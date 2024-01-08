pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";


/**
 * @dev Modified Ownable. Introduces `auditor` address that has the exclusive
 * right to transfer ownership of the contract.
 *
 * This module makes available the modifiers: `onlyAuditor`, `onlyOwnerAndAuditor`.
 * `onlyOwner` replaced with `onlyOwnerAndAuditor` in function `transferOwnership`.
 */
abstract contract Auditable is Context {
    address private _owner;
    address private _auditor;

    event AuditingTransferred(address indexed previousAuditor, address indexed newAuditor);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _auditor = msgSender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current auditor.
     */
    function auditor() public view returns (address) {
        return _auditor;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAuditor() {
        require(_auditor == _msgSender(), "Auditable: caller is not the auditor");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Throws if called by any account other than the owner or auditor.
     */
    modifier onlyOwnerOrAuditor() {
        require(_owner == _msgSender() || _auditor == _msgSender(), "Auditable: caller is not the owner or auditor");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferAuditing(address newAuditor) public virtual onlyAuditor {
        require(newAuditor != address(0), "Auditable: new auditor is the zero address");
        emit AuditingTransferred(_auditor, newAuditor);
        _auditor = newAuditor;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwnerOrAuditor {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
