// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

// https://street-machine.com
// https://t.me/streetmachine_erc
// https://twitter.com/erc_arcade

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./IRNG.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IConsole.sol";
import "./Types.sol";
import "./ICaller.sol";
import "./console.sol";

contract RNG is VRFConsumerBaseV2, IRNG, Ownable, ReentrancyGuard {
    error UnauthorizedCaller(address _caller);
    error UnknownRequestId(uint256 _requestId);

    VRFCoordinatorV2Interface vrfCoord;
    LinkTokenInterface link;
    uint64 private _vrfSubscriptionId;
    bytes32 private _vrfKeyHash;
    uint16 private _vrfNumBlocks = 3;
    uint32 private _vrfCallbackGasLimit = 600000;

    address public airnode;
    bytes32 public endpointIdUint256;
    bytes32 public endpointIdUint256Array;
    address public sponsorWallet;

    mapping (uint256 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping (uint256 => address) public callers;
    mapping (address => bool) public callerWhitelist;

    IConsole public immutable gameConsole;

    event RequestedUint256(uint256 indexed requestId);
    event ReceivedUint256(uint256 indexed requestId, uint256 response);
    event RequestedUint256Array(uint256 indexed requestId, uint256 size);
    event ReceivedUint256Array(uint256 indexed requestId, uint256[] response);

    modifier onlyCaller() {
        if (!callerWhitelist[msg.sender]) {
            Types.Game memory _Game = gameConsole.getGameByImpl(msg.sender);
            if (address(0) == _Game.impl || !_Game.live || _Game.date == 0) {
                revert UnauthorizedCaller(msg.sender);
            }
        }
        _;
    }

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _console) VRFConsumerBaseV2(_vrfCoordinator) {

        vrfCoord = VRFCoordinatorV2Interface(_vrfCoordinator);
        _vrfSubscriptionId = _subscriptionId;
        _vrfKeyHash = _keyHash;
        gameConsole = IConsole(_console);
        callerWhitelist[msg.sender] = true;
    }

    function console() external view returns(IConsole) {
        return gameConsole;
    }
    function makeRequestUint256() external onlyCaller returns (uint256) {
        uint256 requestId = vrfCoord.requestRandomWords(
            _vrfKeyHash,
            _vrfSubscriptionId,
            _vrfNumBlocks,
            _vrfCallbackGasLimit,
            uint16(1)
        );
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        callers[requestId] = msg.sender;
        emit RequestedUint256(requestId);
        return requestId;
    }


    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal
    override
    {
        if (!expectingRequestWithIdToBeFulfilled[requestId]) {
            revert UnknownRequestId(requestId);
        }
        console.log("Fulfilling", requestId);
        expectingRequestWithIdToBeFulfilled[requestId] = false;
        ICaller(callers[requestId]).fulfillRNG(requestId, randomWords);
        emit ReceivedUint256Array(requestId, randomWords);
    }

    /// @notice Requests a `uint256[]`
    /// @param size Size of the requested array
    function makeRequestUint256Array(uint256 size) external onlyCaller returns (uint256) {
        uint256 requestId = vrfCoord.requestRandomWords(
            _vrfKeyHash,
            _vrfSubscriptionId,
            _vrfNumBlocks,
            _vrfCallbackGasLimit,
            uint32(size)
        );
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        callers[requestId] = msg.sender;
        console.log("RNG REQ", requestId);
        emit RequestedUint256Array(requestId, size);
        return requestId;
    }


    function setRequestParameters(address _airnode, bytes32 _endpointIdUint256, bytes32 _endpointIdUint256Array, address _sponsorWallet) external nonReentrant onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsorWallet = _sponsorWallet;
    }

    function setCallerWhitelist(address _caller, bool _isWhitelisted) external nonReentrant onlyOwner {
        callerWhitelist[_caller] = _isWhitelisted;
    }

    function getSponsorWallet() external view returns (address) {
        return sponsorWallet;
    }
}