// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Address.sol";

import "./console.sol";

contract RoyaltyReceiverMP is Ownable {

    using SafeERC20 for IERC20;
   
    address public nifty;
    address public smartTokensLabs;
    
    event RoyaltyPaid(address receiver, uint256 sum);
    event RoyaltyPaidERC20(address indexed erc20, address receiver, uint256 sum);

    constructor(address _nt, address _stl) {
        nifty = _nt;
        smartTokensLabs = _stl;
    }

    function updateRecievers(address _nt, address _stl) external onlyOwner {
        nifty = _nt;
        smartTokensLabs = _stl;
    }

    function withdrawETH() external {
        uint balance = address(this).balance;
        require(balance > 0, "Empty balance");
        unchecked {
            uint half = balance/2;
            emit RoyaltyPaid(nifty, half);
            _pay(half, nifty);

            half = balance - half;
            emit RoyaltyPaid(smartTokensLabs, half);
            _pay(half, smartTokensLabs);
        }
    }

    function _pay(uint256 amount, address receiver) internal {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function withdraw(address[] calldata contracts) external {
        for (uint i = 0; i < contracts.length; i++ ){
            payERC20(contracts[i]);
        }
    }

    function payERC20(address erc20) internal {
        
        IERC20 erc20c = IERC20(erc20);

        // get this contract balance to withdraw
        uint balance = erc20c.balanceOf(address(this));
        // throw error if it requests more that in the contract balance
        require(balance > 0, "Balance is Empty");

        uint half = balance / 2;

        emit RoyaltyPaidERC20( erc20, nifty, half);
        erc20c.safeTransfer(nifty, half);

        half = balance - half;
        emit RoyaltyPaidERC20( erc20, smartTokensLabs, half);
        erc20c.safeTransfer(smartTokensLabs, half);

    }

    receive() external payable {}
}