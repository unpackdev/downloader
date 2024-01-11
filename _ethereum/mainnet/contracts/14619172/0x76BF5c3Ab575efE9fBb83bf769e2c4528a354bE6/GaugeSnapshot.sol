//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./ContractWhitelist.sol";
import "./IGauge.sol";

import "./NonblockingLzApp.sol";

contract GaugeSnapshot is NonblockingLzApp, ContractWhitelist {

    struct Snapshot {
        address gaugeAddress;
        uint256 timestamp;
        uint256 totalSupply;
    }

    constructor(
        address _lzEndpoint
    ) NonblockingLzApp(_lzEndpoint) {
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory payload) internal override {
    }

    function snap(
      address[] calldata gauges
    ) public payable {
        Snapshot[] memory snapshots = new Snapshot[](gauges.length);

        for (uint i = 0; i < gauges.length; ++i)
            snapshots[i] = Snapshot(gauges[i], block.timestamp, IGauge(gauges[i]).totalSupply());
            
        _lzSend(
          10, // Arbitrum chain id
          abi.encode(snapshots), // Data to send 
          payable(msg.sender), // Refund address
          address(0x0), // ZERO token payment address (useless for now)
          bytes("") // Adapter params
        );
    }
}