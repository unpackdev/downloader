// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract ACGNLogic is ReentrancyGuard, Pausable, Ownable {

    event ePayment(
        address owner, 
        address token,
        uint256 amount,
        uint256 timestamp,
        uint256 plan
    );

    using SafeERC20 for IERC20;

    address public _VAULT;

    mapping(address => bool) public _paymentTokens;
    
    constructor(address owner, address erc20, address VAULT ) Ownable( owner ) {

        require(owner != address(0), "owner  is zero address!");
        require(erc20 != address(0), "erc20  is zero address!");
        require(VAULT != address(0), "VAULT  is zero address!");
        
        _VAULT = VAULT;
        addPaymentToken(erc20);
    }

    function setVault(address VAULT) public onlyOwner{
        require(VAULT != address(0), "VAULT  is zero address!");
        _VAULT = VAULT;
    }

    function addPaymentToken(address erc20) public onlyOwner {
        require(erc20 != address(0), "VAULT  is zero address!");
        _paymentTokens[erc20] = true;
    }

    function removePaymentToken(address erc20) public onlyOwner {
         _paymentTokens[erc20] = false;
    }

    function urgencyWithdrawErc20(address erc20, address target) public onlyOwner
    {
        IERC20(erc20).safeTransfer(
            target,
            IERC20(erc20).balanceOf(address(this))
        );
    }

    function withdrawETH(address target) public onlyOwner {
        payable(target).transfer(address(this).balance);
    }

    function pause() public onlyOwner{
        if(!paused()){
            _pause();
        }
        else{
            _unpause();
        }
    }

    function pay(address erc20, uint256 plan, uint256 amount) public whenNotPaused nonReentrant {
       
        require(_paymentTokens[erc20], "invalid payment token");

        IERC20(erc20).safeTransferFrom(msg.sender, _VAULT, amount);

        emit ePayment(msg.sender, erc20, amount, block.timestamp, plan);
    }

}