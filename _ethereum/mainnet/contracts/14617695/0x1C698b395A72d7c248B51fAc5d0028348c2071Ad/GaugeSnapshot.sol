//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IGaugeController.sol";
import "./IGauge.sol";
import "./IInbox.sol";
import "./GaugeSnapshotReceiver.sol";


contract GaugeSnapshot is Ownable {
    IInbox public inbox;

    event RetryableTicketCreated(uint256 indexed ticketId);

    struct Snapshot {
        address gaugeAddress;
        uint256 timestamp;
        uint256 totalSupply;
    }

    IGaugeController public gaugeController;
    address public arbitrumReceiverContractAddress;

    constructor(
        address _gaugeControllerAddress,
        address _inboxAddress,
        address _arbitrumReceiverContractAddress
    ) {
        gaugeController = IGaugeController(_gaugeControllerAddress);
        inbox = IInbox(_inboxAddress);
        arbitrumReceiverContractAddress = _arbitrumReceiverContractAddress;
    }

    function updateArbitrumReceiver(address _arbitrumReceiverContractAddress) public onlyOwner {
        arbitrumReceiverContractAddress = _arbitrumReceiverContractAddress;
    }

    function snap(address[] calldata _gauges, uint256 _maxSubmissionCost, uint256 _maxGas, uint256 _gasPriceBid) public payable onlyOwner {
        Snapshot[] memory snapshots = new Snapshot[](_gauges.length);

        for (uint i = 0; i < _gauges.length; ++i)
            snapshots[i] = Snapshot(_gauges[i], block.timestamp, IGauge(_gauges[i]).totalSupply());

        uint256 ticketID = inbox.createRetryableTicket{value: msg.value}(
            arbitrumReceiverContractAddress,
            0,
            _maxSubmissionCost,
            msg.sender,
            msg.sender,
            _maxGas,
            _gasPriceBid,
            abi.encodeWithSelector(GaugeSnapshotReceiver.setSnapshots.selector, snapshots)
        );

        emit RetryableTicketCreated(ticketID);
    }
}