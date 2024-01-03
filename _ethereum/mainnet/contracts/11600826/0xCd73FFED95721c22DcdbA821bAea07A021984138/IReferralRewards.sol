pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IReferralRewards {
    struct DepositInfo {
        address referrer;
        uint256 depth;
        uint256 amount;
        uint256 time;
        uint256 lastUpdatedTime;
    }
    struct ReferralInfo {
        uint256 reward;
        uint256 lastUpdate;
        uint256 depositHead;
        uint256 depositTail;
        uint256[3] amounts;
        mapping(uint256 => DepositInfo) deposits;
    }

    function setBounds(uint256[3] calldata _depositBounds) external;

    function setDepositRate(uint256[3][3] calldata _depositRate) external;

    function setStakingRate(uint256[3][3] calldata _stakingRate) external;

    function assessReferalDepositReward(address _referrer, uint256 _amount)
        external;

    function claimDividends() external;

    function claimAllDividends(address _referral) external;

    function removeDepositReward(address _referrer, uint256 _amount) external;

    function getReferralReward(address _user) external view;

    function getReferral(address _user) external view returns (address);

    function getStakingRateRange(uint256 _referralStake)
        external
        view
        returns (uint256[3] memory _rates);

    function getDepositRate(uint256[] calldata _referralStakes)
        external
        view
        returns (uint256[] memory _rates);

    function getDepositBounds() external view returns (uint256[3] memory);

    function getStakingRates() external view returns (uint256[3][3] memory);

    function getDepositRates() external view returns (uint256[3][3] memory);

    function getReferralAmounts(address _user)
        external
        view
        returns (uint256[3] memory);
}
