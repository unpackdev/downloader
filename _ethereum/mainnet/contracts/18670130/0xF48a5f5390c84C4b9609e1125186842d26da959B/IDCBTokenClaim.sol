// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/* solhint-disable */

interface IDCBTokenClaim {
    struct Params {
        uint8 minTier;
        uint16 nativeChainId;
        uint32 startDate;
        uint32 endDate;
        address rewardTokenAddr;
        address vestingAddr;
        address tierMigratorAddr;
        address layerZeroAddr;
        bytes32 answerHash;
        uint256 distAmount;
        Tiers[] tiers;
    }

    struct Tiers {
        uint256 minLimit;
        uint16 multi;
    }

    struct UserAllocation {
        uint8 active; //Is active or not
        uint8 registeredTier; //Tier of user while registering
        uint8 multi; //Multiplier of user while registering
        uint256 shares; //Shares owned by user
        uint256 claimedAmount; //Claimed amount from event
    }

    struct ClaimInfo {
        uint8 minTier; //Minimum tier required for users while registering
        uint32 createDate; //Created date
        uint32 startDate; //Event start date
        uint32 endDate; //Event end date
        uint256 distAmount; //Total distributed amount
    }

    function ANSWER_HASH() external view returns (bytes32);

    function claimInfo()
        external
        view
        returns (uint8 minTier, uint32 createDate, uint32 startDate, uint32 endDate, uint256 distAmount);

    function claimTokens() external returns (bool);

    function getClaimForTier(uint8 _tier, uint8 _multi) external view returns (uint256);

    function getClaimableAmount(address _address) external view returns (uint256);

    function getParticipants() external view returns (address[] memory);

    function getRegisteredUsers() external view returns (address[] memory);

    function getTier(address _user) external view returns (uint256 _tier, uint16 _holdMulti);

    function initialize(Params memory p) external;

    function setMinTierForClaim(uint8 _minTier) external;

    function setParams(Params calldata p) external;

    function setToken(address _token) external;

    function registerForAllocation(address _user, uint8 _tier, uint8 _multi) external returns (bool);

    function registerByManager(
        address[] calldata _users,
        uint256[] calldata _tierOfUser,
        uint256[] calldata _multiOfUser
    )
        external;

    function tierInfo(uint256) external view returns (uint256 minLimit, uint16 multi);

    function totalShares() external view returns (uint256);

    function userAllocation(address)
        external
        view
        returns (uint8 active, uint8 registeredTier, uint8 multi, uint256 shares, uint256 claimedAmount);
}
