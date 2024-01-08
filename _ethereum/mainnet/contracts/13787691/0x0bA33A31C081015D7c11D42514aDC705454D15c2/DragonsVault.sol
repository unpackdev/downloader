//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessibleCommon.sol";

contract DragonsVault is AccessibleCommon {
    using SafeERC20 for IERC20;

    string public name;

    IERC20 public token;

    bool public diffClaimCheck;
    bool public settingCheck;

    uint256 public firstClaimAmount = 0;
    uint256 public firstClaimTime;         

    uint256 public totalAllocatedAmount;   

    uint256 public startTime;               
    uint256 public claimPeriodTimes;       
    uint256 public totalClaimCounts;      

    uint256 public nowClaimRound = 0;             

    uint256 public totalClaimsAmount;          

    event Claimed(
        address indexed caller,
        uint256 amount,
        uint256 totalClaimedAmount
    );        

    modifier nonZeroAddress(address _addr) {
        require(_addr != address(0), "DragonsVault: zero address");
        _;
    }

    modifier nonZero(uint256 _value) {
        require(_value > 0, "DragonsVault: zero value");
        _;
    }

    ///@dev constructor
    ///@param _name Vault's name
    ///@param _token Allocated token address
    constructor(
        string memory _name,
        address _token
    ) {
        name = _name;
        token = IERC20(_token);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount  
    ///@param _totalClaims total available claim count  
    ///@param _startTime start time             
    ///@param _periodTimesPerClaim period time per claim
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _totalClaims,
        uint256 _startTime,
        uint256 _periodTimesPerClaim
    ) external onlyOwner {
        require(settingCheck == false, "already setting");
        totalAllocatedAmount = _totalAllocatedAmount;
        totalClaimCounts = _totalClaims;
        startTime = _startTime;
        claimPeriodTimes = _periodTimesPerClaim;
    }

    function changeToken(address _token) external onlyOwner {
        require(settingCheck == false, "already setting");
        token = IERC20(_token);
    }

    function settingEnd() external onlyOwner {
        settingCheck = true;
    }

    function firstClaimSetting(uint256 _amount, uint256 _time)
        public
        onlyOwner
        nonZero(_amount)
        nonZero(_time)
    {
        require(settingCheck == false, "already setting");
        diffClaimCheck = true;
        firstClaimAmount = _amount;
        firstClaimTime = _time;
    }

    function currentRound() public view returns (uint256 round) {
        if(diffClaimCheck) {
            if (block.timestamp < firstClaimTime) {
                round = 0;
            } else if(block.timestamp < startTime) {
                round = 1;
            } else {
                round = (block.timestamp - startTime) / claimPeriodTimes;
                round = round + 2;
            }
        } else {
            if (block.timestamp < startTime) {
                round = 0;
            } else {
                round = (block.timestamp - startTime) / claimPeriodTimes;
                round++;
            }
        }
    }

    function calcalClaimAmount(uint256 _round) public view returns (uint256 amount) {
        uint256 remainAmount;
        if(diffClaimCheck && _round == 1) {
            amount = firstClaimAmount;
        } else if(diffClaimCheck){
            remainAmount = totalAllocatedAmount - firstClaimAmount;
            amount = remainAmount/(totalClaimCounts-1);
        } else {
            remainAmount = totalAllocatedAmount;
            amount = remainAmount/totalClaimCounts;
        }
    }
    
    function claim(address _account)
        external
        onlyOwner
    {
        uint256 count = 0;
        uint256 time;

        if(diffClaimCheck){
            time = firstClaimTime;
        } else {
            time = startTime;
        }
        require(block.timestamp > time, "DragonsVault: not started yet");
        require(totalAllocatedAmount > totalClaimsAmount,"DragonsVault: already All get");

        uint256 curRound = currentRound();
        uint256 amount = calcalClaimAmount(curRound);

        require(curRound != nowClaimRound,"DragonsVault: already get this round");

        if(curRound != 1 && diffClaimCheck && totalClaimsAmount < firstClaimAmount) {
            count = curRound - nowClaimRound;
            amount = (amount * (count-1)) + firstClaimAmount;
        } else if (curRound >= totalClaimCounts) {
            amount = totalAllocatedAmount - totalClaimsAmount;
        } else {
            count = curRound - nowClaimRound;
            amount = (amount * count);
        }

        require(token.balanceOf(address(this)) >= amount,"DragonsVault: dont have doc");

        nowClaimRound = curRound;
        totalClaimsAmount = totalClaimsAmount + amount;
        token.safeTransfer(_account, amount);

        emit Claimed(msg.sender, amount, totalClaimsAmount);
    }

    function withdraw(address _account, uint256 _amount)
        external    
        onlyOwner
    {
        require(token.balanceOf(address(this)) >= _amount,"DragonsVault: dont have doc");
        token.safeTransfer(_account, _amount);
    }
}
