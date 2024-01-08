// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./ISTKBMIToken.sol";

interface IBMIStaking {
    event StakedBMI(uint256 stakedBMI, uint256 mintedStkBMI, address indexed recipient);
    event BMIWithdrawn(uint256 amountBMI, uint256 burnedStkBMI, address indexed recipient);

    event UnusedRewardPoolRevoked(address recipient, uint256 amount);

    struct WithdrawalInfo {
        uint256 coolDownTimeEnd;
        uint256 amountBMIRequested;
    }

    function stakeWithPermit(
        uint256 _amountBMI,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function stakeFor(address _user, uint256 _amountBMI) external;

    function stake(uint256 _amountBMI) external;

    function maturityAt() external view returns (uint256);

    function isBMIRewardUnlocked() external view returns (bool);

    function whenCanWithdrawBMIReward(address _address) external view returns (uint256);

    function unlockTokensToWithdraw(uint256 _amountBMIUnlock) external;

    function withdraw() external;

    /// @notice Getting withdraw information
    /// @return _amountBMIRequested is amount of bmi tokens requested to unlock
    /// @return _amountStkBMI is amount of stkBMI that will burn
    /// @return _unlockPeriod is its timestamp when user can withdraw
    ///         returns 0 if it didn't unlocked yet. User has 48hs to withdraw
    /// @return _availableFor is the end date if withdraw period has already begun
    ///         or 0 if it is expired or didn't start
    function getWithdrawalInfo(address _userAddr)
        external
        view
        returns (
            uint256 _amountBMIRequested,
            uint256 _amountStkBMI,
            uint256 _unlockPeriod,
            uint256 _availableFor
        );

    function addToPool(uint256 _amount) external;

    function stakingReward(uint256 _amount) external view returns (uint256);

    function getStakedBMI(address _address) external view returns (uint256);

    function getAPY() external view returns (uint256);

    function setRewardPerBlock(uint256 _amount) external;

    function revokeUnusedRewardPool() external;
}
