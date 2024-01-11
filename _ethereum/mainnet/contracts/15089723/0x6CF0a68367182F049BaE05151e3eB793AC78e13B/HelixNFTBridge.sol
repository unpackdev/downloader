// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./HelixNFT.sol";

import "./Pausable.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";

/**
 * HelixNFTBridge is responsible for many things related to NFT Bridging from-/to-
 * Solana blockchain. Here's the full list:
 *  - allow Solana NFT to be minted on Ethereum (bridgeFromSolana)
 */
contract HelixNFTBridge is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Bridge status determines
     *  0: pendding status, so when the BridgeServer adds BridgedToken
     *  1: after minted the Ethereum NFT
     */
    enum BridgeStatus {
        Pendding,
        Bridged,
        Burned
    }

    struct BridgeFactory {
        address user;                   // owner of Ethereum NFT
        string[] externalIDs;           // mint tokenIDs on Solana
        string[] nftIDs;                // label IDs on Solana
        string tokenURI;                // tokenURIs on Solana : Ethereum NFT's TokenURI will be tokenURIs[0]
        BridgeStatus bridgeStatus;      // bridge status
        uint256 consumeGas;             // consume Gas Fee to call factory function by admin, users should pay this gas fee
    }

    /// bridgeFactoryId => BridgeFactory
    mapping(uint256 => BridgeFactory) public bridgeFactories;

    /// user -> bridgeFactoryIDs[]
    mapping(address => uint[]) public bridgeFactoryIDs;
    
    /// ethereum NFT tokenId -> true/false
    mapping(uint256 => bool) private _bridgedTokenIDs;
    
    /**
     * @dev If the NFT is available on the Ethereum, then this map stores true
     * for the externalID, false otherwise.
     */
    mapping(string => bool) private _bridgedExternalTokenIDs;

    /// for counting whenever add bridge once approve on solana 
    /// if it's down to 0, will call to remove bridger
    /// user => counts
    mapping(address => uint256) private _countAddBridge;
 
    address public admin;

    uint256 public bridgeFactoryLastId;  
    /**
     * @dev Bridgers are Helix service accounts which listen to the events
     *      happening on the Solana chain and then enabling the NFT for
     *      minting / unlocking it for usage on Ethereum.
     */
    EnumerableSet.AddressSet private _bridgers;

    // Emitted when tokens are bridged to Ethereum
    event BridgeToEthereum(
        address indexed bridger,
        string[] externalTokenIds,
        string uri
    );

    // Emitted when tokens are bridged to Solana
    event BridgeToSolana(
        string externalRecipientAddr, 
        string[] externalTokenIDs
    );

    // Emitted when a bridger is added
    event AddBridger(
        address indexed bridger,
        string externalIDs,
        uint256 newBridgeFactoryId
    );
    
    // Emitted when a bridger is deleted
    event DelBridger(address indexed bridger);

    // Emitted when a new HelixNFT address is set
    event SetHelixNFT(address indexed setter, address indexed helixNFT);

    // Emitted when a new Admin address is set
    event SetAdmin(address indexed setter, address indexed admin);
    
    /**
     * @dev HelixNFT contract    
     */
    HelixNFT helixNFT;

    constructor(HelixNFT _helixNFT, address _admin) {
        helixNFT = _helixNFT;
        admin = _admin;
    }
    
    function addBridgeFactory(address _user, string[] calldata _externalIDs, string[] calldata _nftIDs, string memory _tokenURI, uint256 _consumeGas)
      external 
      onlyOwner
    {
        require(_user != address(0), "HelixNFTBridge:Zero Array");
        require(_externalIDs.length != 0, "HelixNFTBridge:Not Array");
        require(_externalIDs.length == _nftIDs.length, "HelixNFTBridge:Invalid Array");
        
        uint256 length = _externalIDs.length;
        for (uint256 i = 0; i < length; i++) {
            string memory _externalID = _externalIDs[i];
            require(!_bridgedExternalTokenIDs[_externalID], "HelixNFTBridge:Already bridged token");
            _bridgedExternalTokenIDs[_externalID] = true;
        }
        string[] memory _newExternalIDs = new string[](length);
        string[] memory _newNftIDs = new string[](length);
        _newExternalIDs = _externalIDs;
        _newNftIDs = _nftIDs;
        
        uint256 _bridgeFactoryId = bridgeFactoryLastId++;
        BridgeFactory storage _factory = bridgeFactories[_bridgeFactoryId];
        _factory.user = _user;
        _factory.bridgeStatus = BridgeStatus.Pendding;
        _factory.externalIDs = _newExternalIDs;
        _factory.nftIDs = _newNftIDs;
        _factory.tokenURI = _tokenURI;
        _factory.consumeGas = _consumeGas;
        // Relay the bridge id to the user's account
        bridgeFactoryIDs[_user].push(_bridgeFactoryId);

        _countAddBridge[_user]++;
        EnumerableSet.add(_bridgers, _user);
        emit AddBridger(_user, _newExternalIDs[0], _bridgeFactoryId);
    }
    /**
     * @dev This function is called ONLY by bridgers to bridge the token to Ethereum
     */
    function bridgeToEthereum(uint256 _bridgeFactoryId)
      external
      onlyBridger
      whenNotPaused
      payable
      returns(bool) 
    {
        address _user = msg.sender;
        require(_countAddBridge[_user] > 0, "HelixNFTBridge: You are not a Bridger");
        BridgeFactory memory _bridgeFactory = bridgeFactories[_bridgeFactoryId];

        require(_bridgeFactory.user == _user, "HelixNFTBridge:Not a bridger");
        require(_bridgeFactory.bridgeStatus == BridgeStatus.Pendding, "HelixNFTBridge:Already bridged factory");

        uint256 gasFeeETH = _bridgeFactory.consumeGas;
        require(msg.value >= gasFeeETH, "HelixNFTBridge:Insufficient Gas FEE");
        (bool success, ) = payable(admin).call{value: gasFeeETH}("");
        require(success, "HelixNFTBridge:receiver rejected ETH transfer");

        _countAddBridge[_user]--;
        bridgeFactories[_bridgeFactoryId].bridgeStatus = BridgeStatus.Bridged;
        uint256 tokenId = helixNFT.getLastTokenId() + 1;
        _bridgedTokenIDs[tokenId] = true;
        // Ethereum NFT's TokenURI is first URI of wrapped geobots
        string memory tokenURI = _bridgeFactory.tokenURI;
        helixNFT.mintExternal(_user, _bridgeFactory.externalIDs, _bridgeFactory.nftIDs, tokenURI, _bridgeFactoryId);

        if (_countAddBridge[_user] == 0) 
            _delBridger(_user);

        emit BridgeToEthereum(_user, _bridgeFactory.externalIDs, tokenURI);
        return true;
    }

    function getConsumeGas(uint256 _bridgeFactoryId) external view returns (uint256) {
        return bridgeFactories[_bridgeFactoryId].consumeGas;
    }

    function getBridgeFactoryIDs(address _user) external view returns (uint[] memory) {
        return bridgeFactoryIDs[_user];
    }

    function getBridgeFactories(address _user) external view returns (BridgeFactory[] memory) {
        uint256 length = bridgeFactoryIDs[_user].length;
        BridgeFactory[] memory _bridgeFactories = new BridgeFactory[](length);
        for (uint256 i = 0; i < length; i++) {
            _bridgeFactories[i] = bridgeFactories[bridgeFactoryIDs[_user][i]];
        }
        return _bridgeFactories;
    }

    /**
     * @dev Whether the token is bridged or not.
     */
    function isBridged(string calldata _externalTokenID) external view returns (bool) {
        return _bridgedExternalTokenIDs[_externalTokenID];
    }

    /// Called by the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// Called by the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// Called by the owner to set a new _helixNFT address
    function setHelixNFT(address _helixNFT) external onlyOwner {
        require(_helixNFT != address(0));
        helixNFT = HelixNFT(_helixNFT);
        emit SetHelixNFT(msg.sender, _helixNFT);
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0));
        admin = _admin;
        emit SetAdmin(msg.sender, admin);
    }

    /**
     * @dev Mark token as unavailable on Ethereum.
     */
    function bridgeToSolana(uint256 _tokenId, string calldata _externalRecipientAddr) 
       external 
       whenNotPaused
    {
        uint256 bridgeFactoryId = helixNFT.getBridgeFactoryId(_tokenId);
        BridgeFactory storage _bridgeFactory = bridgeFactories[bridgeFactoryId];
        require(_bridgeFactory.user == msg.sender, "HelixNFTBridge: Not owner");
        string[] memory externalTokenIDs = _bridgeFactory.externalIDs;
        uint256 length = externalTokenIDs.length;
        for (uint256 i = 0; i < length; i++) {
            string memory externalID = externalTokenIDs[i];
            require(_bridgedExternalTokenIDs[externalID], "HelixNFTBridge: already bridged to Solana");
            _bridgedExternalTokenIDs[externalID] = false;
        }
        _bridgedTokenIDs[_tokenId] = false;
        _bridgeFactory.bridgeStatus = BridgeStatus.Burned;

        helixNFT.burn(_tokenId);
        emit BridgeToSolana(_externalRecipientAddr, externalTokenIDs);
    }

    /**
     * @dev used by owner to delete bridger
     * @param _bridger address of bridger to be deleted.
     * @return true if successful.
     */
    function delBridger(address _bridger) external onlyOwner returns (bool) {
        return _delBridger(_bridger);
    }

    function _delBridger(address _bridger) internal returns (bool) {
        require(
            _bridger != address(0),
            "HelixNFTBridge: _bridger is the zero address"
        );
        emit DelBridger(_bridger);
        return EnumerableSet.remove(_bridgers, _bridger);
    }

    /**
     * @dev See the number of bridgers
     * @return number of bridges.
     */
    function getBridgersLength() public view returns (uint256) {
        return EnumerableSet.length(_bridgers);
    }

    /**
     * @dev Check if an address is a bridger
     * @return true or false based on bridger status.
     */
    function isBridger(address account) public view returns (bool) {
        return EnumerableSet.contains(_bridgers, account);
    }

    /**
     * @dev Get the staker at n location
     * @param _index index of address set
     * @return address of staker at index.
     */
    function getBridger(uint256 _index)
        external
        view
        returns (address)
    {
        require(_index <= getBridgersLength() - 1, "HelixNFTBridge: index out of bounds");
        return EnumerableSet.at(_bridgers, _index);
    }

    /**
     * @dev Modifier for operations which can be performed only by bridgers
     */
    modifier onlyBridger() {
        require(isBridger(msg.sender), "caller is not the bridger");
        _;
    }
}
