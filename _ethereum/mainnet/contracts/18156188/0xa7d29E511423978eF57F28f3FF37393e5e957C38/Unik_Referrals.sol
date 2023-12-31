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

// File: contracts/Unik_Referrals.sol


pragma solidity ^0.8.20;


/**
 * @title Unik Referrals Contract
 * @dev This contract manages the referrals for the Unik Watch project. It allows adding and retrieving referrals for influencers and their corresponding percentage shares and discounts.
 */
contract Unik_Referrals is Ownable{
    // ----------------------------------------
    // ############## Management ###########
    // ----------------------------------------

    // Address of the management contract that controls access to this contract
    address public managementContractAddress;
    IManagementContract internal managementContract;

    /**
     * @dev Updates the address of the management contract
     * @param newAddress The new address of the management contract
     */
    function UPDATEManagementContractAddress(address newAddress) public onlyAuthorized {
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

    // Address of the main contract where the NFTs are stored
    address public mainContractAddress;
    IMainContract mainContract = IMainContract(mainContractAddress);

    /**
     * @dev Updates the address of the main contract
     * @param newAddress The new address of the main contract
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
     * @dev Modifier that allows only authorized access
     */
    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == managementContractAddress || managementContract.isAddressWhitelisted(msg.sender), "Unauthorized access");
        _;
    }

    // Define the structure and mapping for referrals
    struct Referral {
        uint256[] referralTokenIds;
        uint16 referralSharePercent;
        uint16 referralDiscountPercent;
    }

    // Mapping: refferals are organised byReferralAddress
    mapping (address => Referral) private referrals;

    /**
     * @dev Adds valid referral addresses with their corresponding percentage shares and discounts
     * @param referralAddresses The array of referral addresses
     * @param sharePercent The array of referral share percentages
     * @param discountPercent The array of referral discount percentages
     */
    function addReferrals(address[] memory referralAddresses, uint16[] memory sharePercent, uint16[] memory discountPercent) public {
        require(msg.sender == owner() || managementContract.isAddressWhitelisted(msg.sender), "Unauthorized access");
        require(referralAddresses.length == sharePercent.length && referralAddresses.length == discountPercent.length, "Arrays length mismatch");
            for (uint16 i = 0; i < referralAddresses.length; i++) {
                address theReferral = referralAddresses[i];
                uint16 theReferralPercent = sharePercent[i];
                uint16 theReferralDiscountPercent = discountPercent[i];

                require(theReferral != address(0), "Invalid referral address");
                require(theReferralPercent > 0 && theReferralPercent <= 2500, "Invalid referral share, should be between 0 & 2500");
                
                Referral storage referral = referrals[theReferral];
                referral.referralSharePercent = theReferralPercent;
                referral.referralDiscountPercent = theReferralDiscountPercent;
            }
    }

    /**
     * @dev Returns the owner of a given token ID
     * @param tokenId The token ID
     * @return The address of the token owner
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return mainContract.ownerOf(tokenId);
    }

    /**
    * @dev Returns the referral information for a given referral address
    * @param referralAddress The referral address
    * @return The referral information
    */
    function getReferral(address referralAddress) public view returns (Referral memory) {
        require(msg.sender == mainContractAddress || msg.sender == referralAddress || msg.sender == owner() || managementContract.isAddressWhitelisted(msg.sender), "Function caller is not allowed");
        return referrals[referralAddress];
    }

    /**
     * @dev Adds a token ID to the referral for a given referral address
     * @param referralAddress The referral address
     * @param tokenId The token ID to be added
     */
    function addTokenIdToReferral(address referralAddress, uint256 tokenId) public {
        require(msg.sender == mainContractAddress || msg.sender == owner() || managementContract.isAddressWhitelisted(msg.sender), "Function caller is not allowed");
        require(referrals[referralAddress].referralSharePercent > 0,"Referral doesn't exist");
        require(ownerOf(tokenId) != address(0),"The token does not exist; you cannot add a non-existent token.");
        referrals[referralAddress].referralTokenIds.push(tokenId);
    }

    /**
     * @dev The referral is able to manage his given discount share for his supplier
     * @param myDiscountPercent The number shoosen by the referral as discount.
        Value like 100 means 100/10000 = 1%
     */
    function setReferralDiscount(uint16 myDiscountPercent) public {
        require(referrals[msg.sender].referralSharePercent != 0, "The caller is not a referral");
        require(myDiscountPercent >= 0 || myDiscountPercent <= 10000, "The value should be between 0 and 10000");
        referrals[msg.sender].referralDiscountPercent = myDiscountPercent;
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

// Set-up interface for the Unik Watch Management Contract
interface IManagementContract {
    function isAddressWhitelisted(address _address) external view returns (bool);
}

// Set-up interface for the Unik Watch Main Contract
interface IMainContract {
    // Interface includes the ownerOf and exists functions from ERC721
    function ownerOf(uint256 tokenId) external view returns (address);
}