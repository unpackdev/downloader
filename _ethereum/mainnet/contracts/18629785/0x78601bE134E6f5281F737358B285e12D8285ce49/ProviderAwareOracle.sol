// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPriceOracle.sol";
import "./IPriceProvider.sol";
import "./Ownable.sol";

abstract contract ProviderAwareOracle is IPriceOracle, Ownable {
    uint256 internal constant PRECISION = 1 ether;

    IPriceProvider public provider;

    event ProviderTransfer(address _newProvider, address _oldProvider);

    constructor(address _provider) Ownable(msg.sender) {
        provider = IPriceProvider(_provider);
    }

    function setPriceProvider(address _newProvider) external onlyOwner {
        address oldProvider = address(provider);
        provider = IPriceProvider(_newProvider);
        emit ProviderTransfer(_newProvider, oldProvider);
    }
}
