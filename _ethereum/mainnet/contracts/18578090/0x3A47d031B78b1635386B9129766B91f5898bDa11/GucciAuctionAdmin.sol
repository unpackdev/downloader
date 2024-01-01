// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract GucciAuctionAdmin is ProxyAdmin {
    TransparentUpgradeableProxy private _proxy;
    address private _baseImplementation;

    constructor(address implementation) ProxyAdmin(_msgSender()) {
        _baseImplementation = implementation;
    }

    function setBaseImplementation(address implementation) external onlyOwner {
        _baseImplementation = implementation;
    }

    function deployAuctionCollection(address royalty, uint96 royaltyFee, string memory name, string memory symbol)
        external
        onlyOwner
    {
        _proxy = new TransparentUpgradeableProxy(
            _baseImplementation,
            address(this),
            abi.encodeWithSignature(
                "initialize(address,address,uint96,string,string)",
                _msgSender(),
                royalty,
                royaltyFee,
                name,
                symbol
            )
        );
    }

    function getProxyAddress() external view returns (address) {
        return address(_proxy);
    }
}
