// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITimeLockPool {
    struct Deposit {
        uint256 amount;
        uint64 start;
        uint64 end;
    }

    function deposit(
        uint256 _amount,
        uint256 _duration,
        address _receiver
    ) external;

    function getDepositsOf(address _account)
        external
        view
        returns (Deposit[] memory);

    function getDepositsOfLength(address _account)
        external
        view
        returns (uint256);

    function getMaxBonus() external view returns (uint256);

    function getMaxLockDuration() external view returns (uint256);

    function getMultiplier(uint256 _lockDuration)
        external
        view
        returns (uint256);
}
