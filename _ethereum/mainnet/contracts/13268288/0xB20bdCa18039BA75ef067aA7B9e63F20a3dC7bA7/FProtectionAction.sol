// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IProtectionAction.sol";
import "./ISwapModule.sol";
import "./SafeERC20.sol";
import "./SAave.sol";
import "./CAaveServices.sol";
import "./CProtectionAction.sol";
import "./SProtection.sol";
import "./FProtection.sol";

function _checkRepayAndFlashBorrowAmt(
    ProtectionPayload memory _protectionPayload,
    ILendingPool _lendingPool,
    ILendingPoolAddressesProvider _lendingPoolAddressesProvider,
    IProtectionAction _protectionAction
) view {
    RepayAndFlashBorrowData memory rAndFAmtData;

    rAndFAmtData.user = _protectionPayload.onBehalfOf;
    rAndFAmtData.colToken = _protectionPayload.colToken;
    rAndFAmtData.debtToken = _protectionPayload.debtToken;
    rAndFAmtData.wantedHealthFactor = _protectionPayload.wantedHealthFactor;
    rAndFAmtData.protectionFeeInETH = _protectionPayload.protectionFeeInETH;

    RepayAndFlashBorrowResult
        memory rAndFAmtResult = _getRepayAndFlashBorrowAmt(
            rAndFAmtData,
            _lendingPool,
            _lendingPoolAddressesProvider
        );

    uint256 slippage = _slippage(
        rAndFAmtResult.amtOfDebtToRepay,
        _protectionAction.slippageInBps()
    );
    // Due to accrued aToken, we have some discrepancy we cap it to 1 BPS maximum.
    uint256 oneBpsDiscrepancy = _oneBpsDiscrepancy(
        rAndFAmtResult.amtToFlashBorrow
    );

    bool isFlashBorrowAmtOk = _protectionPayload.amtToFlashBorrow <=
        rAndFAmtResult.amtToFlashBorrow + oneBpsDiscrepancy;
    bool isAmtOfDebtToRepayOk = _protectionPayload.amtOfDebtToRepay >=
        rAndFAmtResult.amtOfDebtToRepay - slippage;

    if (isFlashBorrowAmtOk && isAmtOfDebtToRepayOk) return;
    if (isFlashBorrowAmtOk && !isAmtOfDebtToRepayOk)
        revert(
            "_checkRepayAndFlashBorrowAmt: OffChain amtOfDebtToRepay != onchain amtOfDebtToRepay, out of slippage range."
        );
    if (!isFlashBorrowAmtOk && isAmtOfDebtToRepayOk)
        revert(
            "_checkRepayAndFlashBorrowAmt: OffChain amtToFlashBorrow != onchain amtToFlashBorrow."
        );
    revert(
        "_checkRepayAndFlashBorrowAmt: OffChain amtOfDebtToRepay != onchain amtOfDebtToRepay, out of slippage range. OffChain amtToFlashBorrow != onchain amtToFlashBorrow."
    );
}

function _getProtectionPayload(
    bytes32 _taskHash,
    bytes memory _data,
    bytes memory _offChainData
) pure returns (ProtectionPayload memory) {
    ProtectionPayload memory protectionPayload;

    protectionPayload.taskHash = _taskHash;

    (
        protectionPayload.colToken,
        protectionPayload.debtToken,
        protectionPayload.rateMode,
        protectionPayload.wantedHealthFactor,
        protectionPayload.minimumHealthFactor,
        protectionPayload.onBehalfOf
    ) = abi.decode(
        _data,
        (address, address, uint256, uint256, uint256, address)
    );

    (
        protectionPayload.amtToFlashBorrow,
        protectionPayload.amtOfDebtToRepay,
        protectionPayload.protectionFeeInETH,
        protectionPayload.swapActions,
        protectionPayload.swapDatas,
        protectionPayload.subBlockNumber,
        protectionPayload.isPermanent
    ) = abi.decode(
        _offChainData,
        (uint256, uint256, uint256, address[], bytes[], uint256, bool)
    );

    return protectionPayload;
}

function _flashLoan(
    ILendingPool _lendingPool,
    address receiverAddress,
    ProtectionPayload memory _protectionPayload
) {
    address[] memory flashBorrowTokens = new address[](1);
    flashBorrowTokens[0] = _protectionPayload.colToken;

    uint256[] memory amtToFlashBorrows = new uint256[](1);
    amtToFlashBorrows[0] = _protectionPayload.amtToFlashBorrow;

    _lendingPool.flashLoan(
        receiverAddress,
        flashBorrowTokens,
        amtToFlashBorrows,
        new uint256[](1),
        _protectionPayload.onBehalfOf,
        abi.encode(
            FlashLoanParamsData(
                _protectionPayload.minimumHealthFactor,
                _protectionPayload.taskHash,
                _protectionPayload.debtToken,
                _protectionPayload.amtOfDebtToRepay,
                _protectionPayload.rateMode,
                _protectionPayload.onBehalfOf,
                _protectionPayload.protectionFeeInETH,
                _protectionPayload.swapActions,
                _protectionPayload.swapDatas
            )
        ),
        0
    );
}

function _approveERC20Token(
    address _asset,
    address _spender,
    uint256 _amount
) {
    // Approves 0 first to comply with tokens that implement the anti frontrunning approval fix
    SafeERC20.safeApprove(IERC20(_asset), _spender, 0);
    SafeERC20.safeApprove(IERC20(_asset), _spender, _amount);
}

function _paybackToLendingPool(
    ILendingPool _lendingPool,
    address _asset,
    uint256 _amount,
    uint256 _rateMode,
    address _onBehalf
) {
    _approveERC20Token(_asset, address(_lendingPool), _amount);
    _lendingPool.repay(_asset, _amount, _rateMode, _onBehalf);
}

function _withdrawCollateral(
    ILendingPool _lendingPool,
    address _to,
    address _asset,
    uint256 _amount,
    address _onBehalf
) {
    DataTypes.ReserveData memory reserve = _lendingPool.getReserveData(_asset);

    SafeERC20.safeTransferFrom(
        IERC20(reserve.aTokenAddress),
        _onBehalf,
        _to,
        _amount
    );

    _lendingPool.withdraw(_asset, _amount, _to);
}

function _transferFees(address _asset, uint256 _amount) {
    SafeERC20.safeTransfer(IERC20(_asset), GELATO, _amount);
}

function _requirePositionSafe(
    uint256 _healthFactor,
    uint256 _discrepancyBps,
    uint256 _wantedHealthFactor
) pure {
    uint256 discrepancy = (_wantedHealthFactor * _discrepancyBps) /
        TEN_THOUSAND_BPS;

    require(
        _healthFactor < _wantedHealthFactor + discrepancy &&
            _healthFactor > _wantedHealthFactor - discrepancy &&
            _healthFactor > 1e18,
        "The user position isn't safe after the protection of the debt."
    );
}

function _requirePositionUnSafe(
    uint256 _currentHealthFactor,
    uint256 _minimumHealthFactor
) pure {
    require(
        _currentHealthFactor < _minimumHealthFactor,
        "The user position's health factor is above the minimum trigger health factor."
    );
}

function _transferDust(
    address _sender,
    address _asset,
    address _user
) {
    uint256 serviceBalance = IERC20(_asset).balanceOf(_sender);

    if (serviceBalance > 0) {
        SafeERC20.safeTransfer(IERC20(_asset), _user, serviceBalance);
    }
}

function _swap(
    address _this,
    ISwapModule _swapModule,
    address[] memory _swapActions,
    bytes[] memory _swapDatas,
    IERC20 _outputToken,
    IERC20 _inputToken,
    uint256 _inputAmt,
    uint256 _minReturn
) returns (uint256 receivedAmt) {
    uint256 outputTokenbalanceBSwap = _outputToken.balanceOf(_this);

    SafeERC20.safeTransfer(_inputToken, address(_swapModule), _inputAmt);
    _swapModule.swap(_swapActions, _swapDatas);

    receivedAmt = _outputToken.balanceOf(_this) - outputTokenbalanceBSwap;

    require(
        receivedAmt > _minReturn,
        "ProtectionAction.swap: received amount < minReturn."
    );
}

function _slippage(uint256 _amount, uint256 _slippageInBps)
    pure
    returns (uint256)
{
    return (_amount * _slippageInBps) / TEN_THOUSAND_BPS;
}

// Due to accrued aToken, we have some discrepancy.
function _oneBpsDiscrepancy(uint256 _amount) pure returns (uint256) {
    return _amount / TEN_THOUSAND_BPS;
}

function _checkSubmitterIsUser(
    ProtectionPayload memory _protectionPayload,
    bytes memory _payload
) pure {
    require(
        _protectionPayload.taskHash ==
            keccak256(
                abi.encode(
                    _protectionPayload.onBehalfOf,
                    _protectionPayload.subBlockNumber,
                    _payload,
                    _protectionPayload.isPermanent
                )
            ),
        "ProtectionAction._checkSubmitterIsUser: Task submitter != user"
    );
}
