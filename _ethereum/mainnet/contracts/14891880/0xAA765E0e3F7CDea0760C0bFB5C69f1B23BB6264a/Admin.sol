// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./Ownable.sol";

contract Admin is Ownable {
    // admins
    mapping(address => bool) private admins;

    /**
     * @dev change admin state
     */
    function setAdminState(address admin, bool status) public onlyOwner {
        admins[admin] = status;
    }

    /**
     * @dev change multiple admins
     */
    function changeAdminSateMany(
        address[] calldata adminArray,
        bool[] calldata status
    ) public onlyOwner {
        require(
            adminArray.length == status.length,
            "Array hast to be the same length"
        );
        for (uint256 i = 0; i < adminArray.length; i++) {
            setAdminState(adminArray[i], status[i]);
        }
    }

    /**
     * @dev Throws if called by any account other than the owner or an admin.
     */
    modifier onlyAdmins() {
        require(
            owner() == _msgSender() || admins[_msgSender()],
            "Admin: You are not an admin"
        );
        _;
    }
}
