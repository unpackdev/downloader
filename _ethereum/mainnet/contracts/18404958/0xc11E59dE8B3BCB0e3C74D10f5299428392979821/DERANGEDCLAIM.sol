// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract DERANGEDCLAIM is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    uint256 public tokenPerClaim = 1041300000000000000000000;

    mapping(address => bool) public hasClaimed;

    event TokensClaimed(address indexed user, uint256 amount);
    event LiquidityAdded(uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function claimTokens() external {
        require(!hasClaimed[msg.sender], "You have already claimed tokens");

        token.transfer(msg.sender, tokenPerClaim);

        hasClaimed[msg.sender] = true;

        emit TokensClaimed(msg.sender, tokenPerClaim);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    function setTokenPerClaim(uint256 _tokenPerClaim) external onlyOwner {
        tokenPerClaim = _tokenPerClaim;
    }

    function addLiquidity(uint256 amount) external onlyOwner {
        require(token.transferFrom(owner(), address(this), amount), "Token transfer failed");
        emit LiquidityAdded(amount);
    }
}
