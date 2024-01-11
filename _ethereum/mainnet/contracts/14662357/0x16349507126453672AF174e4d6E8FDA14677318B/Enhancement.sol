// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./EthereumClockToken.sol";
import "./IEnhancement.sol";
import "./Ownable.sol";

contract Enhancement is IEnhancement, Ownable {
    EthereumClockToken public ethClockToken;
    // Enhancement lock time
    uint256 enhanceLockTime = 30 * 24 * 60 * 60;//30 days;

    /// Enhancement Allowed Flag
    bool public _ENHANCEMENT_ALLOWED_;

    mapping(uint256 => bool) public pendingGodTierList;

    mapping(uint256 => bool) public pendingEnhancedList;

    mapping(uint256 => bool) public pendingFailedList;

    mapping(uint256 => bool) public enhanceRequested;

    mapping(uint256 => uint256) public enhanceRequestTime;

    // Initial God-Tier Probability 0.10%
    uint256 public godTierProbability = 10;

    // Initial Failed Probability 3.00%
    uint256 public failedProbability = 300;

    // Initial Frozen Probability 2.00%
    uint256 public frozenProbability = 200;

    // Initial Burn Probability 10.00%
    uint256 public burnProbability = 1000;

    // Level => Type => Probability
    mapping(uint256 => mapping(uint256 => uint256)) public probabilities;

    mapping(bytes32 => uint256) private requestIdToToken;

    constructor(address token) {
        ethClockToken = EthereumClockToken(token);
        calcProbability();
    }

    // ============ System Control Functions ============

    function enableEnhancement() external onlyOwner {
        _ENHANCEMENT_ALLOWED_ = true;
    }

    function disableEnhancement() external onlyOwner {
        _ENHANCEMENT_ALLOWED_ = false;
    }

    function setLockTime(uint256 lockTime) external onlyOwner {
        enhanceLockTime = lockTime;
    }

    /**
     * @notice Calc Probability function
     */
    function calcProbability() internal {
        uint256 maxTokenLevel = ethClockToken._MAX_TOKEN_LEVEL_();

        for (uint256 index = 1; index <= maxTokenLevel; index++) {
            // God-Tier Calculation
            probabilities[index][1] = index * godTierProbability;

            // Failed Calculation
            probabilities[index][2] = failedProbability * (index + 2);

            // Frozen Calculation
            probabilities[index][3] = frozenProbability * index;

            // Burnt Calculation
            probabilities[index][4] = (index * burnProbability) / 3;

            // Enhancement Calculation
            probabilities[index][0] =
            10000 -
            probabilities[index][1] -
            probabilities[index][2] -
            probabilities[index][3] -
            probabilities[index][4];
        }
    }

    /**
     * @notice Check if enhancement is available
     */
    function isAvailableEnhance(uint256 tokenId) public view returns (bool) {
        if (enhanceRequestTime[tokenId] + enhanceLockTime <= _getNow()) {
            return true;
        }
        return false;
    }

    /**
     * @notice Enhance Request as external from frontend
     */
    function enhanceRequest(uint256 tokenId) external {
        require(_ENHANCEMENT_ALLOWED_, "ENHANCEMENT NOT ALLOWED");
        require(
            ethClockToken.ownerOf(tokenId) == msg.sender,
            "NOT OWNER OF TOKEN ID"
        );
        if (!enhanceRequested[tokenId]) {
            enhanceRequestTime[tokenId] = _getNow();
            enhanceRequested[tokenId] = true;
        }
        require(isAvailableEnhance(tokenId), "NOT AVAILABLE TO ENHANCE");

        //Enhancement Process
        enhanceProcess(tokenId);
    }

    /**
     * @notice Enhancement Request Process
     */
    function enhanceProcess(uint256 tokenId) internal returns (bool) {
        require(!ethClockToken.frozen(tokenId), "FROZEN TOKEN UNABLE TO ENHANCEMENT");
        require(!ethClockToken.charred(tokenId), "CHARRED TOKEN UNABLE TO ENHANCEMENT");

        uint256 randomValue = uint256(keccak256(abi.encode(_getNow(), tokenId)));
        uint256 percentValue = randomValue % 10000;
        uint256 level = ethClockToken.levels(tokenId);

        uint256 downBoundary = 0;
        uint256 upBoundary = probabilities[level][0];
        // Enhancement Case:
        if (level == 1 || (downBoundary <= percentValue && percentValue < upBoundary)) {
            require(
                !pendingEnhancedList[tokenId],
                "Token is already existed in pending enhanced list"
            );
            pendingEnhancedList[tokenId] = true;
            emit BeforeEnhanced(tokenId);
            return true;
        }

        downBoundary = upBoundary;
        upBoundary = upBoundary + probabilities[level][1];
        // God-Tier Case:
        if (downBoundary <= percentValue && percentValue < upBoundary) {
            require(
                !pendingGodTierList[tokenId],
                "Token is already existed in pending god-tier list"
            );
            pendingGodTierList[tokenId] = true;
            emit BeforeGodTier(tokenId);
            return true;
        }

        downBoundary = upBoundary;
        upBoundary = upBoundary + probabilities[level][2];
        // Failed Case:
        if (downBoundary <= percentValue && percentValue < upBoundary) {
            require(
                !pendingFailedList[tokenId],
                "Token is already existed in pending failed list"
            );
            pendingFailedList[tokenId] = true;
            emit BeforeFailed(tokenId);
            return true;
        }

        downBoundary = upBoundary;
        upBoundary = upBoundary + probabilities[level][3];
        // Frozen Case:
        if (downBoundary <= percentValue && percentValue < upBoundary) {
            ethClockToken.setFrozen(tokenId);
            return true;
        }

        // Charred Case:
        downBoundary = upBoundary;
        upBoundary = 10000;
        if (downBoundary <= percentValue && percentValue < upBoundary) {
            ethClockToken.setCharred(tokenId);
            return true;
        }

        return false;
    }

    /**
     * @notice Enhancement Request
     */
    function enhance(uint256 tokenId) external {
        require(pendingEnhancedList[tokenId], "TOKEN IS NOT ABLE TO ENHANCE");
        require(
            ethClockToken.ownerOf(tokenId) == msg.sender,
            "NOT OWNER OF TOKEN"
        );

        require(
            ethClockToken.enhance(tokenId),
            "FAILED: ENHANCEMENT"
        );
        pendingEnhancedList[tokenId] = false;
    }

    /**
     * @notice GOD-TIER Request
     */
    function godTier(uint256 tokenId) external {
        require(pendingGodTierList[tokenId], "TOKEN IS NOT ABLE TO GOD-TIER");
        require(
            ethClockToken.ownerOf(tokenId) == msg.sender,
            "NOT OWNER OF TOKEN"
        );

        require(ethClockToken.godTier(tokenId), "FAILED: GOD_TIER");
        pendingGodTierList[tokenId] = false;
    }

    /**
     * @notice FAIL Request
     */
    function fail(uint256 tokenId) external {
        require(pendingFailedList[tokenId], "Token is not able to god-tier");
        require(
            ethClockToken.ownerOf(tokenId) == msg.sender,
            "Not owner of token"
        );

        require(ethClockToken.fail(tokenId));
        pendingFailedList[tokenId] = false;
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}
