#include <clients/nrt/FluidNRTClientWrapper.hpp>
#include <clients/nrt/FluidThreadTest.hpp>
#include <FluidParameterDump.hpp>
int main(int argc, char *argv[]) {
  using namespace fluid::client;
  if (!argc) std::cerr << "Please pass a folder to write to";
  std::cout << "Write JSON to " << argv[1];
  ParameterDump<NRTThreadedThreadTest>::dump("BufThreadDemo", argv[1]);
  return 0;
}
