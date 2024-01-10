// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ILockup.sol";
import "./IVeBend.sol";
import "./IFeeDistributor.sol";
import "./IWETH.sol";
import "./ISnapshotDelegation.sol";

contract LockupBend is ILockup, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant UNLOCK_MAXTIME = 365 * 86400; // 1 years
    uint8 public constant PRECISION = 10;
    IERC20 public bendToken;
    IVeBend public veBend;
    IFeeDistributor public feeDistributor;
    IWETH internal WETH;
    ISnapshotDelegation internal snapshotDelegation;

    mapping(address => Locked) public locked;
    uint256 public unlockStartTime;
    uint256 public override lockEndTime;

    constructor(
        address _wethAddr,
        address _bendTokenAddr,
        address _veBendAddr,
        address _feeDistributorAddr,
        address _snapshotDelegationAddr
    ) {
        WETH = IWETH(_wethAddr);
        bendToken = IERC20(_bendTokenAddr);
        veBend = IVeBend(_veBendAddr);
        feeDistributor = IFeeDistributor(_feeDistributorAddr);
        bendToken.safeApprove(_veBendAddr, type(uint256).max);
        snapshotDelegation = ISnapshotDelegation(_snapshotDelegationAddr);
    }

    function delegateSnapshotVotePower(bytes32 _id, address _delegatee)
        external
        override
        onlyOwner
    {
        snapshotDelegation.setDelegate(_id, _delegatee);
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

        if (locked[_oldBeneficiary].amount > 0) {
            _withdraw(_oldBeneficiary);
            Locked memory _oldLocked = locked[_oldBeneficiary];

            Locked memory _newLocked = locked[_newBeneficiary];

            _newLocked.amount += _oldLocked.amount;
            _newLocked.slope += _oldLocked.slope;

            locked[_newBeneficiary] = _newLocked;

            _oldLocked.amount = 0;
            _oldLocked.slope = 0;

            locked[_oldBeneficiary] = _oldLocked;

            emit BeneficiaryTransferred(
                _oldBeneficiary,
                _newBeneficiary,
                block.timestamp
            );
        }
    }

    function createLock(
        LockParam[] memory _beneficiaries,
        uint256 _totalAmount,
        uint256 _unlockStartTime
    ) external override onlyOwner {
        require(
            unlockStartTime == 0 && lockEndTime == 0,
            "Can't create lock twice"
        );
        unlockStartTime = _unlockStartTime;
        require(unlockStartTime >= block.timestamp, "Can't unlock from past");
        lockEndTime = unlockStartTime + UNLOCK_MAXTIME;
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            LockParam memory _lp = _beneficiaries[i];
            require(
                _lp.thousandths <= 1000,
                "Thousandths should be less than 1000"
            );
            uint256 _lockAmount = (_lp.thousandths * _totalAmount) / 1000;
            _createLock(_lp.beneficiary, _lockAmount);
        }

        bendToken.safeTransferFrom(msg.sender, address(this), _totalAmount);

        // Should withdraw from vebend before linear unlocking
        veBend.createLock(_totalAmount, _unlockStartTime);
    }

    function _createLock(address _beneficiary, uint256 _value) internal {
        Locked memory _locked = locked[_beneficiary];

        require(_value > 0, "Need non-zero lock value");
        require(_locked.amount == 0, "Can't lock twice");

        _locked.amount = _value;
        _locked.slope = (_locked.amount * 10**PRECISION) / UNLOCK_MAXTIME;
        locked[_beneficiary] = _locked;

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
        Locked memory _locked = locked[_beneficiary];
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
        return locked[_beneficiary].amount - _lockedAmount(_beneficiary);
    }

    function withdraw(address _beneficiary) external override onlyOwner {
        _withdraw(_beneficiary);
    }

    function _withdraw(address _beneficiary) internal nonReentrant {
        uint256 _value = locked[_beneficiary].amount -
            _lockedAmount(_beneficiary);

        if (_value > 0) {
            uint256 _bendBalance = bendToken.balanceOf(address(this));
            if (_bendBalance < _value && block.timestamp > unlockStartTime) {
                veBend.withdraw();
            }
            locked[_beneficiary].amount -= _value;
            bendToken.safeTransfer(_beneficiary, _value);

            emit Withdrawn(_beneficiary, _value, block.timestamp);
        }
    }

    function claim() external override onlyOwner {
        uint256 _amount = feeDistributor.claim(true);
        if (_amount > 0) {
            require(WETH.transfer(msg.sender, _amount), "WETH_TRANSFER_FAILED");
        }
    }

    function emergencyWithdraw() external override onlyOwner {
        veBend.withdraw();
        uint256 _bendBalance = bendToken.balanceOf(address(this));
        bendToken.safeTransfer(msg.sender, _bendBalance);
    }
}
