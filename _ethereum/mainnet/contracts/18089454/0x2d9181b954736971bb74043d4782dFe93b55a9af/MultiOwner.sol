// SPDX-License-Identifier: CC0 1.0 Universal

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

/**
 * @dev Contracts to manage multiple owners.
 */
abstract contract MultiOwner {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    mapping(address => bool) private _owners;
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event OwnershipGranted(address indexed operator, address indexed target);
    event OwnershipRemoved(address indexed operator, address indexed target);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidOwner();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[msg.sender] = true;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (!_owners[msg.sender]) revert InvalidOwner();
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns the address of the current owner.
     */
    function ownerCheck(address targetAddress) external view virtual returns (bool) {
        return _owners[targetAddress];
    }

    /**
     * @dev Set the address of the owner.
     */
    function setOwner(address newOwner) external virtual onlyOwner {
        _owners[newOwner] = true;
        emit OwnershipGranted(msg.sender, newOwner);
    }

    /**
     * @dev Remove the address of the owner list.
     */
    function removeOwner(address oldOwner) external virtual onlyOwner {
        _owners[oldOwner] = false;
        emit OwnershipRemoved(msg.sender, oldOwner);
    }
}
