#include "mongoose.h"

static const char *s_http_port = "8000";
static struct mg_serve_http_opts s_http_server_opts;

static const struct mg_str gz_prefix = MG_MK_STR("/gz");

static int has_prefix(const struct mg_str *uri, const struct mg_str *prefix) {
    return uri->len > prefix->len && memcmp(uri->p, prefix->p, prefix->len) == 0;
}


static void ev_handler(struct mg_connection *nc, int ev, void *p) {


    struct http_message *hm = (struct http_message *) p;

    if (ev == MG_EV_HTTP_REQUEST) {

        if (has_prefix(&hm->uri, &gz_prefix)) {

            s_http_server_opts.extra_headers = "Content-Encoding:gzip";

            mg_serve_http(nc, (struct http_message *) p, s_http_server_opts);

        }else{

            s_http_server_opts.extra_headers = NULL;

            if (mg_vcmp(&hm->uri, "/data/curTime") == 0) {
                system("date +\%s > /var/tmp/stats/data/curTime");
            } else if (mg_vcmp(&hm->uri, "/data/stats") == 0){
                system("xdslctl info --stats > /var/tmp/stats/data/stats");
            } else if (mg_vcmp(&hm->uri, "/data/vendor") == 0){
                system("xdslctl info --vendor > /var/tmp/stats/data/vendor");
            } else if (mg_vcmp(&hm->uri, "/data/SNR") == 0){
                system("xdslctl info --SNR > /var/tmp/stats/data/SNR");
            } else if (mg_vcmp(&hm->uri, "/data/Bits") == 0){
                system("xdslctl info --Bits > /var/tmp/stats/data/Bits");
            } else if (mg_vcmp(&hm->uri, "/data/Hlog") == 0){
                system("xdslctl info --Hlog > /var/tmp/stats/data/Hlog");
            } else if (mg_vcmp(&hm->uri, "/data/QLN") == 0){
                system("xdslctl info --QLN > /var/tmp/stats/data/QLN");
            } 

            mg_serve_http(nc, (struct http_message *) p, s_http_server_opts);
        }
    }
}

int main(void) {

	struct mg_mgr mgr;
	struct mg_connection *nc;

	mg_mgr_init(&mgr, NULL);
	printf("Starting web server on port %s\n", s_http_port);
	nc = mg_bind(&mgr, s_http_port, ev_handler);
	if (nc == NULL) {
		printf("Failed to create listener\n");
		return 1;
	}

	s_http_server_opts.custom_mime_types = ".html.gz=text/html,.js.gz=application/javascript,.css.gz=text/css";

	mg_set_protocol_http_websocket(nc);
	s_http_server_opts.document_root = "/var/tmp/stats/";  
	s_http_server_opts.enable_directory_listing = "yes";

	for (;;) {
		mg_mgr_poll(&mgr, 1000);
	}
	mg_mgr_free(&mgr);

	return 0;
}
