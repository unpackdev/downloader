// SPDX-License-Identifier: Unlicense
// @author devberry.eth

pragma solidity ^0.8.0;

import "./Ownable.sol";

    error CallerIsNotDAO();
    error CallerIsNotPartner();

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) and another account (a DAO) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, `onlyDAO` or `onlyPartner`; which can be applied to your functions to restrict their use to
 * the owner, partners, or DAO.
 */
abstract contract DAOable is Ownable {

    address private _dao = 0x42A21bA79D2fe79BaE4D17A6576A15b79f5d36B0;

    event PartnershipTransferred(address indexed previousDAO, address indexed newDAO);

    constructor() {}

    /**
     * @dev Returns the address of the current dao.
     */
    function dao() public view virtual returns (address) {
        return _dao;
    }

    /**
     * @dev Throws if called by any account other than the DAO.
     */
    modifier onlyDAO() {
        if ( dao() != msg.sender ) revert CallerIsNotDAO();
        _;
    }

    /**
     * @dev Throws if called by any account other than a partner.
     */
    modifier onlyPartner() {
        if ( owner() != msg.sender && dao() != msg.sender ) revert CallerIsNotPartner();
        _;
    }

    /**
     * @dev Leaves the contract without DAO partnership. It will not be possible to call
     * `onlyDAO` functions anymore. Can only be called by the current DAO.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renouncePartnership() public virtual onlyDAO {
        _transferPartnership(address(0));
    }

    /**
     * @dev Transfers DAO partnership of the contract to a new account (`newDAO`).
     * Can only be called by the current DAO.
     */
    function transferPartnership(address newDAO) public virtual onlyDAO {
        require(newDAO != address(0), "DAOable: new DAO is the zero address");
        _transferPartnership(newDAO);
    }

    /**
     * @dev Transfers DAO partnership of the contract to a new account (`newDAO`).
     * Internal function without access restriction.
     */
    function _transferPartnership(address newDAO) internal virtual {
        address oldDAO = _dao;
        _dao = newDAO;
        emit PartnershipTransferred(oldDAO, newDAO);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current partners.
     */
    function transferOwnership(address newOwner) public virtual override onlyPartner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current partners.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyPartner {
        _transferOwnership(address(0));
    }

}
