// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IDynamicMetadataCapableElement.sol";

interface IFactory is IDynamicMetadataCapableElement {

    event Deployed(address indexed modelAddress, address indexed deployedAddress, address indexed deployer, bytes deployedLazyInitResponse);

    function modelAddress() external view returns(address);
    function setModelAddress(address newValue) external returns(address oldValue);

    function deployer(address deployedAddress) external view returns(address);

    function deploy(bytes calldata deployData) external payable returns(address deployedAddress, bytes memory deployedLazyInitResponse);
}