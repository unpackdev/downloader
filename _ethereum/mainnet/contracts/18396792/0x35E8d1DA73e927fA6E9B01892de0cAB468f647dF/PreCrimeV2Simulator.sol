// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./MessagingStructs.sol";

import "./IPreCrimeV2Simulator.sol";
import "./IPreCrimeV2.sol";

abstract contract PreCrimeV2Simulator is IPreCrimeV2Simulator {
    /// @dev a generic interface for precrime simulations
    /// @dev this function reverts at the end with the simulation results
    /// @dev value is provided as a lump sum, does not restrict how much each packet can consume
    function lzReceiveAndRevert(InboundPacket[] calldata _packets) external payable virtual override {
        this._simulateLzReceive{value: msg.value}(_packets);

        // msg.sender should be the precrime contract with the buildSimulationResult() function
        revert SimulationResult(IPreCrimeV2(msg.sender).buildSimulationResult());
    }

    function _simulateLzReceive(InboundPacket[] calldata _packets) external payable virtual {
        assert(msg.sender == address(this));

        _beforeSimulation(_packets);

        for (uint i = 0; i < _packets.length; i++) {
            // skip packet from untrusted peer
            InboundPacket calldata packet = _packets[i];
            if (!isPeer(packet.origin.srcEid, packet.origin.sender)) continue;

            _lzReceive(packet.origin, packet.guid, packet.message);
        }
    }

    function _beforeSimulation(InboundPacket[] calldata _packets) internal virtual {}

    function _lzReceive(Origin calldata _origin, bytes32 _guid, bytes calldata _message) internal virtual;

    function isPeer(uint32 _eid, bytes32 _peer) public view virtual returns (bool);

    /// @dev The simulator contract is the base contract for the OApp by default.
    /// @dev If the simulator is a separate contract, override this function.
    function oapp() external view virtual returns (address) {
        return address(this);
    }
}
