pragma solidity >= 0.6.11;

import "./IFxStateSender.sol";

struct Destinations {
    IFxStateSender fxStateSender;
    address destinationOnL2;
}