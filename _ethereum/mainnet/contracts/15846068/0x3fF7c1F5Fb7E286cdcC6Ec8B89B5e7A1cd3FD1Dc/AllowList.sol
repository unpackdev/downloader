// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "./Ownable.sol";

abstract contract AllowList is Ownable {
    mapping(address => bool) private allowList;

    modifier onlyAllowList() {
        require(isAllowList(msg.sender), "Address is not within allowList");
        _;
    }

    /**
     * @notice Adds an address to the allowList
     */
    function allowAddress(address _address) public onlyOwner {
        allowList[_address] = true;
    }

    /**
     * @notice Adds an array of addresses to the allowList
     */
    function allowAddresses(address[] calldata _addresses) external onlyOwner {
        uint length = _addresses.length;
        for (uint i; i < length; ) {
            allowAddress(_addresses[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Removes an address off the allowList
     */
    function disallowAddress(address _address) public onlyOwner {
        allowList[_address] = false;
    }

    /**
     * @notice Returns `true` if `_address` is in and `true` in the allowList
     */
    function isAllowList(address _address) public view returns (bool) {
        return allowList[_address];
    }
}
