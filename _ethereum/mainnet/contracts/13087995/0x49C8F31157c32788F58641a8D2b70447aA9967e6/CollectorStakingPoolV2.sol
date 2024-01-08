// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/**
 * Staking pool for the score calculated by the polymon-collector-staking-backend.
 */
contract CollectorStakingPoolV2 is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant DIV_PRECISION = 1e18;

    struct PendingRewardResult {
        uint256 intervalId;
        uint256 reward;
    }

    struct PendingRewardRequest {
        uint256 intervalId;
        uint256 points;
        uint256 totalPoints;
    }

    struct UserData {
        uint256 lastHarvestedInterval;
    }

    struct Interval {
        uint256 rewardAmount;
        uint256 claimedRewardAmount;
    }

    // PMON
    IERC20 private token;

    // expireAfter = 4 means there are up to 3 closed intervals and 1 open
    uint256 public expireAfter;
    uint256 public intervalLengthInSec;

    address trustedSigner;

    uint256 public nextIntervalTimestamp;
    uint256 public intervalIdCounter;
    mapping(uint256 => Interval) idToInterval;

    mapping(uint256 => UserData) userIdToUserData;

    event AddRewards(uint256 amount);
    event IntervalClosed(uint256 newInterval);
    event RedistributeRewards(uint256 unclaimedRewards);

    function initialize(
        IERC20 _token,
        uint256 _expireAfter,
        uint256 _intervalLengthInSec,
        uint256 endOfFirstInterval,
        address _trustedSigner
    ) public initializer {
        intervalIdCounter = 1;
        token = _token;
        expireAfter = _expireAfter;
        intervalLengthInSec = _intervalLengthInSec;
        nextIntervalTimestamp = endOfFirstInterval;
        trustedSigner = _trustedSigner;
        OwnableUpgradeable.__Ownable_init();
    }

    function setExpireAfter(uint256 _expireAfter) external onlyOwner {
        if (isNextIntervalReached()) {
            // cleanup the current state first if necessary
            closeCurrentInterval();
        }
        if (_expireAfter < expireAfter && intervalIdCounter > _expireAfter) {
            // cleanup expired intervals
            uint256 iStart = 1;
            if (intervalIdCounter > expireAfter) {
                iStart = intervalIdCounter - expireAfter;
            }
            for (uint256 i = iStart; i < intervalIdCounter - _expireAfter; i++) {
                redistributeRewards(i);
            }
        }
        expireAfter = _expireAfter;
    }

    function redistributeRewards(uint256 intervalId) private {
        Interval memory oldInterval = idToInterval[intervalId];
        if (oldInterval.rewardAmount > 0) {
            // redistribute unclaimed rewards
            uint256 unclaimedRewards = oldInterval.rewardAmount - oldInterval.claimedRewardAmount;
            if (unclaimedRewards > 0) {
                idToInterval[intervalIdCounter].rewardAmount += unclaimedRewards;
                emit RedistributeRewards(unclaimedRewards);
            }
            delete idToInterval[intervalId];
        }
    }

    function setTrustedSigner(address _trustedSigner) external onlyOwner {
        trustedSigner = _trustedSigner;
    }

    /**
     * The new interval length does not affect the current interval
     */
    function setIntervalLengthInSec(uint256 _intervalLengthInSec) external onlyOwner {
        intervalLengthInSec = _intervalLengthInSec;
    }

    function isNextIntervalReached() private view returns (bool) {
        return block.timestamp >= nextIntervalTimestamp;
    }

    function addRewards(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        if (isNextIntervalReached()) {
            closeCurrentInterval();
        }
        token.safeTransferFrom(msg.sender, address(this), amount);
        // add rewards to the current interval
        idToInterval[intervalIdCounter].rewardAmount += amount;
        emit AddRewards(amount);
    }

    function closeCurrentInterval() private {
        ++intervalIdCounter;
        nextIntervalTimestamp += intervalLengthInSec;
        // cleanup expired interval
        if (intervalIdCounter > expireAfter) {
            redistributeRewards(intervalIdCounter - expireAfter);
        }
        emit IntervalClosed(intervalIdCounter - 1);
    }

    function splitSignature(bytes memory signature) private pure returns (uint8, bytes32, bytes32) {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        assembly {
            sigR := mload(add(signature, 32))
            sigS := mload(add(signature, 64))
            sigV := byte(0, mload(add(signature, 96)))
        }
        return (sigV, sigR, sigS);
    }

    /**
     * Check the signature of the harvest function.
     */
    function signatureVerification(
        uint256 userId,
        address[] memory userWallets,
        uint256[] memory harvestRequests,
        bytes memory signature
    )
    private
    returns (bool)
    {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
        (sigV, sigR, sigS) = splitSignature(signature);
        bytes32 msg = keccak256(abi.encodePacked(userId, userWallets, harvestRequests));
        return trustedSigner == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msg)), sigV, sigR, sigS);
    }

    /**
     * To make it easier to verify the signature, harvestRequests contains an intervalId in each even index and the
     * reward for the interval in the next odd index.
     */
    function harvest(
        uint256 userId,
        address[] memory userWallets,
        uint256[] memory harvestRequests,
        bytes memory signature
    )
    external
    {
        bool senderAssociatedWithTheUser = false;
        for (uint i = 0; i < userWallets.length && !senderAssociatedWithTheUser; i++) {
            senderAssociatedWithTheUser = msg.sender == userWallets[i];
        }
        require(
            senderAssociatedWithTheUser,
            "Sender is not associated with the user"
        );
        require(
            signatureVerification(userId, userWallets, harvestRequests, signature),
            "Invalid signer or signature"
        );
        if (isNextIntervalReached()) {
            closeCurrentInterval();
        }

        uint256 totalRewards = 0;
        for (uint i = 0; i < harvestRequests.length; i += 2) {
            uint256 intervalId = harvestRequests[i];
            // all of the latest harvest intervals have to be older than the current. Prevent double harvest.
            require(
                userIdToUserData[userId].lastHarvestedInterval < intervalId,
                "Tried to harvest already harvested interval"
            );
            // Prevent harvest of expired interval.
            require(
                intervalIdCounter < intervalId + expireAfter,
                "Tried to harvest expired interval"
            );
            uint256 reward = harvestRequests[i + 1];
            // update latest harvest interval
            userIdToUserData[userId].lastHarvestedInterval = intervalId;
            // update the claimed rewards for this interval
            idToInterval[intervalId].claimedRewardAmount += reward;
            // sum total rewards
            totalRewards += reward;
        }
        // transfer reward to the user
        token.safeTransfer(msg.sender, totalRewards);
    }

    function isExpiredButNotProcessed(uint256 intervalId) private view returns (bool) {
        return isNextIntervalReached()
                && intervalIdCounter + 1 > expireAfter
                && intervalIdCounter - expireAfter == intervalId;
    }

    function pendingRewards(uint256 userId, PendingRewardRequest[] memory pendingRewardRequests)
    external
    view
    returns (PendingRewardResult[] memory)
    {
        uint256 lastHarvestedInterval = userIdToUserData[userId].lastHarvestedInterval;
        PendingRewardResult[] memory rewards = new PendingRewardResult[](pendingRewardRequests.length);
        // calculate rewards for each interval
        for (uint i = 0; i < pendingRewardRequests.length; i++) {
            PendingRewardRequest memory request = pendingRewardRequests[i];
            // only calculate rewards for valid interval ID's
            if (
                // interval is not already harvested
                lastHarvestedInterval < request.intervalId
                // interval is closed
                && (request.intervalId < intervalIdCounter || (request.intervalId == intervalIdCounter && isNextIntervalReached()))
                && !isExpiredButNotProcessed(request.intervalId)
            ) {
                rewards[i] = PendingRewardResult(
                    request.intervalId,
                    calculateReward(idToInterval[request.intervalId].rewardAmount, request.totalPoints, request.points)
                );
            } else {
                rewards[i] = PendingRewardResult(request.intervalId, 0);
            }
        }
        return rewards;
    }

    function calculateReward(uint256 intervalRewardAmount, uint256 totalPointsForTheInterval, uint256 points)
    private
    view
    returns (uint256)
    {
        return intervalRewardAmount * DIV_PRECISION / totalPointsForTheInterval * points / DIV_PRECISION;
    }

    function getLastHarvestedInterval(uint256 userId)
    external
    view
    returns (uint256)
    {
        return userIdToUserData[userId].lastHarvestedInterval;
    }

    function recoverToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), amount);
    }
}
