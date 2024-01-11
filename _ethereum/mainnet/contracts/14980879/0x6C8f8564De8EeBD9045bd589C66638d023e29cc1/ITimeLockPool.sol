// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITimeLockPool {
    
    struct DepositChange {
        uint256 date; 
        uint256 previousLastAdminWithdrawalIndex;
        uint256 previousLastTotalBeforeLessPerToken;
    }
    
    struct Deposit {
        bytes32 kek_id;
        uint256 amount;
        uint256 multiplier;
        uint64 start;
        uint64 end;
        uint256 accUserWithdrawal;
        DepositChange[] changes;
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
