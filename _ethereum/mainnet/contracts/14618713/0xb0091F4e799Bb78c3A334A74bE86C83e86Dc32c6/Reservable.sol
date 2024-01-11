// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev An extension to manage token allowances.
 */
contract Reservable is Ownable {
    uint256 public reserved;

    mapping(address => uint256) public allowances;

    modifier fromAllowance(uint256 count) {
        require(
            count > 0 && count <= allowances[_msgSender()] && count <= reserved,
            "Reservable: reserved tokens mismatch"
        );

        _;

        unchecked {
            allowances[_msgSender()] -= count;
            reserved -= count;
        }
    }

    constructor(uint256 reserved_) {
        reserved = reserved_;
    }

    function reserve(address[] calldata addresses, uint256[] calldata allowance)
        external
        onlyOwner
    {
        uint256 count = addresses.length;

        require(count == allowance.length, "Reservable: data mismatch");

        do {
            count--;
            allowances[addresses[count]] = allowance[count];
        } while (count > 0);
    }
}
