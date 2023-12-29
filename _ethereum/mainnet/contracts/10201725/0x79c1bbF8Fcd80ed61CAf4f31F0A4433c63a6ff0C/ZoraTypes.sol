pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

library ZoraTypes {

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

}