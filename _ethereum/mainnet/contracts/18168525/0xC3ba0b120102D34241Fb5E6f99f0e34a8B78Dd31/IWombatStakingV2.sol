// SPDX-License-Identifier: MIT

import "./ERC20.sol";

pragma solidity ^0.8.0;

interface IWombatStaking {
    function convertWOM(uint256 amount) external returns (uint256);

    function masterWombat() external view returns (address);

    function deposit(
        address _lpToken,
        uint256 _amount,
        uint256 _minAmount,
        address _for,
        address _from
    ) external returns(uint256);

    function depositLP(address _lpToken, uint256 _lpAmount, address _for) external;

    function withdraw(
        address _lpToken,
        uint256 _amount,
        uint256 _minAmount,
        address _sender
    ) external;

    function withdrawLP(address _lpToken, uint256 _lpAmount, address _sender) external;

    function getPoolLp(address _lpToken) external view returns (address);

    function harvest(address _lpToken) external;

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[][] memory rewardTokens, uint256[][] memory feeAmounts);

    function voter() external view returns (address);

    function pendingBribeCallerFee(
        address[] calldata pendingPools
    )
        external
        view
        returns (IERC20[][] memory rewardTokens, uint256[][] memory callerFeeAmount);
}