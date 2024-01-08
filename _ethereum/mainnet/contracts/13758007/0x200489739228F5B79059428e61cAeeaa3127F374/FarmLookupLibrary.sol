// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFarm.sol";

library FarmLookupLibrary {
    struct Counters {
        uint256 skipCounter;
        uint256 counter;
    }

    function getTotalStaked(
        address farmAddress,
        mapping(uint8 => IFarm.Stake[]) storage den
    )
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        IFarm farm = IFarm(farmAddress);

        chickens = farm.totalChickenStaked();

        tier5Noodles = uint16(den[farm.MAX_TIER_SCORE()].length);
        tier4Noodles = uint16(den[farm.MAX_TIER_SCORE() - 1].length);
        tier3Noodles = uint16(den[farm.MAX_TIER_SCORE() - 2].length);
        tier2Noodles = uint16(den[farm.MAX_TIER_SCORE() - 3].length);
        tier1Noodles = uint16(den[farm.MAX_TIER_SCORE() - 4].length);

        noodles =
            tier5Noodles +
            tier4Noodles +
            tier3Noodles +
            tier2Noodles +
            tier1Noodles;
    }

    function getStakedBalanceOf(
        address farmAddress,
        address tokenOwner,
        mapping(uint16 => IFarm.Stake) storage henHouse,
        mapping(uint8 => IFarm.Stake[]) storage den,
        mapping(uint16 => uint16) storage denIndices
    )
        public
        view
        returns (
            uint16 chickens,
            uint16 noodles,
            uint16 tier5Noodles,
            uint16 tier4Noodles,
            uint16 tier3Noodles,
            uint16 tier2Noodles,
            uint16 tier1Noodles
        )
    {
        IFarm farm = IFarm(farmAddress);

        uint16 supply = uint16(farm.chickenNoodle().totalSupply());

        for (uint16 tokenId = 1; tokenId <= supply; tokenId++) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (farm.isChicken(tokenId)) {
                if (henHouse[tokenId].owner == tokenOwner) {
                    chickens++;
                }
            } else {
                uint8 tierScore = farm.tierScoreForNoodle(tokenId);

                if (den[tierScore][denIndices[tokenId]].owner == tokenOwner) {
                    if (tierScore == 8) {
                        tier5Noodles++;
                    } else if (tierScore == 7) {
                        tier4Noodles++;
                    } else if (tierScore == 6) {
                        tier3Noodles++;
                    } else if (tierScore == 5) {
                        tier2Noodles++;
                    } else if (tierScore == 4) {
                        tier1Noodles++;
                    }
                }
            }
        }

        noodles =
            tier5Noodles +
            tier4Noodles +
            tier3Noodles +
            tier2Noodles +
            tier1Noodles;
    }

    function getStakedChickensForOwner(
        address farmAddress,
        IFarm.PagingData memory data,
        mapping(uint16 => IFarm.Stake) storage henHouse,
        mapping(uint8 => IFarm.Stake[]) storage den,
        mapping(uint16 => uint16) storage denIndices
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint256[] memory timeTellUnlock,
            uint256[] memory earnedEgg
        )
    {
        IFarm farm = IFarm(farmAddress);

        (uint16 tokensOwned, , , , , , ) = getStakedBalanceOf(
            farmAddress,
            data.tokenOwner,
            henHouse,
            den,
            denIndices
        );

        (uint256 tokensSize, uint256 pageStart) = _paging(
            tokensOwned,
            data.limit,
            data.page
        );

        tokens = new uint16[](tokensSize);
        timeTellUnlock = new uint256[](tokensSize);
        earnedEgg = new uint256[](tokensSize);

        Counters memory counters;

        uint16 supply = uint16(farm.chickenNoodle().totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counters.counter < tokens.length;
            tokenId++
        ) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (
                farm.isChicken(tokenId) &&
                henHouse[tokenId].owner == data.tokenOwner
            ) {
                IFarm.Stake memory stake = henHouse[tokenId];

                if (counters.skipCounter < pageStart) {
                    counters.skipCounter++;
                    continue;
                }

                tokens[counters.counter] = tokenId;
                timeTellUnlock[counters.counter] = block.timestamp -
                    stake.value <
                    farm.MINIMUM_TO_EXIT()
                    ? farm.MINIMUM_TO_EXIT() - (block.timestamp - stake.value)
                    : 0;

                if (farm.totalEggEarned() < farm.MAXIMUM_GLOBAL_EGG()) {
                    earnedEgg[counters.counter] =
                        ((block.timestamp - stake.value) *
                            (
                                tokenId <= farm.chickenNoodle().PAID_TOKENS()
                                    ? farm.DAILY_GEN0_EGG_RATE()
                                    : farm.DAILY_GEN1_EGG_RATE()
                            )) /
                        1 days;
                } else if (stake.value > farm.lastClaimTimestamp()) {
                    earnedEgg[counters.counter] = 0; // $EGG production stopped already
                } else {
                    earnedEgg[counters.counter] =
                        ((farm.lastClaimTimestamp() - stake.value) *
                            (
                                tokenId <= farm.chickenNoodle().PAID_TOKENS()
                                    ? farm.DAILY_GEN0_EGG_RATE()
                                    : farm.DAILY_GEN1_EGG_RATE()
                            )) /
                        1 days; // stop earning additional $EGG if it's all been earned
                }

                counters.counter++;
            }
        }
    }

    function getStakedNoodlesForOwner(
        address farmAddress,
        IFarm.PagingData memory data,
        mapping(uint16 => IFarm.Stake) storage henHouse,
        mapping(uint8 => IFarm.Stake[]) storage den,
        mapping(uint16 => uint16) storage denIndices
    )
        public
        view
        returns (
            uint16[] memory tokens,
            uint8[] memory tier,
            uint256[] memory taxedEgg
        )
    {
        IFarm farm = IFarm(farmAddress);

        (, uint16 tokensOwned, , , , , ) = getStakedBalanceOf(
            farmAddress,
            data.tokenOwner,
            henHouse,
            den,
            denIndices
        );

        (uint256 tokensSize, uint256 pageStart) = _paging(
            tokensOwned,
            data.limit,
            data.page
        );

        tokens = new uint16[](tokensSize);
        tier = new uint8[](tokensSize);
        taxedEgg = new uint256[](tokensSize);

        Counters memory counters;

        uint16 supply = uint16(farm.chickenNoodle().totalSupply());

        for (
            uint16 tokenId = 1;
            tokenId <= supply && counters.counter < tokens.length;
            tokenId++
        ) {
            if (farm.chickenNoodle().ownerOf(tokenId) != address(this)) {
                continue;
            }

            if (!farm.isChicken(tokenId)) {
                uint8 tierScore = farm.tierScoreForNoodle(tokenId);

                IFarm.Stake memory stake = den[tierScore][denIndices[tokenId]];

                if (stake.owner == data.tokenOwner) {
                    if (counters.skipCounter < pageStart) {
                        counters.skipCounter++;
                        continue;
                    }

                    tokens[counters.counter] = tokenId;
                    tier[counters.counter] = tierScore - 3;
                    taxedEgg[counters.counter] =
                        (tierScore) *
                        (farm.eggPerTierScore() - stake.value);
                    counters.counter++;
                }
            }
        }
    }

    function _paging(
        uint16 tokensOwned,
        uint16 limit,
        uint16 page
    ) private pure returns (uint256 tokensSize, uint256 pageStart) {
        pageStart = limit * page;
        uint256 pageEnd = limit * (page + 1);
        tokensSize = tokensOwned >= pageEnd
            ? limit
            : (tokensOwned > pageStart ? tokensOwned - pageStart : 0);
    }
}
