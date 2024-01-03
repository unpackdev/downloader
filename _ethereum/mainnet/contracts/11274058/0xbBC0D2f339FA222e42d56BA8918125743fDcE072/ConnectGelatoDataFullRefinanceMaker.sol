// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./GelatoBytes.sol";
import "./DSMath.sol";
import "./IInstaDapp.sol";
import "./IConnectInstaPoolV2.sol";
import "./CInstaDapp.sol";
import "./FMaker.sol";
import "./FInstaPoolV2.sol";
import "./FConnectMaker.sol";
import "./FConnectGelatoProviderPayment.sol";
import "./FConnectCompound.sol";
import "./FGelato.sol";
import "./FGelatoDebtBridge.sol";

contract ConnectGelatoDataFullRefinanceMaker is ConnectorInterface {
    using GelatoBytes for bytes;

    // solhint-disable const-name-snakecase
    string public constant override name =
        "ConnectGelatoDataFullRefinanceMaker-v1.0";
    uint256 internal immutable _id;
    address internal immutable _connectGelatoProviderPayment;

    constructor(uint256 id, address connectGelatoProviderPayment) {
        _id = id;
        _connectGelatoProviderPayment = connectGelatoProviderPayment;
    }

    /// @dev Connector Details
    function connectorID()
        external
        view
        override
        returns (uint256 _type, uint256 id)
    {
        (_type, id) = (1, _id); // Should put specific value.
    }

    /// @notice Entry Point for DSA.cast DebtBridge from e.g ETH-A to ETH-B
    /// @dev payable to be compatible in conjunction with DSA.cast payable target
    /// @param _vaultAId Id of the unsafe vault of the client of Vault A Collateral.
    /// @param _vaultBId Id of the vault B Collateral of the client.
    /// @param _colToken  vault's col token address .
    /// @param _colType colType of the new vault. example : ETH-B, ETH-A.
    function getDataAndCastMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        address _colToken,
        string calldata _colType
    ) external payable {
        (address[] memory targets, bytes[] memory datas) =
            _dataMakerToMaker(_vaultAId, _vaultBId, _colToken, _colType);

        _cast(targets, datas);
    }

    /// @notice Entry Point for DSA.cast DebtBridge from Maker to Compound
    /// @dev payable to be compatible in conjunction with DSA.cast payable target
    /// @param _vaultId Id of the unsafe vault of the client.
    /// @param _colToken  vault's col token address .
    function getDataAndCastMakerToCompound(uint256 _vaultId, address _colToken)
        external
        payable
    {
        (address[] memory targets, bytes[] memory datas) =
            _dataMakerToCompound(_vaultId, _colToken);

        _cast(targets, datas);
    }

    function _cast(address[] memory targets, bytes[] memory datas) internal {
        // Instapool V2 / FlashLoan call
        bytes memory castData =
            abi.encodeWithSelector(
                AccountInterface.cast.selector,
                targets,
                datas,
                msg.sender // msg.sender == GelatoCore
            );

        (bool success, bytes memory returndata) =
            address(this).delegatecall(castData);
        if (!success) {
            returndata.revertWithError(
                "ConnectGelatoDataFullRefinanceMaker._cast:"
            );
        }
    }

    /* solhint-disable function-max-lines */

    function _dataMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        address _colToken,
        string calldata _colType
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](1);
        targets[0] = INSTA_POOL_V2;

        uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_vaultAId));
        uint256 wColToWithdrawFromMaker =
            _getMakerVaultCollateralBalance(_vaultAId);
        uint256 route = _getFlashLoanRoute(DAI, wDaiToBorrow);
        uint256 gasCost = _getGasCostMakerToMaker(_vaultBId == 0, route);
        uint256 gasFeesPaidFromCol = _getGelatoProviderFees(gasCost);

        (address[] memory _targets, bytes[] memory _datas) =
            _vaultBId == 0
                ? _spellsMakerToNewMakerVault(
                    _vaultAId,
                    _colToken,
                    _colType,
                    wDaiToBorrow,
                    wColToWithdrawFromMaker,
                    gasFeesPaidFromCol
                )
                : _spellsMakerToMaker(
                    _vaultAId,
                    _vaultBId,
                    _colToken,
                    wDaiToBorrow,
                    wColToWithdrawFromMaker,
                    gasFeesPaidFromCol
                );

        datas = new bytes[](1);
        datas[0] = abi.encodeWithSelector(
            IConnectInstaPoolV2.flashBorrowAndCast.selector,
            DAI,
            wDaiToBorrow,
            route,
            abi.encode(_targets, _datas)
        );
    }

    function _spellsMakerToNewMakerVault(
        uint256 _vaultAId,
        address _colToken,
        string calldata _colType,
        uint256 _wDaiToBorrow,
        uint256 _wColToWithdrawFromMaker,
        uint256 _gasFeesPaidFromCol
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](7);
        targets[0] = CONNECT_MAKER; // payback
        targets[1] = CONNECT_MAKER; // withdraw
        targets[2] = CONNECT_MAKER; // open new B vault
        targets[3] = CONNECT_MAKER; // deposit
        targets[4] = CONNECT_MAKER; // borrow
        targets[5] = _connectGelatoProviderPayment; // payProvider
        targets[6] = INSTA_POOL_V2; // flashPayback

        datas = new bytes[](7);
        datas[0] = _encodePaybackMakerVault(_vaultAId, uint256(-1), 0, 600);
        datas[1] = _encodedWithdrawMakerVault(_vaultAId, uint256(-1), 0, 0);
        datas[2] = _encodeOpenMakerVault(_colType);
        datas[3] = _encodedDepositMakerVault(
            0,
            sub(_wColToWithdrawFromMaker, _gasFeesPaidFromCol),
            0,
            0
        );
        datas[4] = _encodeBorrowMakerVault(0, 0, 600, 0);
        datas[5] = _encodePayGelatoProvider(
            _colToken,
            _gasFeesPaidFromCol,
            0,
            0
        );
        datas[6] = _encodeFlashPayback(DAI, _wDaiToBorrow, 0, 0);
    }

    function _spellsMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        address _colToken,
        uint256 _wDaiToBorrow,
        uint256 _wColToWithdrawFromMaker,
        uint256 _gasFeesPaidFromCol
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        targets = new address[](6);
        targets[0] = CONNECT_MAKER; // payback
        targets[1] = CONNECT_MAKER; // withdraw
        targets[2] = CONNECT_MAKER; // deposit
        targets[3] = CONNECT_MAKER; // borrow
        targets[4] = _connectGelatoProviderPayment; // payProvider
        targets[5] = INSTA_POOL_V2; // flashPayback

        datas = new bytes[](6);
        datas[0] = _encodePaybackMakerVault(_vaultAId, uint256(-1), 0, 600);
        datas[1] = _encodedWithdrawMakerVault(_vaultAId, uint256(-1), 0, 0);
        datas[2] = _encodedDepositMakerVault(
            _vaultBId,
            sub(_wColToWithdrawFromMaker, _gasFeesPaidFromCol),
            0,
            0
        );
        datas[3] = _encodeBorrowMakerVault(_vaultBId, 0, 600, 0);
        datas[4] = _encodePayGelatoProvider(
            _colToken,
            _gasFeesPaidFromCol,
            0,
            0
        );
        datas[5] = _encodeFlashPayback(DAI, _wDaiToBorrow, 0, 0);
    }

    function _dataMakerToCompound(uint256 _vaultId, address _colToken)
        internal
        view
        returns (address[] memory targets, bytes[] memory datas)
    {
        targets = new address[](1);
        targets[0] = INSTA_POOL_V2;

        uint256 wDaiToBorrow = _getRealisedDebt(_getMakerVaultDebt(_vaultId));
        uint256 wColToWithdrawFromMaker =
            _getMakerVaultCollateralBalance(_vaultId);
        uint256 route = _getFlashLoanRoute(DAI, wDaiToBorrow);
        uint256 gasCost = _getGasCostMakerToCompound(route);
        uint256 gasFeesPaidFromCol = _getGelatoProviderFees(gasCost);

        address[] memory _targets = new address[](6);
        _targets[0] = CONNECT_MAKER; // payback
        _targets[1] = CONNECT_MAKER; // withdraw
        _targets[2] = CONNECT_COMPOUND; // deposit
        _targets[3] = CONNECT_COMPOUND; // borrow
        _targets[4] = _connectGelatoProviderPayment; // payProvider
        _targets[5] = INSTA_POOL_V2; // flashPayback

        bytes[] memory _datas = new bytes[](6);
        _datas[0] = _encodePaybackMakerVault(_vaultId, uint256(-1), 0, 600);
        _datas[1] = _encodedWithdrawMakerVault(_vaultId, uint256(-1), 0, 0);
        _datas[2] = _encodeDepositCompound(
            _colToken,
            sub(wColToWithdrawFromMaker, gasFeesPaidFromCol),
            0,
            0
        );
        _datas[3] = _encodeBorrowCompound(DAI, 0, 600, 0);
        _datas[4] = _encodePayGelatoProvider(
            _colToken,
            gasFeesPaidFromCol,
            0,
            0
        );
        _datas[5] = _encodeFlashPayback(DAI, wDaiToBorrow, 0, 0);

        datas = new bytes[](1);
        datas[0] = abi.encodeWithSelector(
            IConnectInstaPoolV2.flashBorrowAndCast.selector,
            DAI,
            wDaiToBorrow,
            route,
            abi.encode(_targets, _datas)
        );
    }

    /* solhint-enable function-max-lines */
}
