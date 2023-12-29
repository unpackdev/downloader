// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

contract NftBridgeInterface {
    uint256 private constant MAX_LOCK = 4 * 52 * 1 weeks;
    uint256 public voteDelay;

    address public voter;   
    address public ve;
    address public ve_dist;
    address[] public crosschainDistributor; // Crosschain SOLID Emission Distributor
    
    int256[] public voteWeights; // Will just be [10000] 100% vote for reward distributor
    uint256[] public chains; // Our chains array, push when goverances adds a new chain
    uint256 public masterTokenId; // The NFT ID we pass in intitialize
    uint256 public totalBridgedBase; // Total bridged base, will differ from our locked supply because we claim emissions
    uint256 public totalShares;
    
    bool public paused;

    /// Structs
    struct UserInfo { 
        address ownerOf;
        uint256 amount;
    }

    struct UserData {
        uint256 bridgedTotal;
        uint256 shares;
        uint256 bridgedOutPeriod;
        mapping (uint256 => uint256) chainBalances;
    }

    struct ChainMap {
        string axelar;
        uint64 ccip;
        uint16 lz;
    }

    /// Mappings
    mapping (uint256 => address) public childChainVe; // ChainId -> ChildChain Ve contract which handles NFT
    mapping (uint256 => ChainMap) public chainMap; // Axelar, CCIP and LZ use different names for chains
    mapping (address => mapping(uint256 => UserData)) public userData; // Map the user to NFTs to their UserData
    mapping (uint256 => address) public ownerOf; // Map user to bridged NFT  ID. 
    mapping (uint256 => uint256) public chainBalances; // ChainId -> Locked Solid Balance in Total
    mapping (bytes32 => bytes) public errors; // Map bridge errors to errorId of error. 
    mapping (uint256 => bool) public isPaused; // Is chain paused?
    mapping(address => bool) public isOperator;

    event ChildChainVeAdded(uint256 indexed chainId, address ve);
    event VoteDelaySet(uint256 delay);
    event NftBridged(address indexed user, uint256 indexed tokenId, uint256 indexed chainId, uint256 amount);
    event NftClaimed(address indexed user, uint256 indexed oldTokenId, uint256 indexed newTokenId, uint256 amount);
    event NftBurned(address indexed user, uint256 indexed tokenId, uint256 indexed chainId, uint256 amount);

    event SetOperator(address newOperator, bool status);
    
    event Error(bytes32 indexed errorId);
    event Paused();
    event Unpaused();
    event ChainPaused(uint256 indexed chainId);
    event ChainUnpaused(uint256 indexed chainId);

    function initialize (
        address _axelarGateway,
        address _axelarGasService,
        address _ccipRouter,
        address _lzEndpoint,
        address _voter, 
        address _ve, 
        address _ve_dist,
        address _crosschainDistributor,
        uint256 _tokenId
    ) external {}



    // Pass an array of Child Chain IDs
    function supportedChains() external view returns (uint256[] memory _chains) {}

    // Total underlying Solid locked in master veNFT
    function totalLocked() public view returns (uint256) {}

    // Public claim of veRebase
    function claimVeRebase() external {}

    function claimNft(uint256 _tokenId) external {}

    // Can only vote once, should be done right before epoch end so we set delay attached to activePeriod on voter. 
    function vote() external {}

    // public increase of unlockTime
    function increaseUnlockTime() public {}

    function lockInfo() public view returns (uint256 endTime, uint256 secondsRemaining, bool shouldIncreaseLock) {}

    // Trusted bridging services
    //function getAxelarGateway() public view returns (address) {}
    //function getAxelarGasService() public view returns (address) {}
    //function getCcipRouter() public view returns (address) {}
    //function getLzEndpoint() public view returns (address) {}
   
    /** 
    * @notice Main Bridge NFT Function
    * @param _to = Address to receive NFTs on child chains
    * @param _chainIds = ChainID Array of bridge to chains
    * @param _tokenId = User NFT TokenId
    * @param _amounts = How much of their NFT is used for each chain
    * @param _feeInEther = We have to calc the calldata cost from anycall contract, have the user pay that in ETH for execution. 
    */
    function bridgeOutNft(
        address _to, 
        uint256[] calldata _chainIds, 
        uint256 _tokenId, 
        uint256[] calldata _amounts, 
        uint256[][] calldata _feeInEther
    ) external payable {}

    
    /**
    * @notice Configure Weights NFT Function. Must have burned all child chain nfts first. 
    * @param _to = Address to receive NFTs on child chains
    * @param _chainIds = ChainID Array of bridge to chains
    * @param _tokenId = User NFT TokenId
    * @param _amounts = How much of their NFT is used for each chain
    * @param _feeInEther = We have to calc the calldata cost from anycall contract, have the user pay that in ETH for execution. 
    */
    function configureChildChainWeights(
        address _to, 
        uint256[] calldata _chainIds, 
        uint256 _tokenId, 
        uint256[] calldata _amounts, 
        uint256[][] calldata _feeInEther
    ) external payable {}


    // If there is an error, hopefully wont/shouldnt happen. We can retry processing the data. 
    function retryError(uint256 _timestamp) external {}

    /// Setters /// 
    function setChildChainVe(uint256 _chainId, address _ve, bool _init) external {}
    function addChainMap(uint256 chainId, address _ve, string memory axelar, uint64 ccip, uint16 lz) external {}

    function setOperator(address _operator, bool _status) external {}
    function setVoteDelay(uint256 _delay) external {}
    function setPaused(bool _status) external {}

    // Trusted Bridging Services
    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external {}
    //function setAxelarGateway(address _axelarGateway) external {}
    //function setAxelarGasService(address _axelarGasService) external {}
    //function setCcipRouter(address _ccipRouter) external {}
    //function setLzEndpoint(address _lzEndpoint) external {}

    /// Pause chain, stop bridging NFT and reallocate solid to all other chains
    function pauseChain(uint256 _chainId) external {}
    function unpauseChain(uint256 _chainId) external {}

    function rescueNft(uint256 _tokenId, bool _status) external {}

    function isBridged(address _owner, uint256 _tokenId) external view returns(bool) {}
    function ownedNfts(address _owner) external view returns(uint256[] memory _nftIds) {}
}