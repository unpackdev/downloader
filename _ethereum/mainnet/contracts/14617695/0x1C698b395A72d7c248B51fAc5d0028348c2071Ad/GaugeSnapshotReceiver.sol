//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";

contract GaugeSnapshotReceiver is Ownable {
    mapping(address => Snapshot[]) public snapshots;
    uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);
    address public ethereumSenderAddress;

    struct Snapshot {
        address gaugeAddress;
        uint256 timestamp;
        uint256 totalSupply;
    }

    function updateEthereumSenderAddress(address _ethereumSenderAddress) public onlyOwner {
        ethereumSenderAddress = _ethereumSenderAddress;
    }

    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        l2Address = address(uint160(l1Address) + offset);
    }

    function setSnapshots(Snapshot[] calldata newSnapshots) public {
        require(msg.sender == applyL1ToL2Alias(ethereumSenderAddress), "Unauthorized");

        for (uint i = 0; i < newSnapshots.length; ++i)
            snapshots[newSnapshots[i].gaugeAddress].push(newSnapshots[i]);
    }
}