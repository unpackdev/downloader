// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ILockupV2.sol";
import "./LockupBendV1Storage.sol";
import "./PercentageMath.sol";
import "./ILendPoolAddressesProvider.sol";
import "./ILendPool.sol";
import "./ISnapshotDelegation.sol";
import "./IVeBend.sol";
import "./IFeeDistributor.sol";
import "./IWETH.sol";

contract LockupBendV2 is
    ILockupV2,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    LockupBendV1Storage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using PercentageMath for uint256;

    uint256 public constant ONE_YEAR_SECONDS = 365 * 86400; // 1 years
    uint8 public constant PRECISION = 10;

    //v2 storage
    uint256 public unlockStartTime;
    uint256 public override lockEndTime;
    mapping(address => Locked) public locks;

    modifier onlyAuthed() {
        require(authedBeneficiaries[_msgSender()], "Sender not authed");
        _;
    }

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

    function approve() external onlyOwner {
        bendToken.safeApprove(address(veBend), type(uint256).max);
        require(
            WETH.approve(
                feeDistributor.addressesProvider().getLendPool(),
                type(uint256).max
            ),
            "Approve WETH failed"
        );
    }

    function transferBeneficiary(
        address _oldBeneficiary,
        address _newBeneficiary
    ) external override onlyOwner {
        require(
            _oldBeneficiary != _newBeneficiary,
            "Beneficiary can't be same"
        );
        require(
            _newBeneficiary != address(0),
            "New beneficiary can't be zero address"
        );
        require(
            authedBeneficiaries[_oldBeneficiary],
            "Old beneficiary not authed"
        );

        authedBeneficiaries[_oldBeneficiary] = false;
        authedBeneficiaries[_newBeneficiary] = true;

        if (locks[_oldBeneficiary].amount > 0) {
            _withdraw(_oldBeneficiary);
            Locked memory _oldLocked = locks[_oldBeneficiary];

            Locked memory _newLocked = locks[_newBeneficiary];

            _newLocked.amount += _oldLocked.amount;
            _newLocked.slope += _oldLocked.slope;

            locks[_newBeneficiary] = _newLocked;

            _oldLocked.amount = 0;
            _oldLocked.slope = 0;

            locks[_oldBeneficiary] = _oldLocked;

            emit BeneficiaryTransferred(
                _oldBeneficiary,
                _newBeneficiary,
                block.timestamp
            );
        }
    }

    function createLock(LockParam[] memory _beneficiaries, uint256 _totalAmount)
        external
        override
        onlyOwner
    {
        require(
            unlockStartTime == 0 && lockEndTime == 0,
            "Can't create lock twice"
        );
        require(
            bendToken.balanceOf(address(this)) >= _totalAmount,
            "Bend Insufficient"
        );
        uint256 _now = block.timestamp;
        uint256 _firstDelayTime = ONE_YEAR_SECONDS;
        uint256 _unlockTime = 3 * ONE_YEAR_SECONDS;
        unlockStartTime = _now + _firstDelayTime;
        lockEndTime = unlockStartTime + _unlockTime;
        uint256 checkPercentage = 0;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            LockParam memory _lp = _beneficiaries[i];
            require(
                _lp.percentage <= PercentageMath.PERCENTAGE_FACTOR,
                "percentage should be less than 10000"
            );
            checkPercentage += _lp.percentage;
            uint256 _lockAmount = _totalAmount.percentMul(_lp.percentage);
            _createLock(_lp.beneficiary, _lockAmount, _unlockTime);
            authedBeneficiaries[_lp.beneficiary] = true;
        }

        require(
            checkPercentage == PercentageMath.PERCENTAGE_FACTOR,
            "The sum of percentage should be 10000"
        );
    }

    function _createLock(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime
    ) internal {
        Locked memory _locked = locks[_beneficiary];

        require(_value > 0, "Need non-zero lock value");
        require(_locked.amount == 0, "Can't lock twice");

        _locked.amount = _value;
        _locked.slope = (_locked.amount * 10**PRECISION) / _unlockTime;
        locks[_beneficiary] = _locked;

        emit Lock(msg.sender, _beneficiary, _value, block.timestamp);
    }

    function lockedAmount(address _beneficiary)
        external
        view
        override
        returns (uint256)
    {
        return _lockedAmount(_beneficiary);
    }

    function _lockedAmount(address _beneficiary)
        internal
        view
        returns (uint256)
    {
        Locked memory _locked = locks[_beneficiary];
        if (block.timestamp <= unlockStartTime) {
            return _locked.amount;
        }
        if (block.timestamp >= lockEndTime) {
            return 0;
        }
        return
            (_locked.slope * (lockEndTime - block.timestamp)) / 10**PRECISION;
    }

    function withdrawable(address _beneficiary)
        external
        view
        override
        returns (uint256)
    {
        return locks[_beneficiary].amount - _lockedAmount(_beneficiary);
    }

    function withdraw() external override onlyAuthed {
        _withdraw(msg.sender);
    }

    function _withdraw(address _beneficiary) internal nonReentrant {
        uint256 _value = locks[_beneficiary].amount -
            _lockedAmount(_beneficiary);

        if (_value > 0) {
            locks[_beneficiary].amount -= _value;
            bendToken.safeTransfer(_beneficiary, _value);

            emit Withdrawn(_beneficiary, _value, block.timestamp);
        }
    }

    function withdrawVeLock() external override onlyOwner {
        veBend.withdraw();
    }

    function createVeLock(uint256 _lockedBendAmount, uint256 _unlockTime)
        external
        override
        onlyOwner
    {
        veBend.createLock(_lockedBendAmount, _unlockTime);
    }

    function increaseVeAmount(uint256 _lockedBendAmount)
        external
        override
        onlyOwner
    {
        veBend.increaseAmount(_lockedBendAmount);
    }

    function increaseVeUnlockTime(uint256 _unlockTime)
        external
        override
        onlyOwner
    {
        veBend.increaseUnlockTime(_unlockTime);
    }

    function delegateVote(bytes32 _snapshotId, address _delegatee)
        external
        override
        onlyOwner
    {
        snapshotDelegation.setDelegate(_snapshotId, _delegatee);
    }

    function clearDelegateVote(bytes32 _snapshotId)
        external
        override
        onlyOwner
    {
        snapshotDelegation.clearDelegate(_snapshotId);
    }

    function refundVeRewards() external override nonReentrant {
        uint256 balanceBefore = WETH.balanceOf(address(this));
        feeDistributor.claim(true);
        uint256 balanceDelta = WETH.balanceOf(address(this)) - balanceBefore;
        if (balanceDelta > 0) {
            ILendPool(feeDistributor.addressesProvider().getLendPool()).deposit(
                    address(WETH),
                    balanceDelta,
                    feeDistributor.bendCollector(),
                    0
                );
        }
    }
}
