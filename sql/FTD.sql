select
	t.id,
	t.travel_agency_id,
	t.ticket_num,
	t.issue_date,
	t.refund_limit_date,
	t.pnr,
	t.iata_code,
	t.gds,
	t.source,
	t.status,
	t.fare_calculation,
	case
	    when exists (select 1 from coupon c where c.ticket_id = t.id) then 'FTD OK'
		when t.raw is null then 'ENGINEERING'
		when t.raw ilike '%Wrong length%' then 'ENGINEERING'
		when t.raw ilike '%DateTimeParseException%' then 'ENGINEERING'
		when char_length(coalesce(t.pnr, '')) = 5 then 'ENGINEERING'
		when t.raw ilike '%is distinct from FC dissolved XT total amount%' then 'ENGINEERING'
		when t.raw ilike '%InvalidResourceUsageException%' then 'RETRY'
		when t.raw ilike '%ConnectionFailedException%' then 'RETRY'
		when t.raw ilike '%Unable to open stream%' then 'RETRY'
		when t.raw ilike '%Tried to use NoopGdsOperations%' then 'CONNECTION'
		when t.raw ilike '%com.aleron.client.HostedHooksClientConfig%' then 'CONNECTION'
		when t.raw ilike '%Failed to initialize resource%' then 'CONNECTION'
		when t.raw ilike '%IATA configuration is missing on config file for%' then 'CONNECTION'
		-- Sabre
		when t.raw ilike '%We can only download eTicketCoupon ticket details for%' then 'CONNECTION'
		when t.gds = '_ARC' and t.raw ilike '%Unable to retrieve document info from DMS%' then 'RETRY'
		when t.raw ilike '%Unable to retrieve document info from DMS%' then 'RETRY'
		when t.raw ilike '%Communications Line Unavailable%' then 'RETRY'
		when t.raw ilike '%Unable to create ESSM session from binary security token%' then 'RETRY'
		when t.raw ilike '%Timeout during waiting on%' then 'RETRY'
		when t.raw ilike '%Error occurred during EDIFACT%' then 'RETRY'
		when t.raw ilike '%CARRIER NOT RESPONDING%' then 'RETRY'
		when t.raw ilike '%Error occurred during internal to EDIFACT%' then 'RETRY'
		when t.raw ilike '%Internal TKTHUB WS Connector error%' then 'RETRY'
		when t.raw ilike '%com.aleron.typetags.PNR$.apply%' then 'ENGINEERING'
		when t.raw ilike '%Unable to determine airline for document beginning with%' then 'CONNECTION'
		when t.raw ilike '%Message Function Invalid%' then 'CONNECTION'
		when t.raw ilike '%No agreement between two carriers%' then 'NOT_FOUND'
		when t.raw ilike '%Request security validation failed%' then 'CONNECTION'
		when t.raw ilike '%Not authorized%' then 'CONNECTION'
		when t.raw ilike '%Unable to find the document for the document number in your request%' then 'NOT_FOUND'
		when t.raw ilike '%No PNR Match Found%' then 'CONNECTION'
		when t.raw ilike '%Invalid Requestor Identification%' then 'CONNECTION'
		when t.raw ilike '%fetchPnr not implemented in arc%' then 'ENGINEERING'
		when t.raw ilike '%fetchPnr not implemented in old bsp%' then 'ENGINEERING'
		when t.raw ilike '%Historical status%' and t.raw ilike '%Not found%' then 'ENGINEERING'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.sabre.services.SabreTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'error' is null
			then 'RETRY'
		when true
		  and t.gds not in ('SABRE', 'ABACUS')
		  and t.raw = '{"extractor_class":"com.aleron.gds.sabre.services.SabreTicketInfoExtractor","exception_stacktrace":null,"raw_ticket_info":{"error":"Unexpected subsystem response: T2 HUB Response Validation"}}'
			then 'NOT_FOUND'
		-- Amadeus
		when t.raw ilike '%Error 368%' then 'CONNECTION'
		when t.raw ilike '%Error 401%' then 'NOT_FOUND'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusEDocTicketExtractor'
			and t.raw::json->>'exception_stacktrace' ilike 'java.util.NoSuchElementException%'
			then 'ENGINEERING'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusHostTicketExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_response' ilike 'TKT%'
			and t.raw::json->'raw_ticket_info'->>'taxes_response' ilike 'TOTALTAX%'
			and t.raw::json->'raw_ticket_info'->>'ticket_parse_failure' is not null or t.raw::json->'raw_ticket_info'->>'taxes_parse_failure' is not null
			then 'ENGINEERING'
		-- Galileo
		when t.raw ilike '%Host error during ticket retrieve%' then 'NOT_FOUND'
		when t.raw ilike '%Host Connection Credentials not available%' then 'CONNECTION'
		when t.raw ilike '%No Agreement Exists%' then 'RETRY'
		when t.raw ilike '%Duplicate ticket number found%' then 'ENGINEERING'
		when t.raw ilike '%User account is locked%' then 'CONNECTION'
		when t.raw ilike '%Authentication credentials are invalid%' then 'CONNECTION'
		when t.raw ilike '%A general marshalling exception occurred%' then 'NOT_FOUND'
		when t.raw ilike '%We can only download eTicketCoupon ticket details for%' then 'ENGINEERING'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.travelport.services.TravelportTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike '%air:ETR%'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_parse_failure' is not null
			then 'ENGINEERING'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.travelport.services.TravelportTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike '%air:ETR%'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike '%air:Coupon%'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_parse_failure' is null
			then 'RETRY'
		-- Worldspan
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.travelport.services.TravelportTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike 'TKT%'
			then 'ENGINEERING'
		--- Additional retry conditions
		when t.raw ilike '%Current status: Not found%' then 'RETRY'
		when t.raw ilike '%Error 718%' then 'RETRY'
		when t.raw ilike '%Error 901%' then 'RETRY'
		when t.raw ilike '%Error 118%' then 'RETRY'
		when t.raw ilike '%Error 155%' then 'RETRY'
		when t.raw ilike '%Error 81%' then 'RETRY'
		when t.raw ilike '%11|Session%' then 'CONNECTION'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusEDocTicketExtractor'
			and t.raw::json->'raw_ticket_info'->>'endpoint' = 'EDoc'
			and t.raw::json->'raw_ticket_info'->>'error' is null
		then 'RETRY'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusEDocTicketExtractor'
			and t.raw::json->'raw_ticket_info'->>'endpoint' = 'EDoc'
			and t.raw::json->'raw_ticket_info'->>'error' = 'Empty response'
		then 'RETRY'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusHostTicketExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_response' ilike 'TIMEOUT%'
		then 'RETRY'
		when t.pnr = 'UNKNWN' then 'RETRY'
		when t.raw ilike '%Accessed by another transaction%' and t.raw ilike '%Retry later%' then 'RETRY'
		when t.raw ilike '%Unexpected system error%' then 'RETRY'
		else 'OTHER'
	end category,
	t.raw,
	t.extra_params,
	t.coupon_count
from ticket t
where true
	and t.travel_agency_id = {{travel_agency_id}}
	and t.gds = '{sales_channel}'
	and t.issue_date >= '{from_date}'
	and t.issue_date <= '{to_date}'
	-- Not purged
	and case
	  when t.gds in ('AMADEUS', 'SABRE', 'ABACUS', 'GALILEO', 'WORLDSPAN')
	    then (t.status is null or (t.status not ilike '%V%' and t.status not ilike '%NOT_FOUND%'))
	else true end
	and not t.extra_params @> '{"document_type":"EMD"}'
	and not t.extra_params @> '{"document_type":"EMDA"}'
	and not t.extra_params @> '{"document_type":"EMDS"}'
	{additional_where}