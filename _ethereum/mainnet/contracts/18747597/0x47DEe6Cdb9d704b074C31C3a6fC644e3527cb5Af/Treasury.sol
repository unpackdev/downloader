// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165Upgradeable.sol";
import "./IERC20.sol";
import "./WadRayMath.sol";

import "./TokenTransfersLibrary.sol";
import "./Errors.sol";

import "./TreasuryStorage.sol";
import "./Constants.sol";
import "./ITreasury.sol";

contract Treasury is ITreasury, TreasuryStorage {
    using WadRayMath for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Throws if caller is not granted with _role
     * @param _role The role that is being checked for a function caller
     */
    modifier onlyRole(bytes32 _role) {
        _require(registry.hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc ITreasury
     */
    function initialize(address _registry) external override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = IAccessControl(_registry);
        initialTimestamp = block.timestamp;
        __ReentrancyGuard_init();
        __Pausable_init();
        __ERC165_init();
    }

    receive() external payable override {}

    /**
     * @inheritdoc ITreasury
     */
    function transferFromTreasury(
        uint256 _amount,
        address _token,
        address _receiver
    ) external override whenNotPaused nonReentrant {
        SpendingInfo storage spender = spenders[msg.sender][_token];
        // Check restrictions per transaction
        _require(
            _amount > 0 &&
                _amount <= spender.limits.maxAmountPerTransfer &&
                spender.lastWithdrawalTimestamp + spender.limits.minTimeBetweenTransfers <= block.timestamp &&
                _amount <= spender.limits.maxTotalAmount,
            Errors.TRANSFER_RESTRICTIONS_NOT_MET.selector
        );
        if (_token == NATIVE_CURRENCY) {
            _require(
                _amount <= address(this).balance.wmul(spender.limits.maxPercentPerTransfer),
                Errors.INSUFFICIENT_NATIVE_TOKEN_BALANCE.selector
            );
        } else {
            _require(
                _amount <= IERC20(_token).balanceOf(address(this)).wmul(spender.limits.maxPercentPerTransfer),
                Errors.INSUFFICIENT_TOKEN_BALANCE.selector
            );
        }
        // Check restrictions per timeframe
        if (
            _getTimeframeNumber(block.timestamp, spender) ==
            _getTimeframeNumber(spender.lastWithdrawalTimestamp, spender)
        ) {
            _require(
                spender.withdrawnDuringTimeframe + _amount <= spender.limits.maxAmountDuringTimeframe,
                Errors.EXCEEDED_MAX_AMOUNT_DURING_TIMEFRAME.selector
            );
            spender.withdrawnDuringTimeframe += _amount;
        } else {
            _require(
                _amount <= spender.limits.maxAmountDuringTimeframe,
                Errors.EXCEEDED_MAX_AMOUNT_DURING_TIMEFRAME.selector
            );
            spender.withdrawnDuringTimeframe = _amount;
        }

        spender.lastWithdrawalTimestamp = block.timestamp;
        spender.limits.maxTotalAmount -= _amount;

        if (_token == NATIVE_CURRENCY) {
            TokenTransfersLibrary.doTransferOutETH(_receiver, _amount);
        } else {
            TokenTransfersLibrary.doTransferOut(_token, _receiver, _amount);
        }
        emit TransferFromTreasury(msg.sender, _receiver, _token, _amount);
    }

    /**
     * @inheritdoc ITreasury
     */
    function setMaxSpendingLimit(
        address _spender,
        address _token,
        SpendingLimits calldata _newSpendingLimits
    ) external override onlyRole(BIG_TIMELOCK_ADMIN) {
        _require(
            _newSpendingLimits.maxTotalAmount > 0 &&
                _newSpendingLimits.maxAmountPerTransfer > 0 &&
                _newSpendingLimits.maxPercentPerTransfer > 0 &&
                _newSpendingLimits.maxPercentPerTransfer < WadRayMath.WAD &&
                _newSpendingLimits.maxAmountDuringTimeframe > 0 &&
                _newSpendingLimits.timeframeDuration > 0,
            Errors.SPENDING_LIMITS_ARE_INCORRECT.selector
        );
        SpendingInfo storage spender = spenders[_spender][_token];
        spender.isSpenderExist = true;
        spender.limits = _newSpendingLimits;
        if (spender.lastWithdrawalTimestamp == 0) {
            spender.lastWithdrawalTimestamp = initialTimestamp;
        }
        emit MaxSpendingLimitChanged(_spender, _token, _newSpendingLimits);
    }

    /**
     * @inheritdoc ITreasury
     */
    function decreaseLimits(
        address _spender,
        address _token,
        SpendingLimits calldata _newSpendingLimits
    ) external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        SpendingInfo storage spender = spenders[_spender][_token];
        SpendingLimits memory spenderLimits = spender.limits;
        _require(spender.isSpenderExist, Errors.SPENDER_IS_NOT_EXIST.selector);
        _require(
            _newSpendingLimits.maxTotalAmount <= spenderLimits.maxTotalAmount &&
                _newSpendingLimits.maxAmountPerTransfer <= spenderLimits.maxAmountPerTransfer &&
                _newSpendingLimits.maxPercentPerTransfer <= spenderLimits.maxPercentPerTransfer &&
                _newSpendingLimits.minTimeBetweenTransfers >= spenderLimits.minTimeBetweenTransfers &&
                _newSpendingLimits.timeframeDuration >= spenderLimits.timeframeDuration &&
                _newSpendingLimits.maxAmountDuringTimeframe <= spenderLimits.maxAmountDuringTimeframe,
            Errors.EXCEEDED_MAX_SPENDING_LIMITS.selector
        );
        spender.limits = _newSpendingLimits;
        emit MaxSpendingLimitChanged(_spender, _token, _newSpendingLimits);
    }

    /**
     * @inheritdoc IPausable
     */
    function pause() external override onlyRole(EMERGENCY_ADMIN) {
        _pause();
    }

    /**
     * @inheritdoc IPausable
     */
    function unpause() external override onlyRole(SMALL_TIMELOCK_ADMIN) {
        _unpause();
    }

    /**
     * @inheritdoc ITreasury
     */
    function canTransferByTime(address _spender, address _token) external view override returns (bool) {
        SpendingInfo memory spender = spenders[_spender][_token];
        _require(spender.isSpenderExist, Errors.SPENDER_IS_NOT_EXIST.selector);
        return spender.lastWithdrawalTimestamp + spender.limits.minTimeBetweenTransfers < block.timestamp;
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view override returns (bool) {
        return _interfaceId == type(ITreasury).interfaceId || super.supportsInterface(_interfaceId);
    }

    function _getTimeframeNumber(uint256 _timestamp, SpendingInfo memory _spender) internal view returns (uint256) {
        return ((_timestamp - initialTimestamp) / _spender.limits.timeframeDuration);
    }
}
