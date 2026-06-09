select
	t.id as id,
	t.travel_agency_id,
	case
		when t.raw ilike '%Tried to use NoopGdsOperations%' then 'GDS-IATA match missing on configurations'
		when t.raw ilike '%com.aleron.client.HostedHooksClientConfig%' then 'Client config'
		when t.raw ilike '%Failed to initialize resource%' then 'Failed to initialize resource'
		when t.raw ilike '%IATA configuration is missing on config file for%' then 'IATA configuration is missing'
		-- Sabre
		when t.raw ilike '%We can only download eTicketCoupon ticket details for%' then 'Error dowloading eTicketCoupon from GDS'
		when t.gds = '_ARC' and t.raw ilike '%Unable to retrieve document info from DMS%' then 'Unable to retrieve document info from DMS'
		when t.raw ilike '%Unable to determine airline for document beginning with%' then 'Unable to determine airline for document beginning'
		when t.raw ilike '%Message Function Invalid%' and t.gds in ('FLGX', 'WEBL','EDIS') then 'Missing direct channel credentials'
		when t.raw ilike '%Message Function Invalid%' and t.gds in ('_ARC', 'AMADEUS', 'GALILEO', 'SABRE') then 'Message Function Invalid'
		when t.raw ilike '%Request security validation failed%' then 'Request security validation failed'
		when t.raw ilike '%Not authorized%' then 'Not authorized'
		when t.raw ilike '%No PNR Match Found%' then 'No PNR Match Found'
		when t.raw ilike '%Invalid Requestor Identification%' then 'Invalid Requestor Identification'
		when t.raw ilike '%NDC ISSUED DOCUMENT%' then 'NDC ISSUED DOCUMENT'
		when t.raw ilike '%No agreement on destination%' then 'No agreement on destination'
		-- Amadeus
		when t.raw ilike '%Error 368%' then 'Error 368'
		-- Galileo
		when t.raw ilike '%Host Connection Credentials not available%' then 'Host Connection Credentials not available'
		when t.raw ilike '%User account is locked%' then 'User account is locked'
		when t.raw ilike '%Authentication credentials are invalid%' then 'Authentication credentials are invalid'
		when t.raw ilike '%11|Session%' then '11 | Session '
		else 'OTHER'
	end category
from ticket t
where t.id in (<<id_list>>);