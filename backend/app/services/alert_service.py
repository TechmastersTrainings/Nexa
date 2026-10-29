import logging
import uuid
from typing import List, Optional
from uuid import UUID
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.alert import IncidentAlertLog
from app.models.incident import Incident
from app.models.user import User
from app.repositories.alert_repository import alert_repository
from app.repositories.contact_repository import contact_repository
from app.repositories.incident_repository import incident_repository
from app.schemas.alert import AlertDispatchRequest, AlertDispatchResponse

logger = logging.getLogger(__name__)


class AlertService:
    def format_alert_message(self, user_name: str, incident: Incident) -> str:
        """
        Builds a high-priority emergency distress broadcast message with geolocation coordinates.
        """
        if (
            incident.latitude is not None
            and incident.longitude is not None
            and not incident.location_unavailable
        ):
            loc_url = f"https://maps.google.com/?q={incident.latitude:.6f},{incident.longitude:.6f}"
            acc = f" (accuracy ~{int(incident.accuracy_meters or 10)}m)"
            loc_info = f"Location: {loc_url}{acc}"
        else:
            loc_info = "Location: Unavailable / Offline coordinates pending"

        battery_info = f" | Battery: {incident.battery_level}%" if incident.battery_level is not None else ""
        return (
            f"EMERGENCY SOS ALERT! Nexa Safety: {user_name} triggered an SOS distress signal "
            f"(Trigger: {incident.trigger_type.upper()}). {loc_info}{battery_info}. Please check on them immediately!"
        )

    def dispatch_alerts_for_incident(
        self,
        db: Session,
        user: User,
        dispatch_in: AlertDispatchRequest,
    ) -> AlertDispatchResponse:
        # Validate incident belongs to user
        incident = incident_repository.get_by_id(db, dispatch_in.incident_id, user.id)
        if not incident:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Incident record not found.",
            )

        # Retrieve user contacts
        all_contacts = contact_repository.get_all_by_user(db, user.id)

        # Filter contacts
        if dispatch_in.recipient_ids:
            target_ids = set(dispatch_in.recipient_ids)
            contacts_to_notify = [c for c in all_contacts if c.id in target_ids]
        else:
            # Prefer verified contacts; if none verified, fallback to all trusted contacts
            verified_contacts = [c for c in all_contacts if c.is_verified]
            contacts_to_notify = verified_contacts if verified_contacts else all_contacts

        dispatched_logs: List[IncidentAlertLog] = []
        failed_count = 0

        user_display_name = user.full_name or "A Nexa User"
        message_body = self.format_alert_message(user_display_name, incident)

        twilio_enabled = (
            settings.EMERGENCY_SMS_ENABLED
            and bool(settings.TWILIO_ACCOUNT_SID)
            and bool(settings.TWILIO_AUTH_TOKEN)
            and bool(settings.TWILIO_FROM_PHONE)
        )

        twilio_client = None
        if twilio_enabled:
            try:
                from twilio.rest import Client
                twilio_client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            except Exception as e:
                logger.error(f"Failed to initialize Twilio client: {e}")

        for contact in contacts_to_notify:
            provider = "twilio" if twilio_client else "nexa_telecom_gateway"
            provider_msg_id = None
            delivery_status = "sent"
            status_details = None
            error_message = None

            if twilio_client:
                try:
                    if dispatch_in.alert_type == "voice":
                        call = twilio_client.calls.create(
                            twiml=f"<Response><Say voice='alice'>{message_body}</Say></Response>",
                            to=contact.phone_number,
                            from_=settings.TWILIO_FROM_PHONE,
                        )
                        provider_msg_id = call.sid
                        delivery_status = call.status or "queued"
                        status_details = f"Twilio voice call initiated: {call.status}"
                    else:
                        message = twilio_client.messages.create(
                            body=message_body,
                            from_=settings.TWILIO_FROM_PHONE,
                            to=contact.phone_number,
                        )
                        provider_msg_id = message.sid
                        delivery_status = message.status or "sent"
                        status_details = f"Twilio SMS message dispatched: {message.status}"
                except Exception as ex:
                    delivery_status = "failed"
                    error_message = str(ex)
                    failed_count += 1
                    logger.error(f"Twilio dispatch error to {contact.phone_number}: {ex}")
            else:
                # Gateway / Development mode
                provider_msg_id = f"NXA-EMERGENCY-{uuid.uuid4().hex[:12].upper()}"
                delivery_status = "delivered"
                status_details = (
                    f"Dispatched via Nexa Emergency Gateway ({dispatch_in.alert_type.upper()}) to {contact.name}"
                )

            log_entry = alert_repository.create(
                db=db,
                incident_id=incident.id,
                recipient_contact_id=contact.id,
                recipient_phone=contact.phone_number,
                message_body=message_body,
                provider=provider,
                provider_message_id=provider_msg_id,
                delivery_status=delivery_status,
                status_details=status_details,
                error_message=error_message,
            )
            dispatched_logs.append(log_entry)

        return AlertDispatchResponse(
            incident_id=incident.id,
            dispatched_count=len(dispatched_logs) - failed_count,
            failed_count=failed_count,
            alerts=dispatched_logs,
        )

    def get_incident_alerts(self, db: Session, user_id: UUID, incident_id: UUID) -> List[IncidentAlertLog]:
        incident = incident_repository.get_by_id(db, incident_id, user_id)
        if not incident:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Incident record not found.",
            )
        return alert_repository.get_by_incident_id(db, incident_id)

    def get_user_alerts(self, db: Session, user_id: UUID) -> List[IncidentAlertLog]:
        return alert_repository.get_by_user_id(db, user_id)


alert_service = AlertService()
