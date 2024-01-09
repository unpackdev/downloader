// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./LibExecAccess.sol";
import "./FExec.sol";

contract PrepaidExecFacet {
    using LibExecAccess for address;

    event LogPrepaidExecSuccess(
        address indexed executor,
        address indexed service,
        uint256 estimatedGasAmount
    );

    function prepaidExec(address _service, bytes calldata _data)
        external
        returns (uint256 estimatedGasAmount)
    {
        uint256 startGas = gasleft();

        require(msg.sender.canExec(), "PrepaidExecFacet.prepaidExec: canExec");

        _prepaidExecServiceCall(_service, _data);

        estimatedGasAmount = startGas - gasleft();

        emit LogPrepaidExecSuccess(msg.sender, _service, estimatedGasAmount);
    }
}
