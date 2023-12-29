// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

contract SolidBridgeInterface {

    // Public variables from SolidBridge
    address public base;
    uint256 public nonce;
    address public crosschainDistributor;
    address public minter;
    uint256 public bridgedBase;
    bool public paused;

    // Public variables from SolidSync
    uint256[] public chains;
    uint256 public pausedChains;

    // Structs from SolidSync
    struct ChainMap {
        string axelar;
        uint64 ccip;
        uint16 lz;
    }

    //struct MessageStatus {
    //    bytes32 axelarData;
    //    bytes32 ccipData;
    //    bytes32 lzData;
    //}

    // Mappings from SolidBridge
    mapping(address => bool) public isOperator;

    // Mappings from SolidSync
    mapping (uint256 => address) public solidBridgeMap;
    mapping (uint256 => ChainMap) public chainMap;
    //mapping(uint256 => mapping(uint256 => MessageStatus)) public messageStatus;
    mapping (bytes32 => bytes) public errors;
    mapping (uint256 => bool) public isPaused;

    // Functions from SolidBridge
    function initialize (
        address _axelarGateway,
        address _axelarGasService,
        address _ccipRouter,
        address _lzEndpoint,
        address _crosschainDistributor,
        address _minter,
        address _base
    ) external {}

    function bridgeSolidOut(
        address _recipient,
        uint256 _chainId,
        uint256 _amount,
        uint256[] calldata _feeInEther
    ) external payable {}
    
    function pauseBridge() external {}
    function unpauseBridge() external {}
    function pauseChain(uint256 _chainId) external {}
    function unpauseChain(uint256 _chainId) external {}
    function rescueAssets(address _to, address _token, uint256 _amount) external {}

    // Functions from SolidSync
    function retryError(bytes32 _errorId, uint256 _chainId) external {}
    //function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory data) external {}
    //function setAxelarGateway(address _axelarGateway) external {}
    //function setAxelarGasService(address _axelarGasService) external {}
    //function setCcipRouter(address _ccipRouter) external {}
    //function setLzEndpoint(address _lzEndpoint) external {}
    function addChainMap(uint256 _chainId, address _remoteSolidBridge, string memory _axelar, uint64 _ccip, uint16 _lz) external {}
    function setRemoteSolidBridge(uint256 _chainId, address _remoteSolidBridge) external {}

    // View Functions from SolidSync
    //function getAxelarGateway() external view returns (address) {}
    //function getAxelarGasService() external view returns (address) {}
    //function getCcipRouter() external view returns (address) {}
    //function getLzEndpoint() external view returns (address) {}
    function supportedChains() external view returns (uint256[] memory _chains) {}

    // Events from SolidBridge
    event SolidBridgedOut(address indexed sender, address indexed recipient, uint256 indexed chainId, uint256 amount, uint256 nonce);
    event SolidEmissionsBridgedOut(address indexed sender, address indexed recipient, uint256 indexed chainId, uint256 amount, uint256 nonce);
    event SolidBridgedIn(address indexed recipient, uint256 indexed chainId, uint256 amount);
    event Paused();
    event Unpaused();

    // Events from SolidSync
    event SolidBridgeAdded(uint256 indexed chainId, address solidBridge);
    event SetOperator(address newOperator, bool status);
    event Error(bytes32 indexed errorId, uint256 indexed chainId);
    event ChainPaused(uint256 indexed chainId);
    event ChainUnpaused(uint256 indexed chainId);

    // Some LZ NBA stuff
    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external {}
    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {}
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);
}