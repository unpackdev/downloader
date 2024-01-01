// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./IERC20.sol";

// ____  _______   ____________
// \   \/  /\   \ /   /  _____/
//  \     /  \   Y   /   \  ___
//  /     \   \     /\    \_\  \
// /___/\  \   \___/  \______  /2023
//       \_/XVG              \/
//
// https://github.com/vergecurrency/erc20

contract XVGClaim is Ownable {

    IERC20 immutable XVG;
    uint256 immutable maxClaims;
    uint256 public minClaimAmount = 10_000 ether;
    uint256 public maxClaimAmount = 25_000 ether;
    uint256 public totalClaims;
    mapping(address => bool) public claimed;

    error AlreadyClaimed();
    error NotEligible();
    error TransferFailed();
    error ClaimingStopped();

    event Claim(address indexed user, uint256 amount);

    constructor(address owner_, address xvg_, uint256 maxClaims_) {
        XVG = IERC20(xvg_);
        maxClaims = maxClaims_;
        transferOwnership(owner_);
    }

    /// @notice Claims a random amount of XVG tokens between minClaimAmount and maxClaimAmount
    function claim() external returns (uint256 amount) {
        if (totalClaims + 1 > maxClaims) revert ClaimingStopped();
        if (claimed[msg.sender]) revert AlreadyClaimed();
        if (XVG.balanceOf(msg.sender) > 0) revert NotEligible();
        claimed[msg.sender] = true;
        amount = getRandomAmount();
        bool success = XVG.transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
        totalClaims++;

        emit Claim(msg.sender, amount);
    }

    /// @notice Sets the min and max claim amount
    function setMinMaxClaimAmount(uint256 min, uint256 max) external onlyOwner {
        minClaimAmount = min;
        maxClaimAmount = max;
    }

    /// @notice Withdraws any ERC20 token to the owner
    function withdrawToken(IERC20 token, uint256 amount) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (amount == 0) amount = balance;
        token.transfer(owner(), amount);
    }

    /// @dev Gets a random amount between minClaimAmount and maxClaimAmount
    function getRandomAmount() internal view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender
                )
            )
        ) % (maxClaimAmount - minClaimAmount) + minClaimAmount;
    }
}
