// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./SafeMath.sol";

/**
@title Membership
@dev A contract for transferring ERC20 tokens.
*/

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Membership is Ownable {
    using SafeMath for uint256;

    address public tokenAddress;
    uint256 public contractBalance;
    uint256 public deductedFee;
    address public destinationAddress;

    /**
     * @dev Initializes the contract with the specified token address and transfer amount.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _deductedFee The fee percentage deducted from token transfers.
     */
    constructor(address _tokenAddress, uint256 _deductedFee) {
        tokenAddress = _tokenAddress;
        deductedFee = _deductedFee;  

    }

    /**
     * @dev Withdraws the tokens from the contract to the owner. Only the owner can access this function.
     */
    function withdrawTokens(address _to, uint256 _amount) external onlyOwner {
        require(_amount <= contractBalance, "Contract balance is zero");
        contractBalance -= _amount;
        require(
            IERC20(tokenAddress).transfer(_to, _amount),
            "Token transfer failed"
        );
    }

    /**
     * @dev Transfers a specified amount of tokens to the contract and a specified amount to the buyer, while deducting a fee.
     * @param buyer The address of the buyer that sends the tokens.
     * @param seller The address of the seller receiving the majority of the tokens.
     * @param tokenAmount The total amount of tokens being transferred.
     */
    function transferTokensWithFee(
        address buyer,
        address seller,
        uint256 tokenAmount
    ) external {
        require(msg.sender == buyer || msg.sender == destinationAddress , "Not Allowed");
        IERC20 token = IERC20(tokenAddress);
        uint256 fee = tokenAmount*(deductedFee)/(100); // Calculate 10% fee
        uint256 amountToTransfer = tokenAmount-fee;    

        // Transfer 10% of tokens to contract
        require(
            token.transferFrom(buyer, address(this), fee),
            "Token transfer failed"
        );
        
        require(
            token.transferFrom(buyer, seller, amountToTransfer),
            "Token transfer failed"
        );

        contractBalance = contractBalance+fee;
    }

    /**
     * @dev Sets the fee percentage deducted from token transfers.
     * @param _newFeePercentage The new fee percentage to be set.
     */
    function setFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(
            _newFeePercentage <= 100,
            "Fee percentage must be less than or equal to 100"
        );
        deductedFee = _newFeePercentage;
    }

    /**
     * @dev Sets the destination address for routing.
     * This function can only be called by the owner of the contract.
     * @param _destinationAddress The address to set as the destination.
     */
    function setRouter(address _destinationAddress) external onlyOwner {
        destinationAddress = _destinationAddress;
    }

}