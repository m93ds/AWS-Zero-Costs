import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Procesa las notificaciones de SNS enviadas por AWS Budgets."""
    
    # Loguea toda la estructura del evento recibido para depuración
    logger.info("## RAW EVENT RECEIVED:")
    logger.info(json.dumps(event, indent=2))
    
    try:
        if 'Records' in event:
            sns_record = event['Records'][0]['Sns']
            message_id = sns_record.get('MessageId', 'N/A')
            message_content = sns_record.get('Message', '{}')  # Obtiene mensaje como cadena
            
            logger.info(f"## PROCESSING SNS MESSAGE ID: {message_id}")
            logger.info("## MESSAGE CONTENT(String):")
            logger.info(message_content)
            
            # Intenta analizar el mensaje content como JSON (común para alertas de presupuesto)
            try:
                message_data = json.loads(message_content)
                logger.info("## MESSAGE CONTENT(Parsed JSON):")
                logger.info(json.dumps(message_data, indent=2))
            except json.JSONDecodeError:
                logger.warning("Could not parse message content as JSON.")
        else:
            logger.warning("Event received does not appear to be from SNS.")
    except Exception as e:
        logger.error(f"Error processing event record:{str(e)}")
    
    # Devuelve una respuesta exitosa para evitar reintentos
    return {
        'statusCode': 200,
        'body': json.dumps('Evento procesado correctamente por Lambda!')
    }
