// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Clones.sol";
import "./Ownable.sol";

contract CloneFactory is Ownable {
    address public _implementationAddress;

    event NewClone(address indexed contractAddress);

    using Clones for address;

    constructor(address implementationAddress_) {
        require(implementationAddress_ != address(0), "implementation must be set");
        _implementationAddress = implementationAddress_;
    }

    function getImplementationAddress() external view returns (address) {
        return _implementationAddress;
    }

    function getCloneAddress(bytes32 salt_) external view onlyOwner returns (address) {
        return _implementationAddress.predictDeterministicAddress(salt_);
    }

    function clone(bytes32 salt_) external payable onlyOwner {
        address newCloneContractAddress = _implementationAddress.cloneDeterministic(salt_);
        emit NewClone(newCloneContractAddress);
    }
}
