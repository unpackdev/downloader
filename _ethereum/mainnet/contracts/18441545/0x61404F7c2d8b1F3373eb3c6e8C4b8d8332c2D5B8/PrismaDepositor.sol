// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IStaker.sol";
import "./ITokenMinter.sol";
import "./ITokenLocker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract PrismaDepositor{
    using SafeERC20 for IERC20;

    address public immutable prisma;
    address public immutable escrow;

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

    constructor(address _staker, address _minter, address _prisma, address _veprisma){
        prisma = _prisma;
        escrow = _veprisma;
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

        uint256 tokenBalanceStaker = IERC20(prisma).balanceOf(staker);
        IStaker(staker).lock(tokenBalanceStaker / ITokenLocker(escrow).lockToTokenRatio());
        IStaker(staker).freeze();
    }

    //lock
    function _lock() internal {
        uint256 tokenBalance = IERC20(prisma).balanceOf(address(this));
        if(tokenBalance > 0){
            IERC20(prisma).safeTransfer(staker, tokenBalance);
        }
        
        //increase ammount
        tokenBalance = IERC20(prisma).balanceOf(staker);
        if(tokenBalance == 0){
            return;
        }
        
        //increase amount after dividing by token ratio
        //this will leave some dust but will accumulate for next lock
        IStaker(staker).lock(tokenBalance / ITokenLocker(escrow).lockToTokenRatio());
    }

    function lock() external {
        _lock();
    }

    //deposit prisma for cvxPrisma
    function deposit(uint256 _amount, bool _islock) public {
        require(_amount > 0,"!>0");

        //mint for msg.sender
        ITokenMinter(minter).mint(msg.sender,_amount);

        //check if some should be withheld
        if(platformHolding > 0){
            //can only withhold if there is surplus locked
            (uint256 lockedAmount,) = ITokenLocker(escrow).getAccountBalances(staker);
            lockedAmount *= ITokenLocker(escrow).lockToTokenRatio();
            if(_amount + IERC20(minter).totalSupply() <= lockedAmount ){
                uint256 holdAmt = _amount * platformHolding / DENOMINATOR;
                IERC20(prisma).safeTransferFrom(msg.sender, platformDeposit, holdAmt);
                _amount -= holdAmt;
            }
        }
        
        if(_islock){
            //lock immediately, transfer directly to staker to skip an erc20 transfer
            IERC20(prisma).safeTransferFrom(msg.sender, staker, _amount);
            _lock();
        }else{
            //move tokens here
            IERC20(prisma).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    function depositAll(bool _islock) external{
        uint256 tokenBalance = IERC20(prisma).balanceOf(msg.sender);
        deposit(tokenBalance,_islock);
    }
}