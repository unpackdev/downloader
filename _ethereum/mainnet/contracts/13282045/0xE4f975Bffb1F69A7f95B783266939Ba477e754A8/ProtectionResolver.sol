// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./GelatoString.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IProtocolDataProvider.sol";
import "./IProtectionAction.sol";
import "./CAave.sol";
import "./CAaveServices.sol";
import "./SProtection.sol";
import "./FProtection.sol";
import "./FProtectionResolver.sol";

contract ProtectionResolver {
    using GelatoString for string;
    IProtectionAction public immutable protectionAction;

    constructor(IProtectionAction _protectionAction) {
        protectionAction = _protectionAction;
    }

    function multiRepayAndFlashBorrowAmt(
        RepayAndFlashBorrowData[] calldata _listRAndWAmt
    ) external view returns (RepayAndFlashBorrowResult[] memory) {
        RepayAndFlashBorrowResult[]
            memory results = new RepayAndFlashBorrowResult[](
                _listRAndWAmt.length
            );

        for (uint256 i = 0; i < _listRAndWAmt.length; i++) {
            try this.getRepayAndFlashBorrowAmt(_listRAndWAmt[i]) returns (
                RepayAndFlashBorrowResult memory rAndWResult
            ) {
                results[i] = rAndWResult;
            } catch Error(string memory error) {
                results[i] = RepayAndFlashBorrowResult({
                    id: _listRAndWAmt[i].id,
                    amtToFlashBorrow: 0,
                    amtOfDebtToRepay: 0,
                    message: error.prefix(
                        "ProtectionResolver.getRepayAndFlashBorrowAmt failed:"
                    )
                });
            } catch {
                results[i] = RepayAndFlashBorrowResult({
                    id: _listRAndWAmt[i].id,
                    amtToFlashBorrow: 0,
                    amtOfDebtToRepay: 0,
                    message: "ProtectionResolver.getRepayAndFlashBorrowAmt failed:undefined"
                });
            }
        }

        return results;
    }

    // solhint-disable-next-line function-max-lines
    function getRepayAndFlashBorrowAmt(
        RepayAndFlashBorrowData calldata _rAndWAmtData
    ) external view returns (RepayAndFlashBorrowResult memory) {
        return
            _getRepayAndFlashBorrowAmt(
                _rAndWAmtData,
                ILendingPool(LENDINGPOOL),
                ILendingPoolAddressesProvider(LENDINGPOOL_ADDRESSES_PROVIDER)
            );
    }

    function multiCanExecute(CanExecData[] calldata _canExecDatas)
        external
        view
        returns (CanExecResult[] memory)
    {
        CanExecResult[] memory results = new CanExecResult[](
            _canExecDatas.length
        );

        for (uint256 i = 0; i < _canExecDatas.length; i++) {
            try this.canExecute(_canExecDatas[i]) returns (
                CanExecResult memory canExecResult
            ) {
                results[i] = canExecResult;
            } catch Error(string memory error) {
                results[i] = CanExecResult({
                    id: _canExecDatas[i].id,
                    isPositionUnSafe: false,
                    isATokenAllowed: false,
                    message: error.prefix(
                        "ProtectionResolver.canExecute failed:"
                    )
                });
            } catch {
                results[i] = CanExecResult({
                    id: _canExecDatas[i].id,
                    isPositionUnSafe: false,
                    isATokenAllowed: false,
                    message: "ProtectionResolver.canExecute failed:undefined"
                });
            }
        }

        return results;
    }

    function canExecute(CanExecData calldata _canExecData)
        external
        view
        returns (CanExecResult memory result)
    {
        (uint256 currentATokenBalance, , , , , , , , ) = IProtocolDataProvider(
            PROTOCOL_DATA_PROVIDER
        ).getUserReserveData(_canExecData.colToken, _canExecData.user);

        result.id = _canExecData.id;
        result.isPositionUnSafe = _isPositionUnsafe(
            _canExecData.user,
            _canExecData.minimumHF
        );
        result.isATokenAllowed = _isAllowed(
            ILendingPool(LENDINGPOOL)
                .getReserveData(_canExecData.colToken)
                .aTokenAddress,
            _canExecData.user,
            _canExecData.spender,
            currentATokenBalance
        );
        result.message = OK;
    }
}
