// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeERC20.sol";

struct Tokens {
    uint256 coinType;
    IERC20 tokenAddress;
    string tokenName;
    uint256 minAmount;
}

contract SubGameSwap is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ReceiveSwap(address from, uint256 fromCoinType, string to, uint256 amount);
    event Send(address to, uint256 toCoinType, uint256 amount, string swapHash);

    mapping(uint256 => Tokens) tokens;

    constructor(IERC20 addr, uint256 coinType, string memory tokenName) {
        tokens[coinType].coinType = coinType;
        tokens[coinType].tokenAddress = addr;
        tokens[coinType].tokenName = tokenName;
        tokens[coinType].minAmount = 10;
    }

    function receiveSwap(string calldata to, uint256 fromCoinType, uint256 amount) external {
        require(amount >= tokens[fromCoinType].minAmount, "amount must greater or equal to min");
        require(tokens[fromCoinType].coinType == fromCoinType, "token not allowed");
        require(fromCoinType > 0, "token not allowed");
        tokens[fromCoinType].tokenAddress.safeTransferFrom(msg.sender, address(this), amount);
        emit ReceiveSwap(msg.sender, fromCoinType, to, amount);
    }

    function send(address to, uint256 toCoinType, uint256 amount, string calldata swapHash) external onlyOwner {
        require(amount >= tokens[toCoinType].minAmount, "amount must greater or equal to min");
        require(tokens[toCoinType].coinType == toCoinType, "token not allowed");
        require(toCoinType > 0, "token not allowed");
        tokens[toCoinType].tokenAddress.safeTransfer(to, amount);
        emit Send(to, toCoinType, amount, swapHash);
    }

    function tokenInfo(uint256 coinType) public view returns (Tokens memory) {
        require(tokens[coinType].coinType == coinType, "token not allowed");
        require(coinType > 0, "token not allowed");
        return tokens[coinType];
    }

    function newToken(IERC20 addr, uint256 newCoinType, string calldata tokenName, uint256 minAmount) external onlyOwner {
        require(tokens[newCoinType].coinType != newCoinType, "token existed");
        require(newCoinType > 0, "token not allowed");
        tokens[newCoinType].coinType = newCoinType;
        tokens[newCoinType].tokenAddress = addr;
        tokens[newCoinType].tokenName = tokenName;
        tokens[newCoinType].minAmount = minAmount;
    }

    function delToken(uint256 coinType) external onlyOwner {
        require(tokens[coinType].coinType == coinType, "token not allowed");
        require(coinType > 0, "token not allowed");
        uint256 newCoinType = 0;
        tokens[coinType].coinType = newCoinType;
    }

    function editToken(IERC20 addr, uint256 coinType, string calldata tokenName, uint256 minAmount) external onlyOwner {
        require(tokens[coinType].coinType == coinType, "token not allowed");
        require(coinType > 0, "token not allowed");
        tokens[coinType].tokenAddress = addr;
        tokens[coinType].tokenName = tokenName;
        tokens[coinType].minAmount = minAmount;
    }
}
