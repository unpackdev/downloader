// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @dev Kyoko Token release rules contract.
 */
contract KyokoVesting is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public vestingToken;

    struct InitVestingInfo {
        address beneficiary;
        uint256 fullyVestedAmount;
        uint256 startDate; // 0 indicates start "now"
        uint256 cliffSec;
        uint256 durationSec;
        bool isRevocable;
    }

    struct VestingInfo {
        address beneficiary;
        uint256 fullyVestedAmount;
        uint256 withdrawnVestedAmount;
        uint256 startDate;
        uint256 cliffDate;
        uint256 durationSec;
        bool isRevocable; //true rep the token vesting rule can be revoked
        bool revocationStatus; //true rep the current status is revocation
        uint256 revokeDate; //the date of modify isRevocable to true
    }

    mapping(address => VestingInfo[]) vestingMapping;

    event GrantVestedTokens(
        address indexed beneficiary,
        uint256 fullyVestedAmount,
        uint256 startDate,
        uint256 cliffSec,
        uint256 durationSec,
        bool isRevocable
    );

    event ModifyVestedTokens(
        address indexed beneficiary,
        uint256 fullyVestedAmount,
        uint256 startDate,
        uint256 cliffSec,
        uint256 durationSec,
        bool isRevocable
    );

    event RemoveVestedTokens(
        address indexed beneficiary,
        uint256 index,
        uint256 fullyVestedAmount,
        uint256 withdrawnVestedAmount
    );

    event RevokeVesting(address indexed beneficiary, uint256 index);

    event RestoreReleaseState(address indexed beneficiary, uint256 index);

    event WithdrawPendingVestingTokens(
        uint256 indexed index,
        uint256 pendingVestedAmount,
        address indexed beneficiary,
        uint256 claimTimestamp
    );

    event Withdraw(address indexed recipient, uint256 amount);

    // constructor(address _token) {
    //     vestingToken = IERC20Upgradeable(_token);
    // }

    function initialize(address _token) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        vestingToken = IERC20Upgradeable(_token);
    }

    /**
     * @dev The kyoko manager grants vested tokens to users — we’ll call them beneficiaries.
     * eg. seed investors、strategic investors.
     */
    function grantVestedTokens(
        address _beneficiary,
        uint256 _fullyVestedAmount,
        uint256 _startDate, // 0 indicates start "now"
        uint256 _cliffSec,
        uint256 _durationSec,
        bool _isRevocable
    ) public onlyOwner returns (bool) {
        require(
            _beneficiary != address(0x0),
            "the beneficiary must be not zero address"
        );
        require(
            _fullyVestedAmount > 0,
            "The amount of vesting tokens must be greater than 0"
        );
        require(
            _durationSec >= _cliffSec,
            "The total token release cycle must be greater than the cliff period"
        );

        if (_startDate == 0) {
            _startDate = block.timestamp;
        }

        uint256 _cliffDate = _startDate + _cliffSec;

        VestingInfo[] storage vestingArray = vestingMapping[_beneficiary];
        vestingArray.push(
            VestingInfo({
                beneficiary: _beneficiary,
                fullyVestedAmount: _fullyVestedAmount,
                withdrawnVestedAmount: 0,
                startDate: _startDate,
                cliffDate: _cliffDate,
                durationSec: _durationSec,
                isRevocable: _isRevocable,
                revocationStatus: false,
                revokeDate: 0
            })
        );

        // vestingToken.safeTransferFrom(
        //     _msgSender(),
        //     address(this),
        //     _fullyVestedAmount
        // );

        emit GrantVestedTokens(
            _beneficiary,
            _fullyVestedAmount,
            _startDate,
            _cliffSec,
            _durationSec,
            _isRevocable
        );

        return true;
    }

    function grantListVestedTokens(InitVestingInfo[] calldata vestingInfoArray)
        public
        onlyOwner
    {
        for (uint8 i = 0; i < vestingInfoArray.length; i++) {
            InitVestingInfo memory vestingInfo = vestingInfoArray[i];
            grantVestedTokens(
                vestingInfo.beneficiary,
                vestingInfo.fullyVestedAmount,
                vestingInfo.startDate,
                vestingInfo.cliffSec,
                vestingInfo.durationSec,
                vestingInfo.isRevocable
            );
        }
    }

    /**
     * @dev modify the vestingMap data
     */
    function modifyVestedTokens(
        address _beneficiary,
        uint256 _index,
        uint256 _fullyVestedAmount,
        uint256 _startDate,
        uint256 _cliffSec,
        uint256 _durationSec,
        bool _isRevocable
    ) public onlyOwner {
        require(_beneficiary != address(0), "beneficiary is empty");
        require(_fullyVestedAmount > 0, "amount must greater than 0");
        require(_durationSec >= _cliffSec, "duration error");
        //when modify the info, `_startDate` must not be 0
        require(_startDate != 0, "the startDate must not be zero");

        uint256 _cliffDate = _startDate + _cliffSec;

        VestingInfo storage vestingInfo = vestingMapping[_beneficiary][_index];

        if (_fullyVestedAmount != vestingInfo.fullyVestedAmount) {
            // the amount has changed.
            // This part of the token needs to be transferred back to the token manager
            // or transfer another portion of tokens to the current contract
            if (_fullyVestedAmount > vestingInfo.fullyVestedAmount) {
                vestingToken.safeTransferFrom(
                    _msgSender(),
                    address(this),
                    _fullyVestedAmount - vestingInfo.fullyVestedAmount
                );
            } else {
                vestingToken.safeTransfer(
                    _msgSender(),
                    vestingInfo.fullyVestedAmount - _fullyVestedAmount
                );
            }
        }

        vestingInfo.fullyVestedAmount = _fullyVestedAmount;
        vestingInfo.startDate = _startDate;
        vestingInfo.cliffDate = _cliffDate;
        vestingInfo.durationSec = _durationSec;
        vestingInfo.isRevocable = _isRevocable;

        emit ModifyVestedTokens(
            _beneficiary,
            _fullyVestedAmount,
            _startDate,
            _cliffSec,
            _durationSec,
            _isRevocable
        );
    }

    /**
     * @dev Remove the data in the VestingMap, preferably before the token is released,
     * to correct the error in the previous authorization
     */
    function removeVestedTokens(address _beneficiary, uint256 _index)
        public
        onlyOwner
    {
        VestingInfo[] storage vestingArray = vestingMapping[_beneficiary];

        uint256 tempFullyVestedAmount = vestingArray[_index].fullyVestedAmount;
        uint256 tempWithdrawnVestedAmount = vestingArray[_index]
            .withdrawnVestedAmount;

        vestingArray[_index] = vestingArray[vestingArray.length - 1];
        vestingArray.pop();

        vestingToken.safeTransfer(
            _msgSender(),
            tempFullyVestedAmount - tempWithdrawnVestedAmount
        );

        emit RemoveVestedTokens(
            _beneficiary,
            _index,
            tempFullyVestedAmount,
            tempWithdrawnVestedAmount
        );
    }

    /**
     * @dev Revoke the beneficiary's token release authority
     * @dev Tokens released before this time point can still be withdrawn by the beneficiary
     */
    function revokeVesting(address _beneficiary, uint256 _index)
        public
        onlyOwner
        returns (bool)
    {
        VestingInfo storage vestingInfo = vestingMapping[_beneficiary][_index];
        require(vestingInfo.isRevocable, "this vesting can not revoke");
        require(!vestingInfo.revocationStatus, "this vesting already revoke");

        require(
            block.timestamp < vestingInfo.startDate + vestingInfo.durationSec,
            "the beneficiary's vesting have already complete release"
        );

        vestingInfo.revocationStatus = true;
        vestingInfo.revokeDate = block.timestamp;

        emit RevokeVesting(_beneficiary, _index);
        return true;
    }

    /**
     * @dev when the manager revoke vesting token.execute this fun can return to normal release state
     */
    function restoreReleaseState(address _beneficiary, uint256 _index)
        public
        onlyOwner
        returns (bool)
    {
        VestingInfo storage vestingInfo = vestingMapping[_beneficiary][_index];
        require(vestingInfo.isRevocable, "this vesting can not revoke");
        require(
            vestingInfo.revocationStatus,
            "this vesting is normal release state"
        );

        require(
            block.timestamp < vestingInfo.startDate + vestingInfo.durationSec,
            "the beneficiary's vesting have already complete release"
        );

        vestingInfo.revocationStatus = false;
        vestingInfo.revokeDate = 0;

        emit RestoreReleaseState(_beneficiary, _index);
        return true;
    }

    /**
     * @dev the beneficiary Withdraw the vesting tokens released over time
     */
    function withdrawPendingVestingTokens(uint256 _index)
        public
        whenNotPaused
        nonReentrant
        returns (bool, uint256)
    {
        VestingInfo storage vestingInfo = vestingMapping[_msgSender()][_index];
        (, uint256 pendingVestedAmount) = _vestingSchedule(vestingInfo);

        require(pendingVestedAmount > 0, "the pending vested amount is zero.");

        vestingInfo.withdrawnVestedAmount += pendingVestedAmount;

        vestingToken.safeTransfer(_msgSender(), pendingVestedAmount);

        emit WithdrawPendingVestingTokens(
            _index,
            pendingVestedAmount,
            msg.sender,
            block.timestamp
        );

        return (true, pendingVestedAmount);
    }

    function queryTokenVestingInfo(address _beneficiary)
        public
        view
        returns (VestingInfo[] memory)
    {
        return vestingMapping[_beneficiary];
    }

    /**
     * @dev query the `_beneficiary` amount of all tokens released
     */
    function queryTokenVestingsAmount(address _beneficiary)
        public
        view
        returns (uint256 allVestedAmount, uint256 pendingVestedAmount)
    {
        VestingInfo[] memory vestingArray = queryTokenVestingInfo(_beneficiary);
        if (vestingArray.length == 0) {
            return (0, 0);
        }
        for (uint256 i = 0; i < vestingArray.length; i++) {
            VestingInfo memory vestingInfo = vestingArray[i];
            (
                uint256 tempVestedAmount,
                uint256 tempPendingAmount
            ) = _vestingSchedule(vestingInfo);
            allVestedAmount += tempVestedAmount;
            pendingVestedAmount += tempPendingAmount;
        }
    }

    /**
     * @dev query the `_beneficiary` amount of all tokens released in the `_index`
     */
    function queryTokenVestingAmount(address _beneficiary, uint256 _index)
        public
        view
        returns (uint256 allVestedAmount, uint256 pendingVestedAmount)
    {
        VestingInfo[] memory vestingArray = queryTokenVestingInfo(_beneficiary);
        if (vestingArray.length == 0 || _index >= vestingArray.length) {
            return (0, 0);
        }
        VestingInfo memory vestingInfo = vestingArray[_index];
        (allVestedAmount, pendingVestedAmount) = _vestingSchedule(vestingInfo);
    }

    /**
     * @dev implementation of the vesting formula. This returns the amout vested, as a function of time, for an asset given its total historical allocation.
     * @dev the current release rules are linear.
     * @return allVestedAmount As of the current time, all available attribution tokens (including those that have been claimed)
     * @return pendingVestedAmount The attribution token to be claimed
     */
    function _vestingSchedule(VestingInfo memory vestingInfo)
        internal
        view
        returns (uint256 allVestedAmount, uint256 pendingVestedAmount)
    {
        uint256 _startDate = vestingInfo.startDate;
        uint256 _cliffDate = vestingInfo.cliffDate;
        uint256 _durationSec = vestingInfo.durationSec;
        uint256 _fullyVestedAmount = vestingInfo.fullyVestedAmount;
        uint256 _withdrawnVestedAmount = vestingInfo.withdrawnVestedAmount;

        uint256 _endDate = _startDate + _durationSec;
        uint256 _releaseTotalTime = _durationSec - (_cliffDate - _startDate);

        uint256 curentTime = getCurrentTime();

        bool _isRevocable = vestingInfo.isRevocable;
        bool _revocationStatus = vestingInfo.revocationStatus;
        uint256 _revokeDate = vestingInfo.revokeDate;
        //when the vesting info's `_revocationStatus` is true, calculate the amount of suspensions during the time period
        uint256 disableAmount = 0;
        if (_isRevocable && _revocationStatus && _revokeDate != 0) {
            //current status is revocation
            if (_revokeDate <= _startDate || _revokeDate < _cliffDate) {
                return (0, 0);
            } else {
                uint256 disableTime = (
                    curentTime > _endDate ? _endDate : curentTime
                ) - _revokeDate;
                disableAmount =
                    (disableTime * _fullyVestedAmount * 100) /
                    _releaseTotalTime /
                    100;
            }
        }

        if (curentTime <= _startDate || curentTime < _cliffDate) {
            return (0, 0);
        } else if (curentTime >= _endDate) {
            return (
                _fullyVestedAmount - disableAmount,
                _fullyVestedAmount - _withdrawnVestedAmount - disableAmount
            );
        } else {
            uint256 _releaseRemainTime = curentTime - _cliffDate;
            uint256 temp = (_releaseRemainTime * _fullyVestedAmount * 100) /
                _releaseTotalTime /
                100;

            return (
                temp - disableAmount,
                temp - _withdrawnVestedAmount - disableAmount
            );
        }
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev The owner has the right to withdraw the token in the current contract
     */
    function withdraw(uint256 amount) public onlyOwner {
        uint256 balance = vestingToken.balanceOf(address(this));
        require(balance >= amount, "amount is error");

        vestingToken.safeTransfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount);
    }
}
