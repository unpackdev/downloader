// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibAddress.sol";
import "./LibDiamond.sol";
import "./LibExecAccess.sol";
import "./LibExecAccounting.sol";
import "./FExec.sol";

contract ExecFacet {
    using LibAddress for address;
    using LibDiamond for address;
    using LibExecAccess for address;

    event LogExecSuccess(
        address indexed executor,
        address indexed service,
        address creditToken,
        uint256 credit,
        uint256 gasDebitInCreditToken,
        uint256 gasDebitInNativeToken
    );

    // solhint-disable function-max-lines
    // ################ Callable by Executor ################
    /// @dev * reverts if Executor overcharges users
    ///      * assumes honest executors
    ///      * verifying correct fee can be removed after staking/slashing
    ///        was introduced
    // solhint-disable-next-line code-complexity
    function exec(
        address _service,
        bytes calldata _data,
        address _creditToken
    )
        external
        returns (
            uint256 credit,
            uint256 gasDebitInNativeToken,
            uint256 gasDebitInCreditToken,
            uint256 estimatedGasUsed
        )
    {
        uint256 startGas = gasleft();

        require(msg.sender.canExec(), "ExecFacet.exec: canExec");

        credit = _execServiceCall(address(this), _service, _data, _creditToken);

        gasDebitInNativeToken = LibExecAccounting.getGasDebitInNativeToken(
            startGas,
            gasleft()
        );

        gasDebitInCreditToken = LibExecAccounting.getGasDebitInCreditToken(
            credit,
            _creditToken,
            gasDebitInNativeToken,
            LibAddress.getOracleAggregator()
        );

        require(
            credit <=
                gasDebitInCreditToken +
                    (gasDebitInCreditToken * LibExecAccess.gasMargin()) /
                    100,
            "ExecFacet.exec: Executor Overcharged"
        );

        emit LogExecSuccess(
            msg.sender,
            _service,
            _creditToken,
            credit,
            gasDebitInCreditToken,
            gasDebitInNativeToken
        );

        estimatedGasUsed = startGas - gasleft();
    }
}
