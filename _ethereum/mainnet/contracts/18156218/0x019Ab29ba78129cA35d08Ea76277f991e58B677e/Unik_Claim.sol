// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: contracts/claim.sol


pragma solidity ^0.8.20;


/**
 * @title Unik Claim System
 * @dev This contract handles the claiming of physical watches associated with NFTs.
 * It allows NFT owners to claim their physical watches by providing their delivery information.
 * The contract also tracks the claim status and delivery date of each watch.
 */

contract Unik_Claim is Ownable {
    // ----------------------------------------
    // ############## Management ###########
    // ----------------------------------------
    address public managementContractAddress;
    IManagementContract internal managementContract = IManagementContract(managementContractAddress);
    
    /**
     * @dev Updates the address of the management contract.
     * @param newAddress The new address of the management contract.
     */
    function UPDATEManagementContractAddress(address newAddress) public  onlyAuthorized {
        uint32 size;
        assembly {
            size := extcodesize(newAddress)
        }
        require(size > 0, "newAddress is not a contract");

        managementContractAddress = newAddress;
        managementContract = IManagementContract(managementContractAddress);
    }

    // ----------------------------------------
    // ############## Main Contract ###########
    // ----------------------------------------
    address public mainContractAddress;// = address (0);
    IMainContract internal mainContract = IMainContract(mainContractAddress);

    /**
     * @dev Updates the address of the main contract.
     * @param newAddress The new address of the main contract.
     */
    function UPDATEMainContractAddress(address newAddress) public onlyAuthorized {
        uint32 size;
        assembly {
            size := extcodesize(newAddress)
        }
        require(size > 0, "newAddress is not a contract");

        mainContractAddress = newAddress;
        mainContract = IMainContract(mainContractAddress);
    }

    // ----------------------------------------
    // ########################################
    // ----------------------------------------

    /**
     * @dev Constructor function
     */
    constructor(address _managementContractAddress) {
        managementContractAddress = _managementContractAddress;
        managementContract = IManagementContract(managementContractAddress);
    }
    
    /**
    * @dev Modifier to allow only authorized addresses to execute certain functions and manage the security.
    * @dev These are, the owner of the contract, the management contract and managers who are in a whitelist inside the Management Contract. 
    */
    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == managementContractAddress || managementContract.isAddressWhitelisted(msg.sender), "Unauthorized access");
        _;
    }

     /**
     * @dev Structure representing the claimant's personal information.
     */
    mapping(uint256 => address) private claimants;

    // Keep the delivery date of the watch to the NFT owner in the mapping. This date reveals the start date of the warranty.
    mapping(uint256 => uint256) public watchDeliveredDate;

    // Keep Watches' claim state
    mapping(uint256 => bool) public claimStatus;

    /**
     * @dev Returns the address of the token owner for a given token ID.
     * @param tokenId The ID of the token.
     * @return The address of the token owner.
     * @notice IERC721 ownerOf Function imported throught the Main Contract where NFTs are inside
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return mainContract.ownerOf(tokenId);
    }
    
    /**
     * @dev Checks if a token with a given ID exists.
     * @param tokenId The ID of the token.
     * @return A boolean indicating whether the token exists or not.
     */
    function exists(uint256 tokenId) internal view virtual returns (bool){
        return ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Sets the claim status for a given token ID.
     * @param tokenId The ID of the token.
     * @param state The claim status to set.
     * @notice If the NFT owner changes his mind regarding claiming his NFT's Watch, he can make changes as long as the watch has not already been sent.
     */
    function setClaimStatus(uint256 tokenId, bool state) public {
        require(exists(tokenId), "TokenId doesn't exist");
        require(ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Caller is not the owner of the token");
        require(claimants[tokenId] != address (0), "The NFT has still not been claimed.");
        require(watchDeliveredDate[tokenId] == 0, "Watch already delivred");
        claimStatus[tokenId] = state;
    }

    /**
     * @dev Returns the claim status of a given token ID.
     * @param tokenId The ID of the token.
     * @return A boolean indicating whether the token has been claimed. "True" means claimed.
     */
    function getClaimStatus(uint256 tokenId) public view returns (bool) {
        require(exists(tokenId), "Token ID does not exist");
        return claimStatus[tokenId];
    }

    /**
     * @dev Allows the NFT owner to claim the physical watch associated with a given token ID.
     * @param tokenId The ID of the token.
     */
    function claimPhysicalWatchNFT(uint256 tokenId) public {
        require(exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");

        // Update the claimant's information.
        claimants[tokenId] = msg.sender;

        // Update the status of the watch claim.
        claimStatus[tokenId] = true;
    }

    /**
     * @dev The buyer confirms the receipt of the watch in person before actually receiving it. 
     *  Only the buyer can call this function. It is considered as a receipt signature.
     *  The date of receipt, therefore, serves as the starting point for the warranty period.
     * @param tokenId The ID of the token.
     */
    function deliverWatchDate(uint256 tokenId) public {
        require(exists(tokenId), "Token ID does not exist");
        require(claimStatus[tokenId], "Token ID is not claimed");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");
        
        // Update delivered date.
        watchDeliveredDate[tokenId] = block.timestamp;
    }


    // ---------------------------------------------
    // ########### Renounce Owner Ship #############
    // ---------------------------------------------

    // Enhance the security of the renounce process by implementing a confirmation system.
    bool renounceOwnerShipState = false;
    /**
    * @dev Set the state of renouncing ownership.
    * @param state The new state of renouncing ownership.
    * @notice Only the owner of the contract can call this function.
    */
    function renounceOwnerShipSet(bool state) public onlyOwner{
        renounceOwnerShipState = state;
    }
    
    /**
    * @dev Override of the renounceOwnership function from Ownable contract to support custom renounce ownership behavior.
    * @notice Only the owner of the contract can call this function.
    */
    function renounceOwnership() public virtual override onlyOwner{
        if (renounceOwnerShipState == true) {
            _transferOwnership(address(0));
        }
    }
}

// Set-up interface from Unik Watch ManagementContract.
interface IManagementContract {
    function isAddressWhitelisted(address _address) external view returns (bool);
}

// Set-up interface from Unik Watch ManagementContract.
interface IMainContract {
    // IERC721 interface which includes the ownerOf and exists functions
    function ownerOf(uint256 tokenId) external view returns (address);
}