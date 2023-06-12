/// API base endpoint.
const String api_link = 'https://193.136.175.76/mobile';

/// API endpoint to create a site or list all sites.
const String sites_link = '$api_link/sites';

/// API endpoint to retrieve, update or delete a site given its id.
/// Interpolate the desired id with a '/' after this link:
/// '$site_link/$id'
const String site_link = '$api_link/site';

/// API endpoint to create an occurrence or list all occurrences.
const String occurrences_link = '$api_link/occurrences';

/// API endpoint to retrieve, update or delete an occurrence given its id.
/// Interpolate the desired id with a '/' after this link:
/// '$occurrence_link/$id'
const String occurrence_link = '$api_link/occurrence';

/// API endpoint to list all attribute choices.
const String attributes_link = '$api_link/attributechoices';

/// API endpoint to list all metric types.
const String metrics_link = '$api_link/metrictypes';
