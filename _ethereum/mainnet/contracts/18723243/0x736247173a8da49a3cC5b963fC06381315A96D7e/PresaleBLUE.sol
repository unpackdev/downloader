// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

/**
 * @title PresaleBLUE contract
 */
contract PresaleBLUE is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public cashReceiver;
    address public bveBLUE;
    bool public ended;

    mapping(address => uint256) public prices;

    constructor(
        address _bveBLUE, address multisig
    ) {
        prices[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 16e4;
        prices[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 16e4;
        cashReceiver = multisig;
        bveBLUE = _bveBLUE;
    }

    function setEnded(bool _value) external onlyOwner {
        ended = _value;
    }

    function setAllowed(address token, uint256 value) external onlyOwner {
        prices[token] = value;
    }

    function setCashReceiver(address _cashReceiver) external onlyOwner {
        cashReceiver = _cashReceiver;
    }

    function batchMint(address payToken, uint256 _amount, address _to) public {
        require(prices[payToken] > 0, "token is not whitelisted for presale");
        require(!ended, "Sale has ended.");

        uint256 totalPrice = _amount * prices[payToken];

        IERC20(payToken).safeTransferFrom(msg.sender, cashReceiver, totalPrice);

        if(_to != address(0)){

            IERC20(bveBLUE).safeTransfer(_to, _amount);
        
        }else{

            IERC20(bveBLUE).safeTransfer(msg.sender, _amount);
        
        }
    }

    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

}
