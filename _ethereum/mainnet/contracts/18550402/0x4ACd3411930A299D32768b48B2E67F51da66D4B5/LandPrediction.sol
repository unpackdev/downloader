pragma solidity ^0.8.23;

import "./Land.sol";

struct Period {
    uint256 number; // period number
    uint256 eth; // ether on period for rewards
    uint256 token; // token on period (not includes stakes) for rewards
    uint256 token2; // token2 on period for rewards
    uint256 tokenStaked; // token stacks sum on period
    bool isTakeTime; // is now take time or not
    bool isDirty; // is period dirty
    uint256 time; // time since the beginning of the period
    uint256 remainingTime; // remaining time until next period
    uint256 endTime; // when period expires
}

struct LandData {
    Land land; // land data
    Period period; // land period data
    uint8 number; // land number
    bool isExists; // is land exists
}

library LandPrediction {
    // time from period start
    function periodTime(Land memory land) internal view returns (uint256) {
        return (block.timestamp - land.creationTime) % land.periodSeconds;
    }

    function nextPeriodRemainingTime(
        Land memory land
    ) internal view returns (uint256) {
        return land.periodSeconds - periodTime(land);
    }

    function nextPeriodTime(
        Land memory land
    ) internal view returns (uint256) {
        return block.timestamp + nextPeriodRemainingTime(land);
    }

    function periodNumber(
        Land memory land
    ) internal view returns (uint256) {
        return (block.timestamp - land.creationTime) / land.periodSeconds;
    }

    function isTakePeriodDirty(
        Land memory land
    ) internal view returns (bool) {
        return land.takePeriodSnapshot != periodNumber(land);
    }

    function isTakeTime(Land memory land) internal view returns (bool) {
        return periodTime(land) < land.takeGoldSeconds;
    }

    function ethOnLand(Land memory land) internal view returns (uint256) {
        if (!isExists(land)) return 0;
        return land.eth;
    }

    function token2OnLand(
        Land memory land
    ) internal view returns (uint256) {
        if (!isExists(land)) return 0;
        return land.token2;
    }

    function ethOnPeriod(Land memory land) internal view returns (uint256) {
        if (!isExists(land)) return 0;
        if (isTakePeriodDirty(land)) return land.eth;
        else return land.ethSnapshot;
    }

    function tokenOnPeriod(
        Land memory land
    ) internal view returns (uint256) {
        if (!isExists(land)) return 0;
        if (isTakePeriodDirty(land)) return land.token1;
        else return land.tokenSnapshot;
    }

    function token2OnPeriod(
        Land memory land
    ) internal view returns (uint256) {
        if (!isExists(land)) return 0;
        if (isTakePeriodDirty(land)) return land.token2;
        else return land.token2Snapshot;
    }

    function tokenStakedOnPeriod(
        Land memory land
    ) internal view returns (uint256) {
        if (isTakePeriodDirty(land)) return land.tokenStaked;
        else return land.tokenStakedSnapshot;
    }

    function ethRewardForTokens(
        Land memory land,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(land)) return 0;
        if (land.tokenStaked == 0) return land.eth;
        return (land.eth * tokenstaked) / land.tokenStaked;
    }

    function tokenRewardForTokens(
        Land memory land,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(land)) return 0;
        if (land.tokenStaked == 0) return land.token1;
        return (land.token1 * tokenstaked) / land.tokenStaked;
    }

    function token2RewardForTokens(
        Land memory land,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(land)) return 0;
        if (land.tokenStaked == 0) return land.token2;
        return (land.token2 * tokenstaked) / land.tokenStaked;
    }

    function ethRewardPeriod(
        Land memory land,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(land)) return 0;
        uint256 stacke = tokenStakedOnPeriod(land);
        if (stacke == 0) return ethOnPeriod(land);
        return (ethOnPeriod(land) * tokenstaked) / stacke;
    }

    function tokenRewardPeriod(
        Land memory land,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(land)) return 0;
        uint256 stacke = tokenStakedOnPeriod(land);
        if (stacke == 0) return tokenOnPeriod(land);
        return (tokenOnPeriod(land) * tokenstaked) / stacke;
    }

    function token2RewardPeriod(
        Land memory land,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(land)) return 0;
        uint256 stacke = tokenStakedOnPeriod(land);
        if (stacke == 0) return token2OnPeriod(land);
        return (token2OnPeriod(land) * tokenstaked) / stacke;
    }

    function isExists(Land memory land) internal view returns (bool) {
        return
            land.id > 0 &&
            (land.eraseTime == 0 || (block.timestamp < land.eraseTime));
    }

    function getData(
        Land memory land,
        uint8 number
    ) internal view returns (LandData memory) {
        return
            LandData(
                land,
                Period(
                    periodNumber(land),
                    ethOnPeriod(land),
                    tokenOnPeriod(land),
                    token2OnPeriod(land),
                    tokenStakedOnPeriod(land),
                    isTakeTime(land),
                    isTakePeriodDirty(land),
                    periodTime(land),
                    nextPeriodRemainingTime(land),
                    nextPeriodTime(land)
                ),
                number,
                isExists(land)
            );
    }

    function changeEraseSeconds(Land storage land, uint256 timer) internal {
        land.eraseTime = block.timestamp + timer;
    }
}
