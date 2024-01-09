pragma solidity ^0.7.0;

import "./interfaces.sol";

struct ZeroExData {
    TokenInterface sellToken;
    TokenInterface buyToken;
    uint256 _sellAmt;
    uint256 _buyAmt;
    uint256 unitAmt;
    bytes callData;
}
