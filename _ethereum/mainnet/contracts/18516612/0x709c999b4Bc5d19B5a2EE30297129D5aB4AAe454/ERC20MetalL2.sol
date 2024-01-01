// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./Ownable.sol";
import "./ERC20OneWayWrapper.sol";

/// @title Metal L2 Wrapper Contract
/// @author Metallicus
/// @notice You can only wrap one way
contract MetalL2Token is ERC20, ERC20Permit, ERC20OneWayWrapper, Ownable {
    uint256 private immutable _secondsInYear = 86_400 * 365;
    uint256 private immutable _yearlyRelease = 6_000_000;
    uint256 private _lastReleaseTime;

    /**
     * @dev Mint appropriate amount for airdrop and developer bootstrap
     */
    constructor(
        IERC20 _underlying
    ) ERC20("Metal", "MTL") ERC20Permit("Metal") ERC20OneWayWrapper(_underlying) Ownable(msg.sender) {
        _lastReleaseTime = block.timestamp;
        _mint(msg.sender, 12_000_000 * 10 ** decimals());
    }

    /**
     * @dev Override default decimals of 18 to 8
     */
    function decimals() public pure override(ERC20) returns (uint8) {
        return 8;
    }

    /**
     * @dev Release accumulated to owner
     */
    function release() public onlyOwner {
        // Calculate amount
        uint256 timePassed = block.timestamp - _lastReleaseTime;
        uint256 amount = (timePassed * _yearlyRelease * (10 ** decimals())) / _secondsInYear;

        // Check amount
        if (amount <= 0) {
            revert("No release available");
        }

        // Update last release time
        _lastReleaseTime = block.timestamp;
        
        // Mint
        _mint(owner(), amount);
    }
}
