// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// This is the NFTMarketplace proxy contract
import "./ERC1967Proxy.sol";

contract MarketplaceProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {
        _changeAdmin(msg.sender);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) external {
        require(msg.sender == _getAdmin(), "Unauthorized call");
        _upgradeToAndCall(newImplementation, data, forceCall);
    }
}