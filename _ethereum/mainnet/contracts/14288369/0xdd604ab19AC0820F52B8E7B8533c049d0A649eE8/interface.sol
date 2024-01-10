pragma solidity ^0.7.0;

import "./interfaces.sol";

struct SwapData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint _sellAmt;
    uint _buyAmt;
    uint unitAmt;
    bytes callData;
}