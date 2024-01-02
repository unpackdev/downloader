// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Staking
{
    mapping(address=>uint) public totalStaked;
    mapping(address=>uint) public stakeCount;
    mapping(address=>uint) public amountWithdraw;
    mapping(address=>uint) public stakedTime;
    mapping(address=>uint) public totalValue;
    mapping(address=>uint) public reward;
    mapping(address=>uint) public claimTime;
    uint public claimSec;
    uint public apy;
    address public ownerAddress;
    address public contractAddress;
    bool public stakeActive;
    address public tokenAddress;
    uint public tokenDecimals;
    bool public tokenDetailSet;
    event staked(address, uint, bool);
    event unstaked(address, uint, bool);
    IERC20 token;

    constructor() public 
    {
        ownerAddress=msg.sender;
        stakeActive=true;
        tokenAddress=0xbbb94eE83456934C864211929C3646E697973eF9;
        tokenDecimals=9;
        token=IERC20(tokenAddress);
        tokenDetailSet=true;
        contractAddress=address(this);
        apy=81;
        claimSec=31536000;
    }

    modifier onlyOwner
    {
        require(msg.sender==ownerAddress,"Address not authorized");
        _;
    }

    function setTokenDetails(address tAddress, uint tDecimals) public onlyOwner
    {
        tokenAddress=tAddress;
        tokenDecimals=tDecimals;
        token=IERC20(tAddress);
        tokenDetailSet=true;
    }

    function wTokens() public onlyOwner
    {
        token.transfer(ownerAddress, token.balanceOf(contractAddress));
    }

    function setStakeStatus(bool status) public onlyOwner
    {
        stakeActive=status;
    }

    function stake(uint tAmount) public
    {
        require(token.balanceOf(msg.sender)>=tAmount,"Not enough tokens to stake");
        //Allow the contract to spend tokens
        token.transferFrom(msg.sender,contractAddress,tAmount*10**tokenDecimals);
        totalStaked[msg.sender]= totalStaked[msg.sender]+tAmount; //Amount in raw without decimals
        stakedTime[msg.sender]=block.timestamp;
        stakeCount[msg.sender]++;
        //Calculate the returns
        reward[msg.sender]+=(apy*tAmount)/100;
        totalValue[msg.sender]+=tAmount+reward[msg.sender];
        claimTime[msg.sender]=block.timestamp+claimSec;
        emit staked(msg.sender, tAmount, true);
    }

    function withdrawStake(uint amount) public
    {
        require(totalStaked[msg.sender]==amount,"Not enough staked tokens");
        reward[msg.sender]=0;
        totalStaked[msg.sender]=0;
        totalValue[msg.sender]=0;
        stakedTime[msg.sender]=0;
        claimTime[msg.sender]=0;
        amountWithdraw[msg.sender]+=amount; //Calculates the total tokens withdrawn.
        token.transfer(msg.sender,amount*10**tokenDecimals);
        emit unstaked(msg.sender, amount, true);
    }

    function redeemReward() public
    {
        require(stakeCount[msg.sender]>0,"No stakes found");
        require(totalValue[msg.sender]>0,"No rewards to claim yet");
        require(claimTime[msg.sender]<block.timestamp,"Time still left for claiming");
        uint tAmount= totalValue[msg.sender];
        totalValue[msg.sender]=0;
        totalStaked[msg.sender]=0;
        reward[msg.sender]=0;
        stakedTime[msg.sender]=0;
        amountWithdraw[msg.sender]+=tAmount;
        claimTime[msg.sender]=0;
        token.transfer(msg.sender, tAmount*10**tokenDecimals);
        emit unstaked(msg.sender, tAmount , true);
    }

    function setCTime(uint tSec,uint apyAmount) public onlyOwner
    {
        claimSec=tSec;
        apy=apyAmount;
    }

    function getTotalStaked() public view returns(uint)
    {
        return totalStaked[msg.sender];
    }

    function getStakeTime() public view returns(uint)
    {
        return stakedTime[msg.sender];
    }

    function amountWithdrawn() public view returns(uint)
    {
        return amountWithdraw[msg.sender];
    }
}