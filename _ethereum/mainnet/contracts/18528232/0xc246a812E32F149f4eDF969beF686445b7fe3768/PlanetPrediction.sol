pragma solidity ^0.8.21;

import "./Planet.sol";

struct Period {
    uint256 number; // period number
    uint256 eth; // ether on period for rewards
    uint256 token; // token on period (not includes stakes) for rewards
    uint256 token2; // token2 on period for rewards
    uint256 tokenStaked; // token stacks sum on period
    bool isClaimTime; // is now claim time or not
    bool isDirty; // is period dirty
    uint256 time; // time since the beginning of the period
    uint256 remainingTime; // remaining time until next period
    uint256 endTime; // when period expires
}

struct PlanetData {
    Planet planet; // planet data
    Period period; // planet period data
    uint8 number; // planet number
    bool isExists; // is planet exists
}

library PlanetPrediction {
    // time from period start
    function periodTime(Planet memory planet) internal view returns (uint256) {
        return (block.timestamp - planet.creationTime) % planet.periodTimer;
    }

    function nextPeriodRemainingTime(
        Planet memory planet
    ) internal view returns (uint256) {
        return planet.periodTimer - periodTime(planet);
    }

    function nextPeriodTime(
        Planet memory planet
    ) internal view returns (uint256) {
        return block.timestamp + nextPeriodRemainingTime(planet);
    }

    function periodNumber(
        Planet memory planet
    ) internal view returns (uint256) {
        return (block.timestamp - planet.creationTime) / planet.periodTimer;
    }

    function isClaimPeriodDirty(
        Planet memory planet
    ) internal view returns (bool) {
        return planet.claimPeriodSnapshot != periodNumber(planet);
    }

    function isClaimTime(Planet memory planet) internal view returns (bool) {
        return periodTime(planet) < planet.claimResourcesTimer;
    }

    function ethOnPlanet(Planet memory planet) internal view returns (uint256) {
        if (!isExists(planet)) return 0;
        return planet.eth;
    }

    function token2OnPlanet(
        Planet memory planet
    ) internal view returns (uint256) {
        if (!isExists(planet)) return 0;
        return planet.token2;
    }

    function ethOnPeriod(Planet memory planet) internal view returns (uint256) {
        if (!isExists(planet)) return 0;
        if (isClaimPeriodDirty(planet)) return planet.eth;
        else return planet.ethSnapshot;
    }

    function tokenOnPeriod(
        Planet memory planet
    ) internal view returns (uint256) {
        if (!isExists(planet)) return 0;
        if (isClaimPeriodDirty(planet)) return planet.token;
        else return planet.tokenSnapshot;
    }

    function token2OnPeriod(
        Planet memory planet
    ) internal view returns (uint256) {
        if (!isExists(planet)) return 0;
        if (isClaimPeriodDirty(planet)) return planet.token2;
        else return planet.token2Snapshot;
    }

    function tokenStakedOnPeriod(
        Planet memory planet
    ) internal view returns (uint256) {
        if (isClaimPeriodDirty(planet)) return planet.tokenStaked;
        else return planet.tokenStakedSnapshot;
    }

    function ethRewardForTokens(
        Planet memory planet,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(planet)) return 0;
        if (planet.tokenStaked == 0) return planet.eth;
        return (planet.eth * tokenstaked) / planet.tokenStaked;
    }

    function tokenRewardForTokens(
        Planet memory planet,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(planet)) return 0;
        if (planet.tokenStaked == 0) return planet.token;
        return (planet.token * tokenstaked) / planet.tokenStaked;
    }

    function token2RewardForTokens(
        Planet memory planet,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(planet)) return 0;
        if (planet.tokenStaked == 0) return planet.token2;
        return (planet.token2 * tokenstaked) / planet.tokenStaked;
    }

    function ethRewardPeriod(
        Planet memory planet,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(planet)) return 0;
        uint256 stacke = tokenStakedOnPeriod(planet);
        if (stacke == 0) return ethOnPeriod(planet);
        return (ethOnPeriod(planet) * tokenstaked) / stacke;
    }

    function tokenRewardPeriod(
        Planet memory planet,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(planet)) return 0;
        uint256 stacke = tokenStakedOnPeriod(planet);
        if (stacke == 0) return tokenOnPeriod(planet);
        return (tokenOnPeriod(planet) * tokenstaked) / stacke;
    }

    function token2RewardPeriod(
        Planet memory planet,
        uint256 tokenstaked
    ) internal view returns (uint256) {
        if (tokenstaked == 0 || !isExists(planet)) return 0;
        uint256 stacke = tokenStakedOnPeriod(planet);
        if (stacke == 0) return token2OnPeriod(planet);
        return (token2OnPeriod(planet) * tokenstaked) / stacke;
    }

    function isExists(Planet memory planet) internal view returns (bool) {
        return
            planet.id > 0 &&
            (planet.destroyTime == 0 || (block.timestamp < planet.destroyTime));
    }

    function getData(
        Planet memory planet,
        uint8 number
    ) internal view returns (PlanetData memory) {
        return
            PlanetData(
                planet,
                Period(
                    periodNumber(planet),
                    ethOnPeriod(planet),
                    tokenOnPeriod(planet),
                    token2OnPeriod(planet),
                    tokenStakedOnPeriod(planet),
                    isClaimTime(planet),
                    isClaimPeriodDirty(planet),
                    periodTime(planet),
                    nextPeriodRemainingTime(planet),
                    nextPeriodTime(planet)
                ),
                number,
                isExists(planet)
            );
    }

    function setDestroyTimer(Planet storage planet, uint256 timer) internal {
        planet.destroyTime = block.timestamp + timer;
    }
}
