// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
import "./SafeERC20Upgradeable.sol";
import "./ISnapshotDelegation.sol";
import "./IVeBend.sol";
import "./IFeeDistributor.sol";
import "./IWETH.sol";
import "./ILockup.sol";

contract LockupBendV1Storage {
    IERC20Upgradeable public bendToken;
    IVeBend public veBend;
    IFeeDistributor public feeDistributor;

    ILockup[3] internal lockups; // deprecated
    mapping(address => uint256) internal feeIndexs; // deprecated
    mapping(address => uint256) internal locked; // deprecated

    mapping(address => bool) public authedBeneficiaries;

    uint256 internal feeIndex; // deprecated
    uint256 internal feeIndexlastUpdateTimestamp; // deprecated
    uint256 internal totalLocked; // deprecated

    IWETH public WETH;
    ISnapshotDelegation public snapshotDelegation;
}
