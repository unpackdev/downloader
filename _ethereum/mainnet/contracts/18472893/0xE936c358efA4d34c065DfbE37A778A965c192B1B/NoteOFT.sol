pragma solidity ^0.8.0;

import "./OFTV2.sol";

contract NoteOFT is OFTV2 {
    constructor(address _lzEndpoint) OFTV2("Note OFT", "NOTE-OFT", 6, _lzEndpoint) {}
}
