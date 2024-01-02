// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./console.sol";
import "./UpgradeableBeacon.sol";
import "./BeaconProxy.sol";

contract AccountFactory {
    address public beacon;

    mapping(uint256 => address) public proxies;

    event ProxyDeployed(address proxyAddress, uint256 id);

    constructor(address implementation_) {
        UpgradeableBeacon _beacon = new UpgradeableBeacon(implementation_);
        _beacon.transferOwnership(msg.sender);
        beacon = address(_beacon);
    }

    function getProxy(uint256 id) external view returns (address) {
        return proxies[id];
    }

    function create(bytes memory data, uint256 id) public returns (address) {
        require(proxies[id] == address(0), "Invalid id");

        BeaconProxy proxy = new BeaconProxy(beacon, data);

        address proxyAddress = address(proxy);
        proxies[id] = proxyAddress;

        emit ProxyDeployed(proxyAddress, id);
        return proxyAddress;
    }

    function createBridgeAccount(address _owner, address _receiver, uint16 _dstChainId, address _dstToken) external returns (address) {
        bytes memory data = abi.encodeWithSignature("initialize(address,address,uint16,address)", _owner, _receiver, _dstChainId, _dstToken);
        console.log(uint256(keccak256(abi.encodePacked(_owner, _receiver, _dstChainId, _dstToken))));
        return create(data, uint256(keccak256(abi.encodePacked(_owner, _receiver, _dstChainId, _dstToken))));
    }

}
