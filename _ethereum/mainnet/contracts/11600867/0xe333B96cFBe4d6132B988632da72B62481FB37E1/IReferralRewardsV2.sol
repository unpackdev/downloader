pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IReferralRewardsV2 {
    struct ReferralInfo {
        uint256 totalDeposit;
        uint256 reward;
        uint256 lastUpdate;
        uint256[3] amounts;
    }

    function setBounds(uint256[3] calldata _depositBounds) external;

    function setDepositRate(uint256[3][3] calldata _depositRate) external;

    function setStakingRate(uint256[3][3] calldata _stakingRate) external;

    function setReferral(address _referrer, address _referral) external;

    function assessReferalDepositReward(address _referrer, uint256 _amount)
        external;

    function transferOwnership(address newOwner) external;

    function claimDividends() external;

    function claimAllDividends(address _referral) external;

    function proccessDeposit(
        address _referrer,
        address _referral,
        uint256 _amount
    ) external;

    function handleDepositEnd(address _referrer, uint256 _amount) external;

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
