// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafe.sol";
import "./Address.sol";
import "./Multicall.sol";

contract GnosisSafeOverseen is GnosisSafe, Multicall
{
    address public overseer;

    event OverseerChanged(address overseer);
    event OverseerSelfExecution();

    function setup(
        address _overseer,
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        this.setup(_owners, _threshold, to, data, fallbackHandler, paymentToken, payment, paymentReceiver);
        this.setOverseer(_overseer);
    }

    function setOverseer(address newOverseer) external {
        require(msg.sender == (overseer == address(0) ? address(this) : overseer), "Unauthorized access");
        overseer = newOverseer;
        emit OverseerChanged(newOverseer);
    }

    function overseerSelfExecute(bytes calldata data) external {
        require(msg.sender == overseer, "Unauthorized access");
        Address.functionCall(address(this), data);
        emit OverseerSelfExecution();
    }
}
