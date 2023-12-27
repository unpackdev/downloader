// SPDX-License-Identifier: MIT

/**
 *
 *  @title: Prospectree Certificate Contract
 *  @date: 25-August-2023 
 *  @version: 1.0
 *  @author: Prospectree Dev Team
 */

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.19;

contract prospecTreeCertificate is Ownable {

    // Declare Variables

    uint256 public certificateIdCounter;

    // Declare Struct

    struct certificate {
        uint256 certificateId;
        bytes32 certificateHash;
        address certificateOwner;
        uint256 noOfTrees;
        bool certificateStatus;
    }

    // Declare mappings

    mapping (address => uint256[]) public certificatesBy;
    mapping (address => bool) public adminPermissions;
    mapping (uint256 => certificate) public certificateRecords;

    // Add modifier

    modifier AdminRequired {
      require((adminPermissions[msg.sender] == true) || (_msgSender()== owner()), "Not allowed");
      _;
   }

    // Constructor

    constructor() public {
        certificateIdCounter=10000000;
    }

    // SETTER FUNCTIONS

    // Register a certificate

    function registerCertificate(bytes32 certificateHash, address certificateOwner, uint256 _noOfTrees) public AdminRequired {
        certificate memory newCertificate = certificate(certificateIdCounter, certificateHash, certificateOwner, _noOfTrees, true);
        certificateRecords[certificateIdCounter] = (newCertificate);
	    certificatesBy[certificateOwner].push(certificateIdCounter);
        certificateIdCounter = certificateIdCounter + 1;
    }

    // Revoke a certificate

    function revokeCertificate(uint256 _certificateID) public AdminRequired{
        certificateRecords[_certificateID].certificateStatus = false;
    }

    // Add Admins

    function addAdmins(address _admin, bool _status) public {
        require (_msgSender()== owner(), "Only Owner");
        adminPermissions[_admin] = _status;

    }

    // RETRIEVE FUNCTIONS

    // Retrieve certificate

    function retrieveCertificate(uint256 _certificateID) public view returns (uint256, bytes32, address, uint256, bool) {
        return (certificateRecords[_certificateID].certificateId, certificateRecords[_certificateID].certificateHash, certificateRecords[_certificateID].certificateOwner, certificateRecords[_certificateID].noOfTrees, certificateRecords[_certificateID].certificateStatus);
    }

    // Retrieve certificate owned by an address

    function retrieveCertificatesOwnedBy(address _certificateOwner) public view returns (uint256[] memory) {
        return (certificatesBy[_certificateOwner]);
    }

    // Retrieve Certificate Status

    function retrieveCertificateStatus(uint256 _certificateID) public view returns (bool) {
        return (certificateRecords[_certificateID].certificateStatus);
    }

    // Retrieve Certificate Owner

    function retrieveCertificateOwner(uint256 _certificateID) public view returns (address) {
        return (certificateRecords[_certificateID].certificateOwner);
    }

    // Retrieve Certificate NoofTrees

    function retrieveCertificateNoTrees(uint256 _certificateID) public view returns (uint256) {
        return (certificateRecords[_certificateID].noOfTrees);
    }

}