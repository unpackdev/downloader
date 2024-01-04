// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract swapContract is Ownable
{
    using SafeMath for uint256;

    IERC20 public tokenAddress;
    address public feeAddress;

    uint128 public numOfTotalBlockchains;
    uint128 public numOfThisBlockchain;
    mapping(uint128 => uint128) public feeAmountOfBlockchain;

    event TransferFromOtherBlockchain(address user, uint256 amount);
    event TransferToOtherBlockchain(uint128 blockchain, address user, uint256 amount, string newAddress);

    constructor(
        IERC20 _tokenAddress,
        address _feeAddress,
        uint128 _numOfTotalBlockchains,
        uint128 _numOfThisBlockchain)
    {
        tokenAddress = _tokenAddress;
        feeAddress = _feeAddress;
        require(
            _numOfTotalBlockchains > 0,
            "WWISH: Wrong numOfTotalBlockchains"
        );
        require(
            _numOfThisBlockchain < _numOfTotalBlockchains,
            "WWISH: Wrong numOfThisBlockchain"
        );
        numOfTotalBlockchains = _numOfTotalBlockchains;
        numOfThisBlockchain = _numOfThisBlockchain;
    }

    function transferToOtherBlockchain(uint128 blockchain, uint256 amount, string memory newAddress) external
    {
        require(
            bytes(newAddress).length > 0,
            "swapContract: No destination address provided"
        );
        require(
            blockchain < numOfTotalBlockchains && blockchain != numOfThisBlockchain,
            "swapContract: Wrong choose of blockchain"
        );
        require(
            amount >= feeAmountOfBlockchain[blockchain],
            "swapContract: Not enough amount of tokens"
        );
        address sender = _msgSender();
        require(
            tokenAddress.balanceOf(sender) >= amount,
            "swapContract: Not enough balance"
        );
        tokenAddress.transferFrom(sender, address(this), amount);
        emit TransferToOtherBlockchain(blockchain, sender, amount, newAddress);
    }

    function transferToUserWithoutFee(address user, uint256 amount) external onlyOwner
    {
        tokenAddress.transfer(user, amount);
        emit TransferFromOtherBlockchain(user, amount);
    }

    /* function transferToUserWithFee(address user, uint256 amountToUser, uint256 feeAmount) external onlyOwner
    {
        tokenAddress.transfer(user, amountToUser);
        tokenAddress.transfer(feeAddress, feeAmount);
        emit TransferFromOtherBlockchain(user, amountToUser);
    } */

    function transferToUserWithFee(address user, uint256 amountToUser) external onlyOwner
    {
        uint256 fee = feeAmountOfBlockchain[numOfThisBlockchain];
        tokenAddress.transfer(user, amountToUser.sub(fee));
        tokenAddress.transfer(feeAddress, fee);
        emit TransferFromOtherBlockchain(user, amountToUser);
    }

    function changeInformationAboutOtherBlockchain(
        uint128 newNumOfThisBlockchain,
        uint128 newNumOfTotalBlockchains
    )
        external
        onlyOwner
    {
        numOfTotalBlockchains = newNumOfTotalBlockchains;
        numOfThisBlockchain = newNumOfThisBlockchain;
    }

    function changeFeeAddress(address newFeeAddress) external onlyOwner
    {
        feeAddress = newFeeAddress;
    }

    function setFeeAmountOfBlockchain(uint128 blockchainNum, uint128 feeAmount) external onlyOwner
    {
        feeAmountOfBlockchain[blockchainNum] = feeAmount;
    }
}