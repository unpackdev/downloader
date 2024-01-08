// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";


/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 */
contract BitBaseTimeLock is Ownable {

    /**
     * @dev ERC20 contract being held = BitBase (BTBS)
     */
    IERC20 public BTBS;
    
    /**
     * @dev timestamp when token unlock logic begins = contract deployment timestamp
     */
    uint256 public startDate;

    address[] private addresessArray;
    
    /**
     * @dev Struct that holds the user data: bought and withdrawn tokens
     */
    struct User {
        uint256 bought;
        uint256 withdrawn;
    }
    
    /**
     * @dev mapping of an address to a User struct
     */
    mapping(address => User) public userData;
    
    /**
     * @dev event emitted when a user claims tokens
     */
    event Claimed(address indexed account, uint256 amount);
    
    /**
     * @dev event emitted when the owner updates the address of a user to a new one.
     */
    event AddressUpdated(address indexed accountOld, address indexed accountNew);

    /**
     * @dev event emitted when the owner sets the addresses of the users with the corresponding amount of locked tokens
     */
    event AddressesSet(bool set);

    constructor () {
        BTBS = IERC20(0x32E6C34Cd57087aBBD59B5A4AECC4cB495924356);
        startDate = block.timestamp;
    }


    /**
     * @dev Percentage of unlocked BTBS from total purchased amount 
     * Unlocked:
     * day 90 = 5%
     * day 180 = 10%
     * day 300 = 15%
     * After day 300 = 0.7%/day
     * @return releasePercentage Percentage magnified x100 to decrease precision errors: 500 = 5%
     */
    function unlocked() public view virtual returns (uint256) {

       uint256 startLinearRelease = startDate + 300 days;
       uint256 releasePercentage;
       
       if (block.timestamp <= startDate + 90 days) {
           releasePercentage = 0;
       } else if (block.timestamp < startDate + 180 days) {
           releasePercentage = 500;
       } else if (block.timestamp >= startDate + 180 days && block.timestamp < startLinearRelease) {
           releasePercentage = 1000;
       } else if (block.timestamp >= startLinearRelease) {
           uint256 timeSinceLinearRelease = block.timestamp - startLinearRelease;
           uint256 linearRelease = timeSinceLinearRelease * 1000 / 1234286; //0.7% Daily
           releasePercentage = 1500 + linearRelease;
       }
       
       if (releasePercentage >= 10000) {
           releasePercentage = 10000;
       }
       return releasePercentage;
    }
    
    /**
     * @dev Sends the available amount of tokens to withdraw to the caller
     */
    function _claim(address account) internal virtual {
        uint256 withdrawable = availableToWithdraw(account);
        userData[account].withdrawn += withdrawable;
        BTBS.transfer(account, withdrawable);
        emit Claimed(account, withdrawable);
    }

    /**
     * @dev Sends the available amount of tokens to withdraw to the caller
     */
    function claim() public virtual {
        _claim(msg.sender);
    }
    
    /**
     * @dev Returns the avilable amount of tokens for an address to withdraw = unlockedTotal - claimedAmount
     * @param account The user address
     */
    function availableToWithdraw(address account) public view virtual returns (uint256) {
        return unlockedTotal(account) - claimedAmount(account);
    }
    
    /**
     * @dev Returns the total amount of tokens that has been unlocked for an account
     * @param account The user address
     */
    function unlockedTotal(address account) public view virtual returns (uint256) {
        return userData[account].bought * unlocked() / 10000;
    }
    
    /**
     * @dev Returns the amount of tokens that an address has bought in private sale
     * @param account The user address
     */
    function boughtAmount(address account) public view virtual returns (uint256) {
        return userData[account].bought;
    }
    
    /**
     * @dev Returns de amount of tokens that an address already claimed
     * @param account The user address
     */
    function claimedAmount(address account) public view virtual returns (uint256) {
        return userData[account].withdrawn;
    }
    
    /**
     * @dev Returns the amount of tokens that an address has not yet claim = bought - withdrawn
     * @param account The user address
     */
    function leftToClaim(address account) public view virtual returns (uint256) {
        return userData[account].bought - userData[account].withdrawn;
    }
    
    
    /**
     * @dev This function allows the owner to update a user address in case of lost keys or security breach from the user side.
     * IMPORTANT: Should only be called after proper KYC examination.
     * @param accountOld The old account address
     * @param accountNew The old account address
     */
    function updateAddress(address accountOld, address accountNew) public virtual onlyOwner {
        userData[accountNew].withdrawn = userData[accountOld].withdrawn;
        userData[accountNew].bought = userData[accountOld].bought;
        userData[accountOld].withdrawn = 0;
        userData[accountOld].bought = 0;
        emit AddressUpdated(accountOld, accountNew);
    }
    
    /**
     * @dev Allows owner to recover any ERC20 sent into the contract. Only owner can call this function.
     * @param tokenAddress The token contract address
     * @param amount The amount to be withdrawn. If the amount is set to 0 it will withdraw all the balance of tokenAddress.
     */
    function recoverERC20(address tokenAddress, uint256 amount) public virtual onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        if (amount == 0) {
            uint256 balance = token.balanceOf(address(this));
            token.transfer(owner(), balance);
        } else if (amount != 0) {
            token.transfer(owner(), amount);
        }
    }
    
    /**
     * @dev Allows owner to set an array of addresess who bought and the corresponding amounts. Only owner can call this function.
     * @param accounts Array of user addresess
     * @param amounts Array of user amounts
     */
    function setBoughtAmounts(address[] memory accounts, uint256[] memory amounts) public virtual onlyOwner {
        addresessArray = accounts;
        for (uint256 i = 0; i < accounts.length; i++) {
            userData[accounts[i]].bought = amounts[i];
        }
        emit AddressesSet(true);
    }

    /**
     * @dev Allows owner to send the "availableToWithdraw()" tokens to all the addresess at once.
     * This function has been implemented to help the less tech-savvy users receive their tokens. Only owner can call this function.
     */
    function sendToAll() public virtual onlyOwner {
        for (uint256 i = 0; i < addresessArray.length; i++) {
            _claim(addresessArray[i]);
        }
    }
}