//The purpose of this harness is to call into OpenSSL's s_client and send a benign heartbeat message.
//The idea is that we can reject a heartbleed message by symbolically attempting (and failing) to verify it
//against the to heartbeat below.

char * ktestModePtr;
char * ktestPathPtr;
char ktestMode[20];
char ktestPath[100];

extern int s_client_main(int argc_val, char ** argv_val);

void begin_target_inner  () {

  //Pass int argc, char **argv
  int argc_val = 6;

  char * arg1 = "-no_special_cmds";
  char * arg2 = "-CAfile";
  char * arg3 = "./TA.crt";
  
  //char * arg4 -- assigned at runtime in TASE, ex "-playback"
  //char * arg5 -- assigned at runtime in TASE, ex "/playpen/humphries/data/mondayTest/monday.ktest"
  char * arg6 = "-heartbeat";
  char * argv_val[6] = {arg1,arg2,arg3,ktestMode,ktestPath,arg6 };
  s_client_main(argc_val,argv_val);

}
