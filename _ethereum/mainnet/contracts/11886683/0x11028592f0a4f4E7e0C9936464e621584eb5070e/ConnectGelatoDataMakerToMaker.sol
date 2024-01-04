// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IConnectInstaPoolV2.sol";
import "./CTokens.sol";
import "./CInstaDapp.sol";
import "./FMaker.sol";
import "./FInstaPoolV2.sol";
import "./FConnectMaker.sol";
import "./FConnectBasic.sol";
import "./FConnectDebtBridgeFee.sol";
import "./FGelato.sol";
import "./FGelatoDebtBridge.sol";
import "./IInstaFeeCollector.sol";
import "./BDebtBridgeFromMaker.sol";
import "./IOracleAggregator.sol";
import "./Convert.sol";
import "./CGelato.sol";

contract ConnectGelatoDataMakerToMaker is BDebtBridgeFromMaker {
    // solhint-disable const-name-snakecase
    string public constant override name = "ConnectGelatoDataMakerToMaker-v3.0";

    // solhint-disable no-empty-blocks
    constructor(
        uint256 __id,
        address _oracleAggregator,
        address __instaFeeCollector,
        address __connectGelatoDebtBridgeFee
    )
        BDebtBridgeFromMaker(
            __id,
            _oracleAggregator,
            __instaFeeCollector,
            __connectGelatoDebtBridgeFee
        )
    {}

    /// @notice Entry Point for DSA.cast DebtBridge from e.g ETH-A to ETH-B
    /// @dev payable to be compatible in conjunction with DSA.cast payable target
    /// @param _vaultAId Id of the unsafe vault of the client of Vault A Collateral.
    /// @param _vaultBId Id of the vault B Collateral of the client.
    /// @param _colType colType of the new vault. example : ETH-B, ETH-A.
    function getDataAndCastMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        string calldata _colType
    ) external payable {
        (address[] memory targets, bytes[] memory datas) =
            _dataMakerToMaker(_vaultAId, _vaultBId, _colType);

        _cast(targets, datas);
    }

    /* solhint-disable function-max-lines */

    function _dataMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        string calldata _colType
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](1);
        targets[0] = INSTA_POOL_V2;

        _vaultBId = _isVaultOwner(_vaultBId, address(this)) ? _vaultBId : 0;

        uint256 daiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_vaultAId));
        uint256 wColToWithdrawFromMaker =
            _getMakerVaultCollateralBalance(_vaultAId);

        uint256 route = _getFlashLoanRoute(DAI, _vaultAId, daiToBorrow);

        (uint256 gasFeesPaidFromDebt, uint256 decimals) =
            IOracleAggregator(oracleAggregator).getExpectedReturnAmount(
                _getGelatoExecutorFees(
                    _getGasCostMakerToMaker(_vaultBId == 0, route)
                ),
                ETH,
                DAI
            );

        gasFeesPaidFromDebt = _convertTo18(decimals, gasFeesPaidFromDebt);

        (address[] memory _targets, bytes[] memory _datas) =
            _vaultBId == 0
                ? _spellsMakerToNewMakerVault(
                    _vaultAId,
                    _colType,
                    daiToBorrow,
                    wColToWithdrawFromMaker,
                    gasFeesPaidFromDebt
                )
                : _spellsMakerToMaker(
                    _vaultAId,
                    _vaultBId,
                    daiToBorrow,
                    wColToWithdrawFromMaker,
                    gasFeesPaidFromDebt
                );

        datas = new bytes[](1);
        datas[0] = abi.encodeWithSelector(
            IConnectInstaPoolV2.flashBorrowAndCast.selector,
            DAI,
            daiToBorrow,
            route,
            abi.encode(_targets, _datas)
        );
    }

    function _spellsMakerToNewMakerVault(
        uint256 _vaultAId,
        string calldata _colType,
        uint256 _daiDebtAmt,
        uint256 _colToWithdrawFromMaker,
        uint256 _gasFeesPaidFromDebt
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](9);
        targets[0] = CONNECT_MAKER; // payback
        targets[1] = CONNECT_MAKER; // withdraw
        targets[2] = _connectGelatoDebtBridgeFee; // calculate fee
        targets[3] = CONNECT_MAKER; // open new B vault
        targets[4] = CONNECT_MAKER; // deposit
        targets[5] = CONNECT_MAKER; // borrow
        targets[6] = CONNECT_BASIC; // user pay fee to fee collector
        targets[7] = CONNECT_BASIC; // user pay fast transaction fee to executor
        targets[8] = INSTA_POOL_V2; // flashPayback

        datas = new bytes[](9);
        datas[0] = _encodePaybackMakerVault(
            _vaultAId,
            type(uint256).max,
            0,
            600
        );
        datas[1] = _encodedWithdrawMakerVault(
            _vaultAId,
            type(uint256).max,
            0,
            0
        );
        datas[2] = _encodeCalculateFee(
            0,
            _gasFeesPaidFromDebt,
            IInstaFeeCollector(instaFeeCollector).fee(),
            600,
            600,
            601
        );
        datas[3] = _encodeOpenMakerVault(_colType);
        datas[4] = _encodedDepositMakerVault(0, _colToWithdrawFromMaker, 0, 0);
        datas[5] = _encodeBorrowMakerVault(0, 0, 600, 0);
        datas[6] = _encodeBasicWithdraw(
            DAI,
            0,
            IInstaFeeCollector(instaFeeCollector).feeCollector(),
            601,
            0
        );
        datas[7] = _encodeBasicWithdraw(
            DAI,
            _gasFeesPaidFromDebt,
            payable(GELATO_EXECUTOR_MODULE),
            0,
            0
        );
        datas[8] = _encodeFlashPayback(DAI, _daiDebtAmt, 0, 0);
    }

    function _spellsMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        uint256 _daiDebtAmt,
        uint256 _colToWithdrawFromMaker,
        uint256 _gasFeesPaidFromDebt
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](8);
        targets[0] = CONNECT_MAKER; // payback
        targets[1] = CONNECT_MAKER; // withdraw
        targets[2] = _connectGelatoDebtBridgeFee; // calculate fee
        targets[3] = CONNECT_MAKER; // deposit
        targets[4] = CONNECT_MAKER; // borrow
        targets[5] = CONNECT_BASIC; // pay fee to instadapp fee collector
        targets[6] = CONNECT_BASIC; // pay fast transaction fee to gelato executor
        targets[7] = INSTA_POOL_V2; // flashPayback

        datas = new bytes[](8);
        datas[0] = _encodePaybackMakerVault(
            _vaultAId,
            type(uint256).max,
            0,
            600
        );
        datas[1] = _encodedWithdrawMakerVault(
            _vaultAId,
            type(uint256).max,
            0,
            0
        );
        datas[2] = _encodeCalculateFee(
            0,
            _gasFeesPaidFromDebt,
            IInstaFeeCollector(instaFeeCollector).fee(),
            600,
            600,
            601
        );
        datas[3] = _encodedDepositMakerVault(
            _vaultBId,
            _colToWithdrawFromMaker,
            0,
            0
        );
        datas[4] = _encodeBorrowMakerVault(_vaultBId, 0, 600, 0);
        datas[5] = _encodeBasicWithdraw(
            DAI,
            0,
            IInstaFeeCollector(instaFeeCollector).feeCollector(),
            601,
            0
        );
        datas[6] = _encodeBasicWithdraw(
            DAI,
            _gasFeesPaidFromDebt,
            payable(GELATO_EXECUTOR_MODULE),
            0,
            0
        );
        datas[7] = _encodeFlashPayback(DAI, _daiDebtAmt, 0, 0);
    }

    /* solhint-enable function-max-lines */
}
