// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./console.sol";

/**
 * @title Vesting contract using for distributing STRP tokens
 * @dev On ethereum for investors:
 * Grant rewards to Investors is continious.
 * @author Strips Finance
 **/
contract Vesting is 
    Ownable,
    ReentrancyGuard
{    
    // The holder of STRP, it approve Vesting contract to send tokens
    address public strp;

    event VestingClaimed(
        address indexed investor, 
        uint amount
    );

    event VestingGranted(
        address indexed investor, 
        uint vestingPeriod,
        uint unlockPeriod,
        uint strpTotal,
        uint strpInitial
    );

    //Structure that controlls vesting info for investors
    struct VestingData {
        bool isActive;

        uint startTime;
        uint endTime;
        uint periodLength;  // unlock period length calc it upfront for optimization
        uint strpPerPeriod;  // calc it upfront for optimization

        uint strpTotal; // the maximum amount of STRP that investor can claim, includes intitial
        uint strpReleased;  // the STRP amount that investor has released
        uint strpInitial;   //custom initial amount that is available to be claimed immidiately (it's included to strpTotal)

        uint lastClaim;
    }

    //investors
    mapping (address => VestingData) public investors;

    constructor(address _strp) 
    {
        strp = _strp;
    }


    /**
     * @dev Owner(DAO) can add new investor to the list at any time.
     * @param _investor address of investor
     * @param _period the length of vesting period in seconds, started from grant time. (1 year, 3 years, ...)
     * @param _periodLength the length of unlock period.  (1 month, 2 month, ...)
     * @param _strpPerPeriod pre-calc it for optimization. STRP amount distributed per period
     * @param _strpTotal total amount of STRP for this investor
     * @param _strpInitial amount that is immidiate available for claiming
     **/

    function grantVesting(
        address _investor,
        uint _period,
        uint _periodLength,
        uint _strpPerPeriod,
        uint _strpTotal,
        uint _strpInitial
    ) external onlyOwner {
        require (investors[_investor].isActive == false, "ALREADY_GRANTED");
        require (block.timestamp < block.timestamp + _period, "PERIOD_IN_THE_PAST");

        investors[_investor] = VestingData({
            isActive:true,
            startTime:block.timestamp,
            endTime:block.timestamp + _period,

            periodLength: _periodLength,
            strpPerPeriod: _strpPerPeriod,

            strpTotal: _strpTotal,
            strpReleased: 0,
            strpInitial: _strpInitial,

            lastClaim: block.timestamp
        });

        emit VestingGranted(
            _investor, 
            _period,
            _periodLength,
            _strpTotal,
            _strpInitial);
    }

    /**
     * @dev View method for INVESTOR to check available amount of STRP unlocked
     * @return STRP amount available for claiming
     **/

    function checkVestingAvailable() public view returns (uint){
        require (investors[msg.sender].isActive == true, "NOT_VESTED");

        uint periodLength = investors[msg.sender].periodLength;
        uint start = investors[msg.sender].startTime;
        uint end = investors[msg.sender].endTime;

        /* user can withdraw everything if end date passed */
        if (block.timestamp > end){
            return (investors[msg.sender].strpTotal - investors[msg.sender].strpReleased);
        }

        uint unlockedPeriods = (block.timestamp - start) / periodLength - (investors[msg.sender].lastClaim - start) / periodLength;
        uint available = unlockedPeriods * investors[msg.sender].strpPerPeriod;
        
        if (investors[msg.sender].strpReleased == 0){
            return available + investors[msg.sender].strpInitial;
        }

        return available;
    }

    /**
     * @dev INVESTOR must execute this method to release the current total unlocked STRP amount.
     * DAO should approve Vesting for required amount
     **/
    function releaseVesting() external nonReentrant {
        require (investors[msg.sender].isActive == true, "NOT_VESTED");

        uint available = checkVestingAvailable();
        if (available == 0){
            return;
        }

        SafeERC20.safeTransferFrom(IERC20(strp), owner(), msg.sender, available);

        investors[msg.sender].strpReleased += available;
        investors[msg.sender].lastClaim = block.timestamp;


        /*will be reverted on negative - free integrity check */
        uint rest = investors[msg.sender].strpTotal - investors[msg.sender].strpReleased;
        if (rest == 0){
            investors[msg.sender].isActive = false;
        }

        emit VestingClaimed(
            msg.sender,
            available
        );
    }
}
