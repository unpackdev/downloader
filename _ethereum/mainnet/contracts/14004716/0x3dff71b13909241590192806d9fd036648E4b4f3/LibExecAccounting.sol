// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./GelatoString.sol";
import "./CExec.sol";
import "./CTokens.sol";
import "./IOracleAggregator.sol";

library LibExecAccounting {
    using GelatoString for string;

    struct ExecAccountingStorage {
        uint256 maxPriorityFee;
    }

    bytes32 private constant _EXECUTOR_STORAGE_POSITION =
        keccak256("gelato.diamond.ExecAccounting.storage");

    function setMaxPriorityFee(uint256 _maxPriorityFee) internal {
        execAccountingStorage().maxPriorityFee = _maxPriorityFee;
    }

    function maxPriorityFee() internal view returns (uint256) {
        return execAccountingStorage().maxPriorityFee;
    }

    function getGasDebitInNativeToken(uint256 _gasStart, uint256 _gasEnd)
        internal
        view
        returns (uint256 gasDebitInNativeToken)
    {
        uint256 priorityFee = tx.gasprice - block.basefee;
        uint256 _maxPriorityFee = maxPriorityFee();
        uint256 cappedPriorityFee = priorityFee <= _maxPriorityFee
            ? priorityFee
            : _maxPriorityFee;

        // Does not account for gas refunds
        uint256 estimatedGasUsed = _gasStart - _gasEnd + GAS_OVERHEAD;
        gasDebitInNativeToken =
            estimatedGasUsed *
            (block.basefee + cappedPriorityFee);
    }

    function getGasDebitInCreditToken(
        uint256 _credit,
        address _creditToken,
        uint256 _gasDebitInNativeToken,
        address _oracleAggregator
    ) internal view returns (uint256 gasDebitInCreditToken) {
        if (_credit == 0) return 0;

        try
            IOracleAggregator(_oracleAggregator).getExpectedReturnAmount(
                _gasDebitInNativeToken,
                NATIVE_TOKEN,
                _creditToken
            )
        returns (uint256 gasDebitInCreditToken_, uint256) {
            require(
                gasDebitInCreditToken_ != 0,
                "LibExecAccess.getGasDebitInCreditToken:  _creditToken not on OracleAggregator"
            );
            gasDebitInCreditToken = gasDebitInCreditToken_;
        } catch Error(string memory err) {
            err.revertWithInfo(
                "LibExecAccess.getGasDebitInCreditToken: OracleAggregator:"
            );
        } catch {
            revert(
                "LibExecAccess.getGasDebitInCreditToken: OracleAggregator: unknown error"
            );
        }
    }

    function execAccountingStorage()
        internal
        pure
        returns (ExecAccountingStorage storage eas)
    {
        bytes32 position = _EXECUTOR_STORAGE_POSITION;
        assembly {
            eas.slot := position
        }
    }
}
