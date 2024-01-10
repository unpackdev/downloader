// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ILockup.sol";
import "./LockupBend.sol";
import "./IVeBend.sol";
import "./IFeeDistributor.sol";
import "./IWETH.sol";
import "./ISnapshotDelegation.sol";
import "./console.sol";

contract LockupBendFactory is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event Withdrawn(bool weth, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event FeeIndexUpdated(uint256 _index);
    event UserFeeIndexUpdated(address indexed user, uint256 index);

    uint8 public constant PRECISION = 18;
    uint256 public constant SECONDS_IN_ONE_YEAR = 365 * 86400;

    IERC20Upgradeable public bendToken;
    IVeBend public veBend;
    IFeeDistributor public feeDistributor;

    ILockup[3] public lockups;

    mapping(address => uint256) public feeIndexs;
    mapping(address => uint256) public locked;
    uint256 public feeIndex;
    uint256 public feeIndexlastUpdateTimestamp;
    uint256 public totalLocked;

    IWETH internal WETH;
    ISnapshotDelegation internal snapshotDelegation;

    function initialize(
        address _wethAddr,
        address _bendTokenAddr,
        address _veBendAddr,
        address _feeDistributorAddr,
        address _snapshotDelegationAddr
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        WETH = IWETH(_wethAddr);
        snapshotDelegation = ISnapshotDelegation(_snapshotDelegationAddr);
        bendToken = IERC20Upgradeable(_bendTokenAddr);
        veBend = IVeBend(_veBendAddr);
        feeDistributor = IFeeDistributor(_feeDistributorAddr);
    }

    // internal functions

    function _getFeeIndex() internal view returns (uint256) {
        if (feeIndexlastUpdateTimestamp == block.timestamp) {
            return feeIndex;
        }
        uint256 _claimable = 0;
        for (uint256 i = 0; i < lockups.length; i++) {
            ILockup _lockup = lockups[i];
            _claimable += feeDistributor.claimable(address(_lockup));
        }
        return _getFeeIndex(_claimable);
    }

    function _getFeeIndex(uint256 feeDistributed)
        internal
        view
        returns (uint256)
    {
        if (feeIndexlastUpdateTimestamp == block.timestamp) {
            return feeIndex;
        }
        return
            (feeDistributed * (10**uint256(PRECISION))) /
            totalLocked +
            feeIndex;
    }

    function _updateFeeIndex(uint256 feeDistributed)
        internal
        returns (uint256)
    {
        if (block.timestamp == feeIndexlastUpdateTimestamp) {
            return feeIndex;
        }
        uint256 _newIndex = _getFeeIndex(feeDistributed);
        if (_newIndex != feeIndex) {
            feeIndex = _newIndex;
            emit FeeIndexUpdated(_newIndex);
        }

        feeIndexlastUpdateTimestamp = block.timestamp;

        return _newIndex;
    }

    function _updateUserFeeIndex(address _addr, uint256 feeDistributed)
        internal
        returns (uint256)
    {
        uint256 _userIndex = feeIndexs[_addr];
        uint256 _newIndex = _updateFeeIndex(feeDistributed);
        uint256 _accruedRewards = 0;
        if (_userIndex != _newIndex) {
            _accruedRewards = _getRewards(_addr, _userIndex, _newIndex);
            feeIndexs[_addr] = _newIndex;
            emit UserFeeIndexUpdated(_addr, _newIndex);
        }
        return _accruedRewards;
    }

    function _getRewards(
        address _addr,
        uint256 _userFeeIndex,
        uint256 _feeIndex
    ) internal view returns (uint256) {
        uint256 _userTotalLocked = locked[_addr];
        return
            (_userTotalLocked * (_feeIndex - _userFeeIndex)) /
            10**uint256(PRECISION);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
    }

    // external functions

    function delegateSnapshotVotePower(
        uint256 _index,
        bytes32 _id,
        address _delegatee
    ) external onlyOwner {
        require(_index < lockups.length, "Index over range");
        ILockup _lockup = lockups[_index];
        _lockup.delegateSnapshotVotePower(_id, _delegatee);
    }

    function transferBeneficiary(
        address _oldBeneficiary,
        address _newBeneficiary
    ) external onlyOwner {
        for (uint256 i = 0; i < lockups.length; i++) {
            ILockup _lockup = lockups[i];
            _lockup.transferBeneficiary(_oldBeneficiary, _newBeneficiary);
        }
    }

    function createLock(
        ILockup.LockParam[] memory _beneficiaries,
        uint256 _totalLockAmount
    ) external onlyOwner {
        uint256 _bendBalance = bendToken.balanceOf(address(this));
        require(
            _bendBalance >= _totalLockAmount,
            "Insufficient Bend for locking"
        );
        require(totalLocked == 0, "Can't create lock twice");

        uint256 checkThousandths = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            checkThousandths += _beneficiaries[i].thousandths;
        }

        require(
            checkThousandths == 1000,
            "The sum of thousands should be 1000"
        );

        totalLocked = _totalLockAmount;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            ILockup.LockParam memory _lock = _beneficiaries[i];
            locked[_lock.beneficiary] =
                (totalLocked * _lock.thousandths) /
                1000;
        }

        uint256 _lockups = lockups.length;

        uint256 _lockAvgAmount = totalLocked / _lockups;
        uint256 _unlockStartTime = block.timestamp;

        for (uint256 i = 0; i < _lockups; i++) {
            LockupBend _lockupBendContract = new LockupBend(
                address(WETH),
                address(bendToken),
                address(veBend),
                address(feeDistributor),
                address(snapshotDelegation)
            );
            lockups[i] = _lockupBendContract;
            bendToken.safeApprove(
                address(_lockupBendContract),
                type(uint256).max
            );
        }

        for (uint256 i = 0; i < _lockups - 1; i++) {
            _unlockStartTime += SECONDS_IN_ONE_YEAR;
            lockups[i].createLock(
                _beneficiaries,
                _lockAvgAmount,
                _unlockStartTime
            );
        }
        _unlockStartTime += SECONDS_IN_ONE_YEAR;
        uint256 _remainingAmount = _totalLockAmount -
            (_lockAvgAmount * (_lockups - 1));
        lockups[_lockups - 1].createLock(
            _beneficiaries,
            _remainingAmount,
            _unlockStartTime
        );
    }

    function claimable(address _addr) external view returns (uint256) {
        uint256 _userFeeIndex = feeIndexs[_addr];
        uint256 _feeIndex = _getFeeIndex();
        return _getRewards(_addr, _userFeeIndex, _feeIndex);
    }

    function claim(bool weth) external nonReentrant {
        uint256 balanceBefore = WETH.balanceOf(address(this));
        for (uint256 i = 0; i < lockups.length; i++) {
            ILockup _lockup = lockups[i];
            _lockup.claim();
        }
        uint256 balanceDelta = WETH.balanceOf(address(this)) - balanceBefore;
        uint256 _accruedRewards = _updateUserFeeIndex(msg.sender, balanceDelta);
        if (_accruedRewards > 0) {
            if (weth) {
                require(
                    WETH.transfer(msg.sender, _accruedRewards),
                    "WETH_TRANSFER_FAILED"
                );
            } else {
                WETH.withdraw(_accruedRewards);
                _safeTransferETH(msg.sender, _accruedRewards);
            }
            emit Claimed(msg.sender, _accruedRewards);
        }
    }

    function withdrawable(address _addr) external view returns (uint256) {
        uint256 _withdrawAmount = 0;
        for (uint256 i = 0; i < lockups.length; i++) {
            ILockup _lockup = lockups[i];
            _withdrawAmount += _lockup.withdrawable(_addr);
        }
        return _withdrawAmount;
    }

    function withdraw() external {
        for (uint256 i = 0; i < lockups.length; i++) {
            ILockup _lockup = lockups[i];
            _lockup.withdraw(msg.sender);
        }
    }

    function withdrawResidue() external onlyOwner {
        uint256 wethToWithdraw = WETH.balanceOf(address(this));
        if (wethToWithdraw > 0) {
            require(
                WETH.transfer(msg.sender, wethToWithdraw),
                "WETH_TRANSFER_FAILED"
            );
            emit Withdrawn(true, wethToWithdraw);
        }
        uint256 ethToWithdraw = address(this).balance;
        if (ethToWithdraw > 0) {
            _safeTransferETH(msg.sender, ethToWithdraw);
            emit Withdrawn(false, ethToWithdraw);
        }
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), "Receive not allowed");
    }
}
