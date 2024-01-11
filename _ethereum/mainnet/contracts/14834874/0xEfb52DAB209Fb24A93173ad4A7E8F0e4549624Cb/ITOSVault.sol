//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ITOSVault {

    ///@dev initialization function
    ///@param _totalAllocatedAmount total allocated amount           
    ///@param _claimCounts total claim Counts
    ///@param _claimTimes each claimTime
    ///@param _claimAmounts each claimAmount
    function initialize(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts
    ) external;

    ///@dev ProxyOwner can change when requested by the project team
    ///@param _totalAllocatedAmount total allocated amount           
    ///@param _claimCounts total claim Counts
    ///@param _claimTimes each claimTime
    ///@param _claimAmounts each claimAmount
    function ownerSetting(
        uint256 _totalAllocatedAmount,
        uint256 _claimCounts,
        uint256[] calldata _claimTimes,
        uint256[] calldata _claimAmounts
    ) external;

    ///@dev ProxyOwner can change when requested by the project team or change the dividendPool
    ///@param _token manage token Address           
    ///@param _dividedPool dividendPool Address
    function changeAddr(
        address _token,
        address _dividedPool
    ) external;

    ///@dev Used to indicate the current round
    ///@param round the current round
    function currentRound() external view returns (uint256 round);

    ///@dev Reports the claimAmount for the round
    ///@param _round round
    ///@param amount amount
    function calculClaimAmount(uint256 _round) external view returns (uint256 amount);

    ///@dev When you claim, the amount corresponding to the round goes to the vault
    function claim()
        external;
}