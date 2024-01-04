// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract GraphLinqDepositor {
    using SafeMath for uint256;

    address private _graphLinkContract;
    mapping (address => uint256) _balances;
    address private _engineManager;

    constructor(address engineManager, address graphLinqContract) {
        _engineManager = engineManager;
        _graphLinkContract = graphLinqContract;
    }

    /* Parameters: Amount of GLQ Token to burn
    ** Desc: Burn a specific amount of token by calling the GLQ Token Contract for All Wallets
    ** Return: void
    */
    function burnAmount(uint256 amount) public {
        IERC20 graphLinqToken = IERC20(address(_graphLinkContract));
         require (
            msg.sender == _engineManager,
            "Only the GraphLinq engine manager can decide which funds should be burned for graph costs."
        );
        require(
            graphLinqToken.balanceOf(address(this)) >= amount, 
            "Invalid fund in the depositor contract, cant reach the contract balance amount."
        );
        graphLinqToken.burnFuel(amount);
    }

    /* Parameters: Amount of GLQ Token to burn
    ** Desc: Burn a specific amount of token by calling the GLQ Token Contract for a specific wallet
    */
    function burnBalance(address fromWallet, uint256 amount) public {
        IERC20 graphLinqToken = IERC20(address(_graphLinkContract));
        require (
            msg.sender == _engineManager,
            "Only the GraphLinq engine manager can decide which funds should be burned for graph costs."
        );

        require (_balances[fromWallet] >= amount,
            "Invalid amount to withdraw, amount is higher then current wallet balance."
        );

        require(
            graphLinqToken.balanceOf(address(this)) >= amount, 
            "Invalid fund in the depositor contract, cant reach the contract balance amount."
        );

        graphLinqToken.burnFuel(amount);
        _balances[fromWallet] -= amount;
    }

    /* Parameters: wallet owner address, amount asked to withdraw, fees to pay for graphs execs
    ** Desc: Withdraw funds from this contract to the base wallet depositor, applying fees if necessary
    */
    function withdrawWalletBalance(address walletOwner, uint256 amount,
     uint256 removeFees) public {
        IERC20 graphLinqToken = IERC20(address(_graphLinkContract));

        require (
            msg.sender == _engineManager,
            "Only the GraphLinq engine manager can decide which funds are withdrawable or not."
        );

        uint256 summedAmount = amount.add(removeFees);
        require (_balances[walletOwner] >= summedAmount,
            "Invalid amount to withdraw, amount is higher then current wallet balance."
        );

        require(
            graphLinqToken.balanceOf(address(this)) >= summedAmount, 
            "Invalid fund in the depositor contract, cant reach the wallet balance amount."
        );

        _balances[walletOwner] -= amount;
        require(
            graphLinqToken.transfer(walletOwner, amount),
            "Error transfering balance back to his owner from the depositor contract."
        );
        
        // in case the wallet runned some graph on the engine and have fees to pay
        if (removeFees > 0) {
            graphLinqToken.burnFuel(removeFees);
            _balances[walletOwner] -= removeFees;
        }
    }

    /* Parameters: Amount to add into the contract
    ** Desc: Deposit GLQ token in the contract to pay for graphs fees executions
    */
    function addBalance(uint256 amount) public {
         IERC20 graphLinqToken = IERC20(address(_graphLinkContract));

         require(
             graphLinqToken.balanceOf(msg.sender) >= amount,
             "Invalid balance to add in your credits"
         );

         require(
             graphLinqToken.transferFrom(msg.sender, address(this), amount) == true,
             "Error while trying to add credit to your balance, please check allowance."
         );

         _balances[msg.sender] += amount;
    }

    function getBalance(address from) public view returns(uint256) {
        return _balances[from];
    }
}