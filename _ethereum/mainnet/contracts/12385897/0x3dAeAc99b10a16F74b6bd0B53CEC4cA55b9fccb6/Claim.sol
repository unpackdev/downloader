// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Rena.sol";
import "./ILPStaking.sol";
import "./IRebalancer.sol";

//This contract is intended to act as a second layer to the LP Staking contract.
//The Staking contract requires 100% of claim to be added/removed on withdraw and deposits
//of parent token.
//Our modifaction requires payment for claim.
//Claims from the LP Contract are inteded to accumlulate here recored to the address owed to.
//The purchase and rebalancer refill happen here.

contract Claim is Ownable {
    using SafeMath for uint256;

    event Claimed(address indexed, uint256, uint256);
    event lpSacrificed(address indexed, uint256, uint256);

    uint256 public claimDivisor;    

    Rena rena;

    mapping(address => uint256) unclaimed;

    constructor(address rena_) {
        rena = Rena(rena_);
        claimDivisor = 2;
    }

    function maxClaimable(uint256 pid_, address account_) external view returns( uint256 claimable ) {
        address staking = rena.lpStaking();
        uint256 pending_ = ILPStaking(staking).pendingrena(pid_, account_);
        claimable = unclaimed[account_].add(pending_);
    }

    function claim(uint256 requested_, uint256 pid_) external payable {
        address lpStaking = rena.lpStaking();
        if(ILPStaking(lpStaking).pendingrena(pid_, msg.sender) > 0)
            ILPStaking(lpStaking).claim(msg.sender, pid_);

        require(requested_ <= unclaimed[msg.sender], "You don't have that much to claim.");
        unclaimed[msg.sender] = unclaimed[msg.sender].sub(requested_);
        uint256 claimValue = getClaimPrice(requested_);
        require(msg.value >= claimValue, "Insufficient input amount");
        if(claimValue > 0){
            IRebalancer(rena.rebalancer()).refill{value: claimValue}();
        }
        rena.transfer(msg.sender, requested_);
        //send back dust if any
        uint dust = msg.value.sub(claimValue);
        if(dust > 0) {
            msg.sender.transfer(dust);
        }
        emit Claimed(msg.sender, requested_, msg.value);
    }

    //Approval for Claim will be required before calling this.
    function sacrificeLP(uint256 requested_, uint256 pid_) external {
        address lpStaking = rena.lpStaking();

        if(ILPStaking(lpStaking).pendingrena(pid_, msg.sender) > 0)
            ILPStaking(lpStaking).claim(msg.sender, pid_);
        require(requested_ <= unclaimed[msg.sender], "You don't have that much to claim.");
        uint256 requiredLP = getLPPrice(requested_);
        unclaimed[msg.sender] = unclaimed[msg.sender].sub(requested_);
        ILPStaking(lpStaking).withdrawFromTo(msg.sender, 0, requiredLP, rena.rebalancer());
        rena.transfer(msg.sender, requested_);
        emit lpSacrificed(msg.sender, requiredLP, requested_);
    }

    function getClaimPrice(uint256 _amount) public view returns(uint256 claimPrice) {
        if(claimDivisor == 0) return 0;
        address pair = rena.uniPair();
        uint256 ethReserves = IERC20(rena.WETH()).balanceOf(pair);
        uint256 renaReserves = IERC20(address(rena)).balanceOf(pair);
               
        claimPrice = _amount.mul(ethReserves).div(renaReserves); 
        claimPrice = claimPrice.sub(claimPrice.div(claimDivisor));
    }

    function getLPPrice(uint256 _amount) public view returns(uint256 requiredLP) {
        uint256 eBal = IERC20(rena.WETH()).balanceOf(rena.uniPair());
        uint256 lpSupply = IERC20(rena.uniPair()).totalSupply();
        requiredLP = _amount.mul(eBal).div(lpSupply).div(4);
        requiredLP = requiredLP.sub(requiredLP.div(claimDivisor));
    }

    function setClaim(address _from, uint256 _amount) external {
        require(msg.sender ==  rena.lpStaking(), "Only Staking can set claims");
        unclaimed[_from] = unclaimed[_from].add(_amount);
    }

    function setClaimDivisor(
        uint256 _amount 
    ) public onlyOwner {
        require(_amount != 0, 'Cannot set that');
        claimDivisor = _amount;
    }
       
}