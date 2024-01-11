// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILockupV2 {
    struct LockParam {
        address beneficiary;
        uint256 percentage;
    }

    struct Locked {
        uint256 amount;
        uint256 slope;
    }

    event Lock(
        address indexed provider,
        address indexed beneficiary,
        uint256 value,
        uint256 ts
    );

    event BeneficiaryTransferred(
        address indexed previousBeneficiary,
        address indexed newBeneficiary,
        uint256 ts
    );

    event Withdrawn(address indexed beneficiary, uint256 value, uint256 ts);

    function lockEndTime() external view returns (uint256);

    function transferBeneficiary(
        address _oldBeneficiary,
        address _newBeneficiary
    ) external;

    function createLock(LockParam[] memory _beneficiaries, uint256 _totalAmount)
        external;

    function withdrawable(address _beneficiary) external view returns (uint256);

    function withdraw() external;

    function lockedAmount(address _beneficiary) external view returns (uint256);

    function createVeLock(uint256 _lockedBendAmount, uint256 _unlockTime)
        external;

    function increaseVeAmount(uint256 _lockedBendAmount) external;

    function increaseVeUnlockTime(uint256 _unlockTime) external;

    function withdrawVeLock() external;

    function delegateVote(bytes32 _snapshotId, address _delegatee) external;

    function clearDelegateVote(bytes32 _snapshotId) external;

    function refundVeRewards() external;
}
