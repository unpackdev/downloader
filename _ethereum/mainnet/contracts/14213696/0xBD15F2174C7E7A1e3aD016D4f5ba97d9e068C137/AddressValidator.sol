// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Validator.sol";

contract AddressValidator is IERC721Validator, Ownable {
    event AddressesSet(address[] addrs, bool set);

    mapping(address => bool) public acceptedAddrs;

    // Used in ValidatorCloneFactory.
    function initialize(address _owner, address[] calldata addrs) external {
        require(owner() == address(0));
        _transferOwnership(_owner);
        _setAddresses(addrs, true);
    }

    function setAddresses(address[] calldata addrs, bool set)
        external
        onlyOwner
    {
        _setAddresses(addrs, set);
    }

    function _setAddresses(address[] calldata addrs, bool set) internal {
        for (uint256 i = 0; i < addrs.length; i++) {
            acceptedAddrs[addrs[i]] = set;
        }
        emit AddressesSet(addrs, set);
    }

    function meetsCriteria(address tokenAddr, uint256)
        external
        view
        override
        returns (bool)
    {
        return acceptedAddrs[tokenAddr];
    }
}
