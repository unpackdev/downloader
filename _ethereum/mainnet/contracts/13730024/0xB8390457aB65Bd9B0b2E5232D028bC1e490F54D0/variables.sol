pragma solidity ^0.8.6;

contract Variables {
    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }
    
    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    // Constant Addresses //

    address public constant nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public wnativeToken;
}