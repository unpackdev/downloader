// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract AtlasNaviVesting is Initializable, OwnableUpgradeable {
    struct Vesting {
        uint256 initialTokenAmount;
        uint256 lastClaimTimestamp;
        uint256 vestingCategory;
    }

    struct AddBulkStruct {
        address accountAddress;
        Vesting[] vestings;
    }

    enum VestingCategory {
        Seed,
        Strategic,
        PrivateSale,
        Partner,
        PublicSale,
        Team,
        Marketing,
        Rewards,
        Development,
        Liquidity,
        Advisors
    }

    address public atlasNaviToken;
    mapping(address => Vesting[]) public mappingAddressVesting;
    uint256 public tgeTimestamp;

    event InvestorAdded(
        address account,
        uint256 vestingCategory,
        uint256 amount
    );

    event TokensClaimed(address account, uint256 amount, uint256 timestamp);

    function initialize(address atlasNaviTokenAddress) public initializer {
        __Ownable_init();
        atlasNaviToken = atlasNaviTokenAddress;
         tgeTimestamp = 1669723200; //29-11-2022: 12:00:00 UTC;
//        tgeTimestamp = 1668168000; // 11-11-12:00 UTC
    }

    function deposit(uint256 amount) public onlyOwner {
        IERC20(atlasNaviToken).transferFrom(msg.sender, address(this), amount);
    }

    function setTGE(uint256 timestamp) public onlyOwner {
        tgeTimestamp = timestamp;
    }

    function addInvestor(
        address accountAddress,
        uint256 vestingCategory,
        uint256 amount
    ) public onlyOwner {
        Vesting memory vestingObj;
        vestingObj.vestingCategory = vestingCategory;
        vestingObj.initialTokenAmount = amount;

        mappingAddressVesting[accountAddress].push(vestingObj);
        emit InvestorAdded(accountAddress, vestingCategory, amount);
    }

    function addInvestorsBulk(AddBulkStruct[] memory objects) public onlyOwner {
        for (uint256 i = 0; i < objects.length; i++) {
            address accountAddress = objects[i].accountAddress;
            Vesting[] memory vestingsForThisAddress = objects[i].vestings;
            for (uint256 j = 0; j < vestingsForThisAddress.length; j++) {
                addInvestor(
                    accountAddress,
                    vestingsForThisAddress[j].vestingCategory,
                    vestingsForThisAddress[j].initialTokenAmount
                );
            }
        }
    }

    function getVestingObject(address accountAddress, uint256 index)
    public
    view
    returns (Vesting memory)
    {
        return mappingAddressVesting[accountAddress][index];
    }

    function getTokensAvailableToClaim(address accountAddress, uint256 index)
    public
    view
    returns (uint256)
    {
        if (tgeTimestamp > block.timestamp) {
            return 0;
        }
        Vesting memory vestingObj = mappingAddressVesting[accountAddress][
        index
        ];
        uint256 availableTokens;
        uint256 daysFromTGE = (block.timestamp - tgeTimestamp) / 60 / 60 / 24;
        uint256 daysFromLastClaim = (block.timestamp -
        vestingObj.lastClaimTimestamp) /
        60 /
        60 /
        24;

        if (vestingObj.vestingCategory == uint256(VestingCategory.Seed)) {
            availableTokens = availableTokensSeed(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Strategic)
        ) {
            availableTokens = availableTokensStrategic(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.PrivateSale)
        ) {
            availableTokens = availableTokensPrivateSale(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            (vestingObj.vestingCategory == uint256(VestingCategory.Partner)) ||
            (vestingObj.vestingCategory == uint256(VestingCategory.PublicSale))
        ) {
            availableTokens = availableTokensPartnerOrPublicSale(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Team)
        ) {
            availableTokens = availableTokensTeam(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Marketing)
        ) {
            availableTokens = availableTokensMarketing(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Rewards)
        ) {
            availableTokens = availableTokensRewards(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Development)
        ) {
            availableTokens = availableTokensDevelopment(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Liquidity)
        ) {
            availableTokens = availableTokensLiquidity(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        } else if (
            vestingObj.vestingCategory == uint256(VestingCategory.Advisors)
        ) {
            availableTokens = availableTokensAdvisors(
                vestingObj,
                daysFromTGE,
                daysFromLastClaim
            );
        }

        return availableTokens;
    }

    function claim(uint256 index) public {
        require(block.timestamp > tgeTimestamp, 'Vesting has not started');
        uint256 noOfTokensToClaim = getTokensAvailableToClaim(
            msg.sender,
            index
        );
        require(noOfTokensToClaim > 0, "There are no available tokens");

        IERC20(atlasNaviToken).transfer(msg.sender, noOfTokensToClaim);

        mappingAddressVesting[msg.sender][index].lastClaimTimestamp = block
        .timestamp;

        emit TokensClaimed(msg.sender, noOfTokensToClaim, block.timestamp);
    }

    function availableTokensSeed(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysWith5;
        uint256 nrOfdaysWith7;
        //never claimed
        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 5%
            response = (vestingObj.initialTokenAmount * 5) / 100;
        }

        if (daysFromTGE >= 90) {
            //5%/day;
            if (daysFromTGE < 120) {
                nrOfDaysWith5 = daysFromTGE - 90;
            } else {
                nrOfDaysWith5 = 30;
            }
            //nr of days with 5 = 20
            //days from last claim = 18
            if (nrOfDaysWith5 > daysFromLastClaim) {
                //it means that users already claimed some days in this interval
                nrOfDaysWith5 = daysFromLastClaim;
            }
        }

        if (daysFromTGE >= 360) {
            //7.5% per day
            if (daysFromTGE < 720) {
                nrOfdaysWith7 = daysFromTGE - 360;
            } else {
                nrOfdaysWith7 = 360;
            }

            if (nrOfdaysWith7 > daysFromLastClaim) {
                //it means that users already claimed some days in this interval
                nrOfdaysWith7 = daysFromLastClaim;
            }
        }

        response +=
        (vestingObj.initialTokenAmount * 5 * nrOfDaysWith5) /
        100 /
        30;

        response +=
        ((vestingObj.initialTokenAmount * 75) * nrOfdaysWith7) /
        1000 /
        30;
        return response;
    }

    function availableTokensStrategic(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDays;
        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 4.96%
            response = (vestingObj.initialTokenAmount * 496) / 10000;
        }

        if (daysFromTGE >= 360) {
            if (daysFromTGE < 720) {
                nrOfDays = daysFromTGE - 360;
            } else {
                nrOfDays = 360;
            }
            if (nrOfDays > daysFromLastClaim) {
                nrOfDays = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 792 * nrOfDays) /
        10000 /
        30;
        return response;
    }

    function availableTokensPrivateSale(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysWith6;
        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 10%
            response = (vestingObj.initialTokenAmount * 10) / 100;
        }

        if (daysFromTGE >= 90) {
            if (daysFromTGE < 540) {
                nrOfDaysWith6 = daysFromTGE - 90;
            } else {
                nrOfDaysWith6 = 450;
            }

            if (nrOfDaysWith6 > daysFromLastClaim) {
                nrOfDaysWith6 = daysFromLastClaim;
            }
        }

        response +=
        (vestingObj.initialTokenAmount * 6 * nrOfDaysWith6) /
        100 /
        30;
        return response;
    }

    function availableTokensPartnerOrPublicSale(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysPartner;
        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 20%
            response = (vestingObj.initialTokenAmount * 20) / 100;
        }

        if (daysFromTGE >= 90) {
            if (daysFromTGE < 360) {
                nrOfDaysPartner = daysFromTGE - 90;
            } else {
                nrOfDaysPartner = 270;
            }
            if (nrOfDaysPartner > daysFromLastClaim) {
                nrOfDaysPartner = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 889 * nrOfDaysPartner) /
        10000 /
        30;
        return response;
    }

    function availableTokensTeam(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysTeam;
        if (daysFromTGE >= 360) {
            if (daysFromTGE < 1080) {
                nrOfDaysTeam = daysFromTGE - 360;
            } else {
                nrOfDaysTeam = 720;
            }
            if (nrOfDaysTeam > daysFromLastClaim) {
                nrOfDaysTeam = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 417 * nrOfDaysTeam) /
        10000 /
        30;
        return response;
    }

    function availableTokensMarketing(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysMarketing1;
        uint256 secondRoundWith1Marketing;
        uint256 nrOfDaysMarketing3;

        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 1.50%
            response = (vestingObj.initialTokenAmount * 150) / 10000;
        }

        if (daysFromTGE >= 30) {
            if (daysFromTGE < 60) {
                nrOfDaysMarketing1 = daysFromTGE - 30;
            } else {
                nrOfDaysMarketing1 = 30;
            }
            if (nrOfDaysMarketing1 > daysFromLastClaim) {
                nrOfDaysMarketing1 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 1 * nrOfDaysMarketing1) /
        100 /
        30;

        if (daysFromTGE >= 90) {
            //we add here the second round with 1 %
            if (daysFromTGE < 360) {
                secondRoundWith1Marketing = daysFromTGE - 90;
            } else {
                secondRoundWith1Marketing = 270;
            }
            if (secondRoundWith1Marketing > daysFromLastClaim) {
                secondRoundWith1Marketing = daysFromLastClaim;
            }
        }

        response +=
        (vestingObj.initialTokenAmount * 1 * secondRoundWith1Marketing) /
        100 /
        30;

        if (daysFromTGE >= 360) {
            if (daysFromTGE < 1080) {
                nrOfDaysMarketing3 = daysFromTGE - 360;
            } else {
                nrOfDaysMarketing3 = 720;
            }
            if (nrOfDaysMarketing3 > daysFromLastClaim) {
                nrOfDaysMarketing3 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 369 * nrOfDaysMarketing3) /
        10000 /
        30;
        return response;
    }

    function availableTokensRewards(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysRewardsWith15;
        uint256 secondRoundWith15Rewards;
        uint256 nrOfDaysRewardsWith216;

        if (daysFromTGE >= 7) {
            if (daysFromTGE < 14) {
                nrOfDaysRewardsWith15 = daysFromTGE - 7;
            } else {
                nrOfDaysRewardsWith15 = 7;
            }
            if (nrOfDaysRewardsWith15 > daysFromLastClaim) {
                nrOfDaysRewardsWith15 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 150 * nrOfDaysRewardsWith15) /
        10000 /
        7;

        if (daysFromTGE >= 30) {
            //we add here the second round with 1.5 %
            if (daysFromTGE < 360) {
                secondRoundWith15Rewards = daysFromTGE - 30;
            } else {
                secondRoundWith15Rewards = 330;
            }
            if (secondRoundWith15Rewards > daysFromLastClaim) {
                secondRoundWith15Rewards = daysFromLastClaim;
            }
        }

        response +=
        (vestingObj.initialTokenAmount * 150 * secondRoundWith15Rewards) /
        10000 /
        30;

        if (daysFromTGE >= 360) {
            if (daysFromTGE < 1500) {
                nrOfDaysRewardsWith216 = daysFromTGE - 360;
            } else {
                nrOfDaysRewardsWith216 = 1140;
            }
            if (nrOfDaysRewardsWith216 > daysFromLastClaim) {
                nrOfDaysRewardsWith216 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 216 * nrOfDaysRewardsWith216) /
        10000 /
        30;

        return response;
    }

    function availableTokensDevelopment(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysDevelopmentWith1;
        uint256 secondRoundWith1Development;
        uint256 nrOfDaysRewardsWith367;

        if (daysFromTGE >= 7) {
            if (daysFromTGE < 14) {
                nrOfDaysDevelopmentWith1 = daysFromTGE - 7;
            } else {
                nrOfDaysDevelopmentWith1 = 7;
            }
            if (nrOfDaysDevelopmentWith1 > daysFromLastClaim) {
                nrOfDaysDevelopmentWith1 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 1 * nrOfDaysDevelopmentWith1) /
        100 /
        7;

        if (daysFromTGE >= 30) {
            //we add here the second round with 1 %
            if (daysFromTGE < 360) {
                secondRoundWith1Development = daysFromTGE - 30;
            } else {
                secondRoundWith1Development = 330;
            }
            if (secondRoundWith1Development > daysFromLastClaim) {
                secondRoundWith1Development = daysFromLastClaim;
            }
        }

        response +=
        (vestingObj.initialTokenAmount * 1 * secondRoundWith1Development) /
        100 /
        30;

        if (daysFromTGE >= 360) {
            if (daysFromTGE < 1080) {
                nrOfDaysRewardsWith367 = daysFromTGE - 360;
            } else {
                nrOfDaysRewardsWith367 = 720;
            }
            if (nrOfDaysRewardsWith367 > daysFromLastClaim) {
                nrOfDaysRewardsWith367 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 367 * nrOfDaysRewardsWith367) /
        10000 /
        30;

        return response;
    }

    function availableTokensLiquidity(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysWith5Liquidity;
        uint256 secondRoundWith5Liquidity;
        uint256 thirdRoundWith5Liquidity;
        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 15%
            response = (vestingObj.initialTokenAmount * 15) / 100;
        }

        if (daysFromTGE >= 90) {
            if (daysFromTGE < 120) {
                nrOfDaysWith5Liquidity = daysFromTGE - 90;
            } else {
                nrOfDaysWith5Liquidity = 30;
            }
            if (nrOfDaysWith5Liquidity > daysFromLastClaim) {
                nrOfDaysWith5Liquidity = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 5 * nrOfDaysWith5Liquidity) /
        100 /
        30;

        if (daysFromTGE >= 180) {
            if (daysFromTGE < 210) {
                secondRoundWith5Liquidity = daysFromTGE - 180;
            } else {
                secondRoundWith5Liquidity = 30;
            }
            if (secondRoundWith5Liquidity > daysFromLastClaim) {
                secondRoundWith5Liquidity = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 5 * secondRoundWith5Liquidity) /
        100 /
        30;

        if (daysFromTGE >= 360) {
            if (daysFromTGE < 810) {
                thirdRoundWith5Liquidity = daysFromTGE - 360;
            } else {
                thirdRoundWith5Liquidity = 450;
            }
            if (thirdRoundWith5Liquidity > daysFromLastClaim) {
                thirdRoundWith5Liquidity = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 5 * thirdRoundWith5Liquidity) /
        100 /
        30;
        return response;
    }

    function availableTokensAdvisors(
        Vesting memory vestingObj,
        uint256 daysFromTGE,
        uint256 daysFromLastClaim
    ) private view returns (uint256) {
        uint256 response;
        uint256 nrOfDaysWith452;
        if (
            block.timestamp >= tgeTimestamp &&
            vestingObj.lastClaimTimestamp == 0
        ) {
            //the instant 5%
            response = (vestingObj.initialTokenAmount * 5) / 100;
        }

        if (daysFromTGE >= 90) {
            if (daysFromTGE < 720) {
                nrOfDaysWith452 = daysFromTGE - 90;
            } else {
                nrOfDaysWith452 = 630;
            }
            if (nrOfDaysWith452 > daysFromLastClaim) {
                nrOfDaysWith452 = daysFromLastClaim;
            }
        }
        response +=
        (vestingObj.initialTokenAmount * 452 * nrOfDaysWith452) /
        10000 /
        30;
        return response;
    }

}
