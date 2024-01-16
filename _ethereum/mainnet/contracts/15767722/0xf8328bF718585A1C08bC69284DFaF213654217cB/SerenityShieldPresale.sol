// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract SerenityShieldPresale is Ownable {
    using SafeERC20 for IERC20;

    address public recipient;
    uint256 public price;
    mapping(address => uint256) public holders;
    address[] public allowedTokens;

    event Deposited(
        address usdTokenAddress,
        bytes32 solAddress,
        uint256 usdAmount,
        uint256 tokenAmount
    );

    constructor(address _recipient, uint256 _price, address[] memory _allowedTokens) {
        recipient = _recipient;
        price = _price;
        allowedTokens = _allowedTokens;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    function setAllowedTokens(address[] memory _allowedTokens) external onlyOwner {
        allowedTokens = _allowedTokens;
    }

    function isAllowed(address tokenAddress) internal view returns (bool) {
        for (uint idx = 0; idx < allowedTokens.length; idx++) {
            if (allowedTokens[idx] == tokenAddress) {
                return true;
            }
        }

        return false;
    }

    function deposit(address usdTokenAddress, uint256 usdAmount, bytes32 solAddress) external {
        // Check token address is in allowed list
        require(isAllowed(usdTokenAddress), "Submitted token is not allowed");

        // Transfer token
        IERC20(usdTokenAddress).safeTransferFrom(
            msg.sender,
            recipient,
            usdAmount
        );
        uint256 tokenAmount = (usdAmount * price) / 10000;
        holders[msg.sender] += tokenAmount;

        emit Deposited(
            usdTokenAddress,
            solAddress,
            usdAmount,
            tokenAmount
        );
    }
}
