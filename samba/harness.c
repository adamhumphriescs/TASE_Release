
int target_main(int argc, char *argv[]);

int begin_target_inner(int argc, char** argv){
  return target_main(argc, argv);
}
