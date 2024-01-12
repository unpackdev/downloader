//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./AccessControl.sol";

contract ConfigurableOracleMock is AccessControl {
    string public tokenSymbol;
    uint256 public tokenPrice;
    uint256 public tokenDecimals;

    constructor(string memory tokenSymbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        tokenSymbol = tokenSymbol_;
    }

    function latestAnswer() external view returns (uint256) {
        return tokenPrice;
    }

    function decimals() external view returns (uint256) {
        return tokenDecimals;
    }

    function setPriceAndDecimals(
        string calldata tokenSymbol_,
        uint256 price_,
        uint256 decimals_
    ) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Err not admin");
        require(keccak256(bytes(tokenSymbol_)) == keccak256(bytes(tokenSymbol)), "Err wrong token");
        require(decimals_ > 0, "Err decimals_");

        tokenPrice = price_;
        tokenDecimals = decimals_;
    }
}
