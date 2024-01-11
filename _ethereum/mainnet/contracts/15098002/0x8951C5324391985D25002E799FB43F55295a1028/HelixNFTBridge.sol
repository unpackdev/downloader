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
        Create,
        Pendding,
        Bridged,
        Burned
    }

    struct BridgeFactory {
        address user;                   // owner of Ethereum NFT
        string encryptExternalID;           // mint tokenIDs on Solana
        string[] nftIDs;                // label IDs on Solana
        string tokenURI;                // tokenURIs on Solana : Ethereum NFT's TokenURI will be tokenURIs[0]
        BridgeStatus bridgeStatus;      // bridge status
    }

    /// bridgeFactoryId => BridgeFactory
    mapping(uint256 => BridgeFactory) public bridgeFactories;

    /// user -> bridgeFactoryIDs[]
    mapping(address => uint256[]) public bridgeFactoryIDs;
    
    mapping(string => bool) private _wrappedNftIDs;

    /// for counting whenever add bridge once approve on solana 
    /// if it's down to 0, will call to remove bridger
    /// user => counts
    mapping(address => uint256) private _countAddBridge;
 
    address public admin;

    uint256 public gasFeeToAdmin;

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
        string uri
    );

    // Emitted when tokens are bridged to Solana
    event BridgeToSolana(
        string externalRecipientAddr, 
        string encryptExternalID
    );

    // Emitted when a bridger is added
    event AddBridger(
        address indexed bridger,
        string encryptExternalID,
        uint256 newBridgeFactoryId
    );
    
    // Emitted when a user create wrap
    event Wrap(address indexed user, uint256 newBridgeFactoryId);

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

    constructor(HelixNFT _helixNFT, address _admin, uint256 _gasFeeToAdmin) {
        helixNFT = _helixNFT;
        admin = _admin;
        gasFeeToAdmin = _gasFeeToAdmin;
    }
    
    function wrap(string memory _encryptExternalID, string[] calldata _nftIDs, string memory _tokenURI) 
      external
      whenNotPaused
      payable
    {
        address _user = msg.sender;
        require(_nftIDs.length != 0, "HelixNFTBridge:Not Array");
        
        require(msg.value >= gasFeeToAdmin, "HelixNFTBridge:Insufficient Amount to send Fee to Admin");
        (bool success, ) = payable(admin).call{value: gasFeeToAdmin}("");
        require(success, "HelixNFTBridge:receiver rejected ETH transfer");

        uint256 length = _nftIDs.length;
        for (uint256 i = 0; i < length; i++) {
            string memory _nftID = _nftIDs[i];
            require(!_wrappedNftIDs[_nftID], "HelixNFTBridge:Already Wrapped token");
            _wrappedNftIDs[_nftID] = true;
        }
        string[] memory _newNftIDs = new string[](length);
        _newNftIDs = _nftIDs;
        
        uint256 _bridgeFactoryId = ++bridgeFactoryLastId;
        BridgeFactory storage _factory = bridgeFactories[_bridgeFactoryId];
        _factory.user = _user;
        _factory.bridgeStatus = BridgeStatus.Create;
        _factory.encryptExternalID = _encryptExternalID;
        _factory.nftIDs = _newNftIDs;
        _factory.tokenURI = _tokenURI;
        // Relay the bridge id to the user's account
        bridgeFactoryIDs[_user].push(_bridgeFactoryId);

        emit Wrap(_user, _bridgeFactoryId);
    }

    function getCreatedFactoryIdByUser(address _user, string memory _encryptExternalID) 
      external
      view
      returns(uint256)
    {
        uint256[] memory _factoryIDs = bridgeFactoryIDs[_user];
        uint256 length = _factoryIDs.length;
        for (uint256 i = 0; i < length; i++) {
            BridgeFactory memory _factory = bridgeFactories[_factoryIDs[i]];
            if (_factory.bridgeStatus == BridgeStatus.Create && compareStringsbyBytes(_factory.encryptExternalID, _encryptExternalID)) {
                return _factoryIDs[i];
            }
        }
        return 0;
    }

    function compareStringsbyBytes(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function addBridgeFactory(uint256 _bridgeFactoryId)
      external 
      onlyOwner
      whenNotPaused
    {
        BridgeFactory storage _bridgeFactory = bridgeFactories[_bridgeFactoryId];
        _bridgeFactory.bridgeStatus = BridgeStatus.Pendding;
        address _user = _bridgeFactory.user;
        _countAddBridge[_user]++;
        EnumerableSet.add(_bridgers, _user);
        emit AddBridger(_user, _bridgeFactory.encryptExternalID, _bridgeFactoryId);
    }
    /**
     * @dev This function is called ONLY by bridgers to bridge the token to Ethereum
     */
    function bridgeToEthereum(uint256 _bridgeFactoryId)
      external
      onlyBridger
      whenNotPaused
    {
        address _user = msg.sender;
        require(_countAddBridge[_user] > 0, "HelixNFTBridge: You are not a Bridger");
        BridgeFactory memory _bridgeFactory = bridgeFactories[_bridgeFactoryId];

        require(_bridgeFactory.user == _user, "HelixNFTBridge:Not a bridger");
        require(_bridgeFactory.bridgeStatus == BridgeStatus.Pendding, "HelixNFTBridge:Already bridged factory");

        _countAddBridge[_user]--;
        bridgeFactories[_bridgeFactoryId].bridgeStatus = BridgeStatus.Bridged;
        // Ethereum NFT's TokenURI is first URI of wrapped geobots
        string memory tokenURI = _bridgeFactory.tokenURI;
        uint256 length = _bridgeFactory.nftIDs.length;
        string[] memory _externalIDs = new string[](length);
        helixNFT.mintExternal(_user, _externalIDs, _bridgeFactory.nftIDs, tokenURI, _bridgeFactoryId);

        if (_countAddBridge[_user] == 0) 
            _delBridger(_user);
        emit BridgeToEthereum(_user, tokenURI);
    }

    function getGasFeeToAdmin() external view returns (uint256) {
        return gasFeeToAdmin;
    }
    
    function getBridgeFactoryIDs(address _user) external view returns (uint256[] memory) {
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
        return _wrappedNftIDs[_externalTokenID];
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

    function setGasFeeToAdmin(uint256 _gasFeeToAdmin) external onlyOwner {
        gasFeeToAdmin = _gasFeeToAdmin;
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
        string[] memory _nftIDs = _bridgeFactory.nftIDs;
        uint256 length = _nftIDs.length;
        for (uint256 i = 0; i < length; i++) {
            string memory _nftID = _nftIDs[i];
            require(_wrappedNftIDs[_nftID], "HelixNFTBridge: already bridged to Solana");
            _wrappedNftIDs[_nftID] = false;
        }
        _bridgeFactory.bridgeStatus = BridgeStatus.Burned;

        helixNFT.burn(_tokenId);
        emit BridgeToSolana(_externalRecipientAddr, _bridgeFactory.encryptExternalID);
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
