select
	t.id as id,
	case
		when exists (select 1 from coupon c where c.ticket_id = t.id) then 'FTD OK'
		when t.raw is null then 'Missing raw log'
		when t.raw ilike '%Wrong length%' then 'Wrong length PNR'
		when t.raw ilike '%DateTimeParseException%' then 'Date-time parser error'
		when char_length(coalesce(t.pnr, '')) = 5 then 'PNR error'
		when t.raw ilike '%is distinct from FC dissolved XT total amount%' then 'Tax error'
		when t.raw ilike '%com.aleron.typetags.PNR$.apply%' then 'PNR error'
		when t.raw ilike '%fetchPnr not implemented in arc%' then 'Fetch not implemented in ARC'
		when t.raw ilike '%fetchPnr not implemented in old bsp%' then 'Fetch PNR not implemented in old bsp'
		when t.raw ilike '%Historical status%' and t.raw ilike '%Not found%' then 'Historial status not found'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusEDocTicketExtractor'
			and t.raw::json->>'exception_stacktrace' ilike 'java.util.NoSuchElementException%'
			then 'Amadeus ticket extractor error'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.amadeus.services.AmadeusHostTicketExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_response' ilike 'TKT%'
			and t.raw::json->'raw_ticket_info'->>'taxes_response' ilike 'TOTALTAX%'
			and t.raw::json->'raw_ticket_info'->>'ticket_parse_failure' is not null or t.raw::json->'raw_ticket_info'->>'taxes_parse_failure' is not null
			then 'Amadeus tax error'
		when t.raw ilike '%Duplicate ticket number found%' then 'Duplicte ticket number found'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.travelport.services.TravelportTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike '%air:ETR%'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_parse_failure' is not null
			then 'Travelport parse error'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.travelport.services.TravelportTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike '%air:ETR%'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike '%air:Coupon%'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_parse_failure' is null
			then 'Travelport parse error'
		when true
			and t.raw::json->>'extractor_class' = 'com.aleron.gds.travelport.services.TravelportTicketInfoExtractor'
			and t.raw::json->'raw_ticket_info'->>'ticket_and_details_response' ilike 'TKT%'
			then 'Travelport parse error'
		else 'OTHER'
	end category
from ticket t
where t.id in (<<id_list>>);