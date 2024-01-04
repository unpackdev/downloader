// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @dev Contract module which provides several vesting algorithms.
 * there is an account (an owner) that is granted exclusive access to
 * send function.
 *
 * There is no hardcoded total supply variable (rely on balanceOf instead).
 * There is no hardcoded destination addresses (rely on addresses provided by send function)
 *
 * This module is used through inheritance.
 */
abstract contract YIELDTokenHolder is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    string public name;
    uint256 public createdAt;//counter start

    //# of releases, months
    uint256 public unlockRate;

    //How many tokens should be unlocked in case non-linear release 
    //example: perMonthCustom = [1024, 0, 2048] means that
    // month #1 - 1024 tokens; month #2 - no tokens at all;   month #3 - 2048 tokens;
    uint256[] public perMonthCustom;

    uint256 public sent;
    address public yieldTokenAddress;

    constructor (address _yieldTokenAddress) {
        yieldTokenAddress = _yieldTokenAddress;
        createdAt = block.timestamp;
    }

    /**
    @notice This function is used to return amout of available tokens
    @return amount of tokens that can be sent instantly by "send" function 
    */
   function getAvailableTokens() public view  returns (uint256) {

        //2592000 = 1 month;
        //months variable starts from 0; 
        uint256 months = block.timestamp.sub(createdAt).div(2592000);

        if(months >= unlockRate){//lock is over, we can unlock everything we have
            return IERC20(yieldTokenAddress).balanceOf(address(this));
        }

        //+1 due to beginning of a month
        uint256 potentialAmount;
        for (uint256 i=0; i<months+1; i++) {
            potentialAmount += perMonthCustom[i];
        }
        return potentialAmount.sub(sent);
    }

    /**
    @notice This function is used to send unlocked tokens
    @param to is a distination address
    @param amount how many tokens to sent
    */
    function send(address to, uint256 amount) onlyOwner nonReentrant external {
        require(getAvailableTokens() >= amount, "available amount is less than requested amount");
        sent = sent.add(amount);
        IERC20(yieldTokenAddress).transfer(to, amount);
    }

}