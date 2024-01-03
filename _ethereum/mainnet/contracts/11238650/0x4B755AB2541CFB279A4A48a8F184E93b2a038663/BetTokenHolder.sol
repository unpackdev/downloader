pragma solidity ^0.6.9;

import "./IERC777.sol";

contract BetTokenHolder {
    IERC777 token;

    constructor (address tokenAddress) public {
        token = IERC777(tokenAddress);
    }

    modifier isRightToken () {
        require(msg.sender == address(token), "Not a valid token");
        _;
    }
}