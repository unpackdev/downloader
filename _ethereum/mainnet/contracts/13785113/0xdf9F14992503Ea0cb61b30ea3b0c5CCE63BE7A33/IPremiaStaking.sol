// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./PremiaStakingStorage.sol";

interface IPremiaStaking {
    event Deposit(address indexed user, uint256 amount);
    event StartWithdrawal(
        address indexed user,
        uint256 premiaAmount,
        uint256 startDate
    );
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @notice stake PREMIA using IERC2612 permit
     * @param amount quantity of PREMIA to stake
     * @param deadline timestamp after which permit will fail
     * @param v signature "v" value
     * @param r signature "r" value
     * @param s signature "s" value
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice stake PREMIA in exchange for xPremia
     * @param amount quantity of PREMIA to stake
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Initiate the withdrawal process by burning xPremia, starting the delay period
     * @param amount quantity of xPremia to unstake
     */
    function startWithdraw(uint256 amount) external;

    /**
     * @notice withdraw PREMIA after withdrawal delay has passed
     */
    function withdraw() external;

    /**
     * @notice get current withdrawal delay
     * @return withdrawal delay
     */
    function getWithdrawalDelay() external view returns (uint256);

    /**
     * @notice set current withdrawal delay
     * @param delay withdrawal delay
     */
    function setWithdrawalDelay(uint256 delay) external;

    /**
     * @notice get the xPREMIA : PREMIA ratio (with 18 decimals)
     * @return xPREMIA : PREMIA ratio (with 18 decimals)
     */
    function getXPremiaToPremiaRatio() external view returns (uint256);

    /**
     * @notice get pending withdrawal data of a user
     * @return amount pending withdrawal amount
     * @return startDate start timestamp of withdrawal
     * @return unlockDate timestamp at which withdrawal becomes available
     */
    function getPendingWithdrawal(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 startDate,
            uint256 unlockDate
        );

    /**
     * @notice get the amount of PREMIA staked (subtracting all pending withdrawals)
     * @return amount of PREMIA staked
     */
    function getStakedPremiaAmount() external view returns (uint256);
}
