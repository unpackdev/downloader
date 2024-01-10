// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface EventCenterLeveragePositionInterface {
    // function emitCreateAccountEvent(address EOA, address account) external;

    function epochRound() external view returns (uint256);

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external;

    function emitOpenLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitCloseLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitOpenShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitCloseShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    ) external;

    function emitAddMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external;

    function emitRemoveMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external;

    function startEpoch(uint256 _rewardAmount) external;

    function isInRewardEpoch() external view returns (bool);

    function emitWithDrawEvent(address token, uint256 amount) external;

    function emitRepayEvent(address token, uint256 amount) external;

    function emitReleasePositionRewardEvent(
        address owner,
        uint256 epochRound,
        bytes32 merkelRoot
    ) external;

    function emitClaimPositionRewardEvent(
        address EOA,
        uint256 epochRound,
        uint256 amount
    ) external;

    function emitClaimOpenAccountRewardEvent(
        address EOA,
        address account,
        uint256 amount
    ) external;
}
