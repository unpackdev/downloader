// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract SupportedTokenList is Ownable {
    event AddToken(address token, string symbol);

    mapping(address => string) public tokenList;

    function add(address _token, string memory _symbol) public onlyOwner {
        tokenList[_token] = _symbol;
    }

    function get(address _token) public view returns (string memory) {
        string memory symbol = tokenList[_token];
        if (bytes(symbol).length == 0) {
            return "Unknown";
        }
        return symbol;
    }
}
