// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./GelatoBytes.sol";
import "./IInstaDapp.sol";
import "./IGelatoCore.sol";
import "./FMaker.sol";
import "./SDebtBridge.sol";
import "./CTokens.sol";
import "./FGelatoDebtBridge.sol";
import "./CDebtBridge.sol";
import "./FGelatoDebtBridge.sol";
import "./FConnectGelatoDataMakerToAave.sol";
import "./FConnectGelatoDataMakerToMaker.sol";
import "./FConnectGelatoDataMakerToCompound.sol";
import "./IInstaFeeCollector.sol";

contract ConnectGelatoDataMakerToX is ConnectorInterface {
    using GelatoBytes for bytes;

    string public constant OK = "OK";

    // solhint-disable const-name-snakecase
    string public constant override name = "ConnectGelatoDataMakerToX-v1.0";
    uint256 internal immutable _id;
    address public immutable oracleAggregator;
    address internal immutable _instaFeeCollector;
    address internal immutable _connectGelatoDataMakerToAave;
    address internal immutable _connectGelatoDataMakerToMaker;
    address internal immutable _connectGelatoDataMakerToCompound;

    constructor(
        uint256 __id,
        address __oracleAggregator,
        address __instaFeeCollector,
        address __connectGelatoDataMakerToAave,
        address __connectGelatoDataMakerToMaker,
        address __connectGelatoDataMakerToCompound
    ) {
        _id = __id;
        oracleAggregator = __oracleAggregator;
        _instaFeeCollector = __instaFeeCollector;
        _connectGelatoDataMakerToAave = __connectGelatoDataMakerToAave;
        _connectGelatoDataMakerToMaker = __connectGelatoDataMakerToMaker;
        _connectGelatoDataMakerToCompound = __connectGelatoDataMakerToCompound;
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

    // ====== ACTION TERMS CHECK ==========
    // Overriding IGelatoAction's function (optional)
    function termsOk(
        uint256, // taskReceipId
        address _dsa,
        bytes calldata _actionData,
        DataFlow,
        uint256, // value
        uint256 // cycleId
    ) public view returns (string memory) {
        uint256 vaultAId = abi.decode(_actionData[4:36], (uint256));

        if (vaultAId == 0)
            return "ConnectGelatoDataMakerToMaker: Vault A Id is not valid";
        if (!_isVaultOwner(vaultAId, _dsa))
            return "ConnectGelatoDataMakerToMaker: Vault A not owned by dsa";
        return OK;
    }

    /// @notice Entry Point for DSA.cast DebtBridge from e.g ETH-A to ETH-B
    /// @dev payable to be compatible in conjunction with DSA.cast payable target
    /// @param _vaultAId Id of the unsafe vault of the client of Vault A Collateral.
    /// @param _colToken The ETH-A collateral token.
    /// @param _makerDestVaultId Only for Maker: e.g. ETH-B vault of the client.
    /// @param _makerDestColType Only for Maker: colType of the new vault: e.g.ETH-B
    function getDataAndCastFromMaker(
        uint256 _vaultAId,
        address _colToken,
        uint256 _makerDestVaultId,
        string memory _makerDestColType
    ) external payable {
        uint256 debtAmt = _getRealisedDebt(_getMakerVaultDebt(_vaultAId));
        (address[] memory targets, bytes[] memory datas) =
            _dataFromMaker(
                _vaultAId,
                _colToken,
                DebtBridgeInputData({
                    dsa: address(this),
                    colAmt: _getMakerVaultCollateralBalance(_vaultAId),
                    colToken: _colToken,
                    debtAmt: debtAmt,
                    oracleAggregator: oracleAggregator,
                    makerDestVaultId: _makerDestVaultId,
                    makerDestColType: _makerDestColType,
                    fees: IInstaFeeCollector(_instaFeeCollector).fee(),
                    flashRoute: _getFlashLoanRoute(DAI, debtAmt)
                })
            );

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

        if (!success)
            returndata.revertWithError("ConnectGelatoDataMakerToX._cast:");
    }

    function _dataFromMaker(
        uint256 _vaultAId,
        address _colToken,
        DebtBridgeInputData memory _data
    ) internal view returns (address[] memory targets, bytes[] memory datas) {
        PROTOCOL protocol = _getDebtBridgeRoute(_data);

        require(
            protocol != PROTOCOL.NONE,
            "ConnectGelatoDataMakerToX._dataFromMaker: PROTOCOL.NONE"
        );

        targets = new address[](1);
        datas = new bytes[](1);

        if (protocol == PROTOCOL.AAVE) {
            targets[0] = _connectGelatoDataMakerToAave;
            datas[0] = _encodeGetDataAndCastMakerToAave(_vaultAId, _colToken);
        } else if (protocol == PROTOCOL.MAKER) {
            targets[0] = _connectGelatoDataMakerToMaker;
            datas[0] = _encodeGetDataAndCastMakerToMaker(
                _vaultAId,
                _data.makerDestVaultId,
                _data.makerDestColType,
                _colToken
            );
        } else {
            targets[0] = _connectGelatoDataMakerToCompound;
            datas[0] = _encodeGetDataAndCastMakerToCompound(
                _vaultAId,
                _colToken
            );
        }
    }
}
