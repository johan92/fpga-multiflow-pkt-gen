# fpga-multiflow-pkt-gen
Implementation of multiflow packet generator with various rate settings.

It will generate only packet skeleton (in avalon-st interface) without usefull data,
because I'm interested in "perfect" time and rate generation.

I assume it for 10G Ethernet, but it can be parametrized and used for other applications.

My Goal: it should work good on corner cases such as:
  * one flow at 64 bytes packets and 100% rate
  * all flows at 64 bytes packets and each got 100/FLOW\_CNT% rate
  * one flow at 64 bytes packets and 99% rate and FLOW\_CNT - 1 flows at 1/(FLOW\_CNT - 1)% rate
