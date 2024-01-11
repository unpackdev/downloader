// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./ReentrancyGuard.sol";
import "./PermissionManagement.sol";
import "./Payable.sol";
import "./Splits.sol";

/// @title The Splits Factory Contract Instance
/// @author kumareth@monument.app
/// @notice This is the Minimal Splits Proxy Factory Contract
contract SplitsFactory is Payable, ReentrancyGuard {
    address public splitsContractAddress;
    address[] public allProxies;

    event NewProxy (address indexed contractAddress, address indexed createdBy, uint256 timestamp);

    constructor (
        address _splitsContractAddress, 
        address _permissionManagementContractAddress
    ) 
    Payable(_permissionManagementContractAddress) 
    {
        splitsContractAddress = _splitsContractAddress;
    }

    function _clone() internal returns (address result) {
        bytes20 targetBytes = bytes20(splitsContractAddress);

        //-> learn more: https://coinsbench.com/minimal-proxy-contracts-eip-1167-9417abf973e3 & https://medium.com/coinmonks/diving-into-smart-contracts-minimal-proxy-eip-1167-3c4e7f1a41b8
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }

        require(result != address(0), "ERC1167: clone failed");
    }

    function createProxy(
        address[] memory _splitters,
        uint256[] memory _permyriads
    ) external nonReentrant returns (address result) {
        address proxy = _clone();
        allProxies.push(proxy);
        Splits(payable(proxy)).initialize(_splitters, _permyriads);
        emit NewProxy (proxy, msg.sender, block.timestamp);
        return proxy;
    }

    function changeSplitsContractAddress(address _splitsContractAddress) 
        external
        nonReentrant
        returns(address)
    {
        permissionManagement.adminOnlyMethod(msg.sender);
        splitsContractAddress = _splitsContractAddress;
        return _splitsContractAddress;
    }
}