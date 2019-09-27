public without sharing class lpes_ExceptionMessageWrapper 
{
    @testvisible public static final string JSON_PARSE_ERROR_MESSAGE {get; private set;}
    @testvisible public static final string INVALID_EVENT_FIELD_MESSAGE {get; private set;}
    @testvisible public static final string DISABLED_PAYLOAD_LOG_MESSSAGE {get; private set;}
    @testvisible public static final string INVALID_PARAMETERS_MESSAGE {get; private set;}

    static 
    {
        INVALID_PARAMETERS_MESSAGE = 'INVALID_METHOD_PARAMETERS: Parameters cannot be null';
        JSON_PARSE_ERROR_MESSAGE = 'JSON_PARSE_ERROR: '+Label.lpes_json_parse_error_message;
        INVALID_EVENT_FIELD_MESSAGE = 'INVALID_EVENT_FIELD: '+Label.lpes_invalid_event_field_message;
        DISABLED_PAYLOAD_LOG_MESSSAGE = 'DISABLED_PAYLOAD_LOG: '+Label.lpes_disabled_payload_log_message;
    }

}