// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IStaker.sol";
import "./ITokenMinter.sol";
import "./IVoteEscrow.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract FxnDepositor{
    using SafeERC20 for IERC20;

    address public constant fxn = address(0x365AccFCa291e7D3914637ABf1F7635dB165Bb09);
    address public constant escrow = address(0xEC6B8A3F3605B083F7044C0F31f2cac0caf1d469);
    uint256 private constant MAXTIME = 4 * 365 * 86400;
    uint256 private constant WEEK = 7 * 86400;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public platformHolding = 0;
    address public platformDeposit;

    address public owner;
    address public pendingOwner;
    address public immutable staker;
    address public immutable minter;
    uint256 public unlockTime;

    event SetPendingOwner(address indexed _address);
    event OwnerChanged(address indexed _address);
    event ChangeHoldingRate(uint256 _rate, address _forward);

    constructor(address _staker, address _minter){
        staker = _staker;
        minter = _minter;
        owner = msg.sender;
    }

    //set next owner
    function setPendingOwner(address _po) external {
        require(msg.sender == owner, "!auth");
        pendingOwner = _po;
        emit SetPendingOwner(_po);
    }

    //claim ownership
    function acceptPendingOwner() external {
        require(msg.sender == pendingOwner, "!p_owner");

        owner = pendingOwner;
        pendingOwner = address(0);
        emit OwnerChanged(owner);
    }

    function setPlatformHoldings(uint256 _holdings, address _deposit) external{
        require(msg.sender==owner, "!auth");

        require(_holdings <= 2000, "too high");
        if(_holdings > 0){
            require(_deposit != address(0),"need address");
        }
        platformHolding = _holdings;
        platformDeposit = _deposit;
        emit ChangeHoldingRate(_holdings, _deposit);
    }

    function initialLock() external{
        require(msg.sender==owner, "!auth");

        uint256 vefxn = IERC20(escrow).balanceOf(staker);
        uint256 locked = IVoteEscrow(escrow).locked(staker);
        if(vefxn == 0 || vefxn == locked){
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = (unlockAt/WEEK)*WEEK;

            //release old lock if exists
            IStaker(staker).release();
            //create new lock
            uint256 fxnBalanceStaker = IERC20(fxn).balanceOf(staker);
            IStaker(staker).createLock(fxnBalanceStaker, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    //lock fxn
    function _lockFxn() internal {
        uint256 fxnBalance = IERC20(fxn).balanceOf(address(this));
        if(fxnBalance > 0){
            IERC20(fxn).safeTransfer(staker, fxnBalance);
        }
        
        //increase ammount
        uint256 fxnBalanceStaker = IERC20(fxn).balanceOf(staker);
        if(fxnBalanceStaker == 0){
            return;
        }
        
        //increase amount
        IStaker(staker).increaseAmount(fxnBalanceStaker);
        

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt/WEEK)*WEEK;

        //increase time too if over 1 week buffer
        if( unlockInWeeks - unlockTime >= 1){
            IStaker(staker).increaseTime(unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    function lockFxn() external {
        _lockFxn();
    }

    //deposit fxn for cvxfxn
    function deposit(uint256 _amount, bool _lock) public {
        require(_amount > 0,"!>0");

        //mint for msg.sender
        ITokenMinter(minter).mint(msg.sender,_amount);

        //check if some should be withheld
        if(platformHolding > 0){
            //can only withhold if there is surplus locked
            if(_amount + IERC20(minter).totalSupply() <= IVoteEscrow(escrow).locked(staker) ){
                uint256 holdAmt = _amount * platformHolding / DENOMINATOR;
                IERC20(fxn).safeTransferFrom(msg.sender, platformDeposit, holdAmt);
                _amount -= holdAmt;
            }
        }
        
        if(_lock){
            //lock immediately, transfer directly to staker to skip an erc20 transfer
            IERC20(fxn).safeTransferFrom(msg.sender, staker, _amount);
            _lockFxn();
        }else{
            //move tokens here
            IERC20(fxn).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    function depositAll(bool _lock) external{
        uint256 fxnBal = IERC20(fxn).balanceOf(msg.sender);
        deposit(fxnBal,_lock);
    }
}