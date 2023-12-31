//          █████  ███████ ███████ ███████ ████████ ██      ██ ███    ██ ██   ██
//         ██   ██ ██      ██      ██         ██    ██      ██ ████   ██ ██  ██
//         ███████ ███████ ███████ █████      ██    ██      ██ ██ ██  ██ █████
//         ██   ██      ██      ██ ██         ██    ██      ██ ██  ██ ██ ██  ██
//         ██   ██ ███████ ███████ ███████    ██    ███████ ██ ██   ████ ██   ██
//


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AssetLink Team & Advisors Tokens Lock
 * @version 1.0.2
 * @date 2023-08-01
 * @license MIT
 * @author Tech Department, AssetLink
 *
 * @dev Smart contract to lock AssetLink's team and advisors tokens.
 * This contract locks the team and advisors tokens for a period of 2 years,
 * with a subsequent quarterly release of 25% of the remaining tokens.
 * This mechanism is designed to align the team's interests with those of the investors,
 * ensuring a long-term commitment to the project's success.
 *
 * Key Features:
 * - 2 years initial lock.
 * - 25% release every 3 months after the initial lock period.
 * - Only the designated beneficiary can release and claim the tokens.
 * - Built-in checks for release conditions.
 **/

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

interface IMainContract is IERC20 {
    function handleReleasedTokens(uint256 amount) external;
}

contract ASETTeamTokensLock is ReentrancyGuard {
    address public beneficiary;
    uint256 public initialReleaseTime;
    uint256 public lastReleaseTime;
    IERC20 public token;
    uint256 public releasedPercentage = 0;
    bool public initialized = false;

    event Initialized(address indexed token);
    event TokensReleased(uint256 amount);

    // Modifiers
    modifier onlyBeneficiary() {
        require(
            msg.sender == beneficiary,
            "Only the beneficiary can call this function"
        );
        _;
    }

    modifier onlyOnce() {
        require(!initialized, "Already initialized");
        _;
    }

    constructor() {
        beneficiary = msg.sender;
        initialReleaseTime = block.timestamp + 730 days; // 2 years from now
    }

    /**
     * @dev Initializes the contract with the token address.
     * @param _token Address of the token contract.
     */
    function initialize(address _token) external onlyBeneficiary onlyOnce {
        require(
            _token != address(0),
            "Token address cannot be the zero address"
        );
        token = IERC20(_token);
        initialized = true;
        emit Initialized(_token);
    }

    /**
     * @dev Releases a portion of the locked tokens to the beneficiary.
     */
    function release() public onlyBeneficiary nonReentrant {
        require(initialized, "Contract not initialized");
        require(
            block.timestamp >= initialReleaseTime,
            "Tokens are still locked"
        );
        require(
            releasedPercentage < 100,
            "All tokens have already been released"
        );

        uint256 monthsSinceLastRelease = (block.timestamp - lastReleaseTime) / 30 days;
        require(
            monthsSinceLastRelease >= 3 || releasedPercentage == 0,
            "Less than 3 months since last release or tokens already released this quarter"
        );

        uint256 amountToRelease = (token.balanceOf(address(this)) * 25) / 100; // 25% of remaining balance
        releasedPercentage += 25;

        lastReleaseTime = block.timestamp;

        require(amountToRelease > 0, "No tokens to release");

        // Transfer tokens to the beneficiary
        token.transfer(beneficiary, amountToRelease);

        emit TokensReleased(amountToRelease);
    }
}
