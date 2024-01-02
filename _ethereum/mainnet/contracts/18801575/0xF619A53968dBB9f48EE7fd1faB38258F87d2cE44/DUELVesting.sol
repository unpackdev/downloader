// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";

contract VestingBase is Ownable {
    address duelToken;

    constructor(address _duelToken) Ownable(msg.sender) {
        duelToken = _duelToken;
    }

    function allocateDUEL(address, uint256) external virtual {}

    function allocateDUEL(address, uint256, uint256) external virtual {}

    function claimDUEL() external virtual {}
}

/// @title Core static vesting contract allowing for cliff and variable percentage releases
/// @author Haider
/// @notice Contract uses pre-approved DUEL amount to transferFrom() the owner()
/// @notice Deploy 3 versions: Private Sale, Team & Advisors, Operations & Marketing
contract StaticVesting is VestingBase {
    address icoContract;
    uint256[] releaseTimestamps; // 13 months day 1 timestamps
    uint16[] releasePercentages; // 13 months release percentage [0,0,0,10,10,10,...]
    mapping(address => uint256) public vestedAllocations; // wallet => total allocated
    mapping(address => uint256) public vestedClaims; // wallet => total claimed

    constructor(
        address _icoContract,
        address _duelToken,
        uint256[] memory _releaseTimestamps,
        uint16[] memory _releasePercentages
    ) VestingBase(_duelToken) {
        require(
            releaseTimestamps.length == releasePercentages.length,
            "Parameters length mismatch"
        );
        icoContract = _icoContract;
        releaseTimestamps = _releaseTimestamps;
        releasePercentages = _releasePercentages;
    }

    function updateReleaseParameters(
        uint256[] memory _releaseTimestamps,
        uint16[] memory _releasePercentages
    ) external onlyOwner {
        require(
            releaseTimestamps.length == releasePercentages.length,
            "Parameters length mismatch"
        );
        releaseTimestamps = _releaseTimestamps;
        releasePercentages = _releasePercentages;
    }

    function allocateDUEL(address wallet, uint256 amount) external override {
        require(_msgSender() == icoContract || _msgSender() == owner(), "Access forbidden");
        require(vestedAllocations[wallet] == 0, "Vesting already in progress");
        vestedAllocations[wallet] = amount;
    }

    function claimDUEL() external override {
        require(
            vestedAllocations[_msgSender()] > 0 &&
                vestedAllocations[_msgSender()] > vestedClaims[_msgSender()],
            "Nothing to claim"
        );

        uint16 cumulativePercentage = 0; // Cumulative percentage released so far
        for (uint8 i = 0; i < releaseTimestamps.length; i++) {
            if (releaseTimestamps[i] > block.timestamp) {
                break;
            }
            cumulativePercentage += releasePercentages[i];
        }

        uint256 availableClaim = (vestedAllocations[_msgSender()] *
            cumulativePercentage) / 100;
        require(
            availableClaim > vestedClaims[_msgSender()],
            "Period already claimed"
        );

        uint256 unclaimedTokens = availableClaim - vestedClaims[_msgSender()];
        vestedClaims[_msgSender()] += unclaimedTokens;
        IERC20(duelToken).transferFrom(owner(), _msgSender(), unclaimedTokens);
    }
}

/// @title Core dynamic vesting contract to be used upon RAINxDUEL conversion
/// @author Haider
/// @notice Contract uses pre-approved DUEL amount to transferFrom() the owner()
/// @dev Does not allow for two separate schedules for same wallet
contract DynamicVesting is VestingBase {
	mapping(address => uint256) public startTimes; // wallet => claim start time
	mapping(address => uint256[]) public releaseAmounts; // wallet => [amount30d, amount90d]

    constructor(address _duelToken) VestingBase(_duelToken) {}

    function allocateDUEL(address wallet, uint256 amount30d, uint256 amount90d) external override {
        require(_msgSender() == duelToken, "Access forbidden");
		require(startTimes[wallet] == 0, "Vesting already in progress");
		startTimes[wallet] = block.timestamp;
		releaseAmounts[wallet] = [amount30d, amount90d];
    }

    function claimDUEL() external override {
		require(startTimes[_msgSender()] >= 0, "Nothing vested");

		uint256 availableAmount = 0;
		if (block.timestamp >= startTimes[_msgSender()] + 30 days && releaseAmounts[_msgSender()][0] > 0) {
			availableAmount += releaseAmounts[_msgSender()][0];
			releaseAmounts[_msgSender()][0] = 0;
		}
		if (block.timestamp >= startTimes[_msgSender()] + 90 days && releaseAmounts[_msgSender()][1] > 0) {
			availableAmount += releaseAmounts[_msgSender()][1];
			releaseAmounts[_msgSender()][1] = 0;
		}

		require(availableAmount > 0, "Nothing to claim");
		IERC20(duelToken).transferFrom(owner(), _msgSender(), availableAmount);
	}
}
