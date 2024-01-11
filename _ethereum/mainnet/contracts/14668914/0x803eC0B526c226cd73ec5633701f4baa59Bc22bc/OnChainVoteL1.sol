// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Destinations.sol";
import "./IFxStateSender.sol";
import "./UserVotePayload.sol";
import "./IEventSender.sol";

contract OnChainVoteL1 is Initializable, Ownable, Pausable, IEventSender {
    bool public _eventSend;
    Destinations public destinations;

    modifier onEventSend() {
        if (_eventSend) {
            _;
        }
    }

    function initialize() public initializer {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    }

    function vote(UserVotePayload memory userVotePayload) external whenNotPaused {
        require(msg.sender == userVotePayload.account, "INVALID_ACCOUNT");
        bytes32 eventSig = "Vote";
        encodeAndSendData(eventSig, userVotePayload);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setDestinations(address _fxStateSender, address _destinationOnL2) external override onlyOwner {
        require(_fxStateSender != address(0), "INVALID_ADDRESS");
        require(_destinationOnL2 != address(0), "INVALID_ADDRESS");

        destinations.fxStateSender = IFxStateSender(_fxStateSender);
        destinations.destinationOnL2 = _destinationOnL2;

        emit DestinationsSet(_fxStateSender, _destinationOnL2);
    }

    function setEventSend(bool _eventSendSet) external override onlyOwner {
        require(destinations.destinationOnL2 != address(0), "DESTINATIONS_NOT_SET");
        
        _eventSend = _eventSendSet;

        emit EventSendSet(_eventSendSet);
    }

    function encodeAndSendData(bytes32 _eventSig, UserVotePayload memory userVotePayload)
        private
        onEventSend
    {
        require(address(destinations.fxStateSender) != address(0), "ADDRESS_NOT_SET");
        require(destinations.destinationOnL2 != address(0), "ADDRESS_NOT_SET");

        bytes memory data = abi.encode(_eventSig, abi.encode(userVotePayload));

        destinations.fxStateSender.sendMessageToChild(destinations.destinationOnL2, data);
    }
}
