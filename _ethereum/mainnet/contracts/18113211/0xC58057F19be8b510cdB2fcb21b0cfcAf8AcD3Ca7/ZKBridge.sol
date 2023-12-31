// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

import "./RLPReader.sol";
import "./BytesLib.sol";
import "./IZKBridgeReceiver.sol";
import "./IZKBridge.sol";
import "./IMptVerifier.sol";
import "./IBlockUpdater.sol";

contract ZKBridge is Initializable, OwnableUpgradeable, IZKBridge {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;
    using BytesLib for bytes;

    event SetFee(uint16 dstChainId, uint256 fee);

    event ClaimFee(address operator, uint256 amount);

    event SetTrustedRemoteAddress(uint16 chainId, address remoteAddress);

    event SetMptVerifier(uint16 chainId, address mptVerifier);

    event SetBlockUpdater(uint16 chainId, address lockUpdater);

    bytes32 public constant MESSAGE_TOPIC = 0xb8abfd5c33667c7440a4fc1153ae39a24833dbe44f7eb19cbe5cd5f2583e4940;

    uint16 public chainId;

    // chainId => mptVerifierAddress
    mapping(uint16 => IMptVerifier) public mptVerifiers;

    // chainId => blockUpdaterAddress
    mapping(uint16 => IBlockUpdater) public blockUpdaters;

    mapping(bytes32 => uint64) public targetNonce;

    // chainId => zkBridgeAddress
    mapping(uint16 => address) public trustedRemoteLookup;

    mapping(bytes32 => bool) public completedTransfers;

    mapping(uint16 => uint256) public fees;

    struct LogMessage {
        uint16 dstChainId;
        uint64 nonce;
        address dstAddress;
        address srcAddress;
        address srcZkBridge;
        bytes payload;
    }

    struct Payload {
        uint16 srcChainId;
        uint16 dstChainId;
        address srcAddress;
        address dstAddress;
        uint64 nonce;
        bytes uaPayload;
    }


    function initialize(uint16 _chainId) public initializer {
        __Ownable_init();
        chainId = _chainId;
    }

    function send(
        uint16 _dstChainId,
        address _dstAddress,
        bytes memory _payload
    ) external payable returns (uint64 currentNonce) {
        require(_dstChainId != chainId, "ZKBridge:Cannot send to same chain");
        require(msg.value >= _estimateFee(_dstChainId), "ZKBridge:insufficient Fee");
        currentNonce = _useNonce(msg.sender, _dstChainId, _dstAddress);
        emit MessagePublished(msg.sender, _dstChainId, currentNonce, _dstAddress, _payload);
    }

    function validateTransactionProof(
        uint16 _srcChainId,
        bytes32 _srcBlockHash,
        uint256 _logIndex,
        bytes calldata _mptProof
    ) external {
        IMptVerifier mptVerifier = mptVerifiers[_srcChainId];
        IBlockUpdater blockUpdater = blockUpdaters[_srcChainId];
        require(address(mptVerifier) != address(0), "ZKBridge:MptVerifier is not set");
        require(address(blockUpdater) != address(0), "ZKBridge:Block Updater is not set");

        IMptVerifier.Receipt memory receipt = mptVerifier.validateMPT(_mptProof);
        require(receipt.state == 1, "ZKBridge:Source Chain Transaction Failure");
        require(blockUpdater.checkBlock(_srcBlockHash, receipt.receiptHash), "ZKBridge:Block Header is not set");

        LogMessage memory logMessage = _parseLog(receipt.logs, _logIndex);
        require(
            logMessage.srcZkBridge == trustedRemoteLookup[_srcChainId],
            "ZKBridge:Destination chain is not a trusted sourcee"
        );
        require(logMessage.dstChainId == chainId, "ZKBridge:Invalid destination chain");

        bytes32 hash = keccak256(
            abi.encode(_srcChainId, logMessage.srcAddress, logMessage.dstAddress, logMessage.nonce)
        );
        require(!completedTransfers[hash], "ZKBridge:Message already executed.");
        completedTransfers[hash] = true;

        IZKBridgeReceiver(logMessage.dstAddress).zkReceive(
            _srcChainId,
            logMessage.srcAddress,
            logMessage.nonce,
            logMessage.payload
        );
        emit ExecutedMessage(
            logMessage.srcAddress,
            _srcChainId,
            logMessage.nonce,
            logMessage.dstAddress,
            logMessage.payload
        );
    }

    function _useNonce(
        address _emitter,
        uint16 _dstChainId,
        address _dstAddress
    ) internal returns (uint64 currentNonce) {
        bytes32 hash = keccak256(abi.encode(_emitter, _dstChainId, _dstAddress));
        currentNonce = targetNonce[hash];
        targetNonce[hash]++;
    }

    function _parseLog(bytes memory _logsByte, uint256 _logIndex) internal pure returns (LogMessage memory logMessage) {
        RLPReader.RLPItem[] memory logs = _logsByte.toRlpItem().toList();
        if (_logIndex != 0) {
            require(logs.length > _logIndex + 2, "ZKBridge:Invalid proof");
            logs = logs[_logIndex + 2].toRlpBytes().toRlpItem().toList();
        }
        RLPReader.RLPItem[] memory topicItem = logs[1].toRlpBytes().toRlpItem().toList();
        bytes32 topic = bytes32(topicItem[0].toUint());
        if (topic == MESSAGE_TOPIC) {
            logMessage.srcZkBridge = logs[0].toAddress();
            logMessage.srcAddress = abi.decode(topicItem[1].toBytes(), (address));
            logMessage.dstChainId = uint16(topicItem[2].toUint());
            logMessage.nonce = uint64(topicItem[3].toUint());
            (logMessage.dstAddress, logMessage.payload) = abi.decode(logs[2].toBytes(), (address, bytes));
        }
    }

    function _estimateFee(uint16 _dstChainId) internal view returns (uint256 bridgeFee) {
        bridgeFee = fees[_dstChainId];
    }

    function estimateFee(uint16 _dstChainId) external view returns (uint256 bridgeFee) {
        bridgeFee = _estimateFee(_dstChainId);
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setFee(uint16 _dstChainId, uint256 _fee) public onlyOwner {
        fees[_dstChainId] = _fee;
        emit SetFee(_dstChainId, _fee);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, address _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = _remoteAddress;
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function setMptVerifier(uint16 _chainId, address _mptVerifier) external onlyOwner {
        require(_mptVerifier != address(0), "ZKBridge:Zero address");
        mptVerifiers[_chainId] = IMptVerifier(_mptVerifier);
        emit SetMptVerifier(_chainId, _mptVerifier);
    }

    function setBlockUpdater(uint16 _chainId, address _blockUpdater) external onlyOwner {
        require(_blockUpdater != address(0), "ZKBridge:Zero address");
        blockUpdaters[_chainId] = IBlockUpdater(_blockUpdater);
        emit SetBlockUpdater(_chainId, _blockUpdater);
    }

    function claimFees() external onlyOwner {
        emit ClaimFee(msg.sender, address(this).balance);
        payable(owner()).transfer(address(this).balance);
    }

    fallback() external payable {
        revert("ZKBridge:unsupported");
    }

    receive() external payable {
        revert("ZKBridge:the ZkBridge contract does not accept assets");
    }
}
