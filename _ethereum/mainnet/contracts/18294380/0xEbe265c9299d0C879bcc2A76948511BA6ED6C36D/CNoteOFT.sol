pragma solidity ^0.8.0;

import "./OFTV2.sol";

contract CNoteOFT is OFTV2 {
    constructor(address _lzEndpoint) OFTV2("cNote OFT", "CNOTE-OFT", 6, _lzEndpoint) {}
}
