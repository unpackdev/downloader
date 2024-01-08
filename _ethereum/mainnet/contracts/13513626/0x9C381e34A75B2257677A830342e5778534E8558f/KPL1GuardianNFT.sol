// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./VRFConsumerBase.sol";

/** 
 * @title Guardians on mainnet
 * @notice Mints and allows for cross chain transfers of the Guardian NFT
 */
contract KPL1GuardianNFT is AccessControl, ERC721URIStorage, ERC721Enumerable, VRFConsumerBase {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 constant DAO_AGENT_ROLE = keccak256("DAO_AGENT_ROLE");

    string public baseURI;
    address public daoTreasury;
    address public crossChainAdapter;
    uint public constant GUARDIAN_PRICE = 0.088 ether;
    uint public constant EARLY_PRICE = 0.0088 ether;
    uint public creationTime = block.timestamp;
    uint public messageFromTheUniverse;
    uint public chosenLeader;
    uint public currentGuardiansInThisNetwork = 88;

    bytes32 internal keyHash;
    uint256 internal fee;

    mapping(address => uint) pendingWithdrawals;
    mapping(address => bool) guardians;
    mapping(uint => uint16) guardianAttributes;
    mapping(address => bool) earlyBirds;
    
    event SetEarlyBirds(address[], uint);
    event SetEarlyBird(address, bool);
    event SetCrossChainAdapter(address);
    event SetChainlinkFee(uint256);
    event SetChainlinkKeyHash(bytes32);
    event SetFee(address);
    event SetBaseURI(string);
    event SetDAOTreasury(address);
    event etherealMessageReceived(uint);
    event SetAttributes(uint, uint16);

    constructor(address _daoTreasury) 
        ERC721("Kitty Party Guardian", "KPG")
        VRFConsumerBase
        (
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) 
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO_AGENT_ROLE, _daoTreasury);
        daoTreasury = _daoTreasury;
    }

    modifier onlyAfterCrossChainActive() {
        require(block.timestamp >= creationTime + 58 days, "Cross Chain Mint not active yet!");
        _;
    }

    modifier onlyCrossChainAdapter() {
        require(msg.sender == crossChainAdapter, "Only cross chain adapter can mint!");
        _;
    }

    function awakenGuardian() external payable {
        require(totalSupply() < 87);
        require(block.timestamp > 1635552000);
        require(balanceOf(msg.sender) == 0);
        require(msg.value >= EARLY_PRICE, "Not enough ether");

        if(!earlyBirds[msg.sender] || (block.timestamp > creationTime + 48 hours)) {
            require(msg.value >= GUARDIAN_PRICE, "Not enough ether");
        }

        uint tokenId = _tokenIdCounter.current();
        pendingWithdrawals[daoTreasury] += msg.value;
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
    }

    function withdrawAll() external onlyRole(DAO_AGENT_ROLE) {
        uint amount = pendingWithdrawals[daoTreasury];
        pendingWithdrawals[daoTreasury] = 0;
        payable(daoTreasury).transfer(amount);
    }

    function addEarlyBirds(address[] memory _earlyBirdAddresses) external onlyRole(DAO_AGENT_ROLE) {
        for(uint i=0; i < _earlyBirdAddresses.length; ++i) {
            earlyBirds[_earlyBirdAddresses[i]] = true;
        }
        emit SetEarlyBirds(_earlyBirdAddresses, _earlyBirdAddresses.length);
    }

    function addNewEarlyBird(address _earlyBirdAddress) external onlyRole(DAO_AGENT_ROLE) {
        earlyBirds[_earlyBirdAddress] = true;
        emit SetEarlyBird(_earlyBirdAddress, earlyBirds[_earlyBirdAddress]);
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(DAO_AGENT_ROLE) {
        keyHash = _keyHash;
        emit SetChainlinkKeyHash(_keyHash);
    }

    function setChainlinkFee(uint256 _fee) external onlyRole(DAO_AGENT_ROLE) {
        fee = _fee;
        emit SetChainlinkFee(_fee);
    }

    function setDAOTreasury(address _daoTreasury) external onlyRole(DAO_AGENT_ROLE) {
        daoTreasury = _daoTreasury;
        emit SetDAOTreasury(_daoTreasury);
    }

    function setCrossChainAdapter(address _crossChainAdapter) external onlyRole(DAO_AGENT_ROLE) {
        crossChainAdapter = _crossChainAdapter;
        emit SetCrossChainAdapter(_crossChainAdapter);
    }

    function setAttributes(uint _tokenId, uint16 _attributeSet) external onlyRole(DAO_AGENT_ROLE) {
        _setAttributes(_tokenId, _attributeSet);
    }

    function getAttributes(uint _tokenId) external view returns(uint16) {
        return guardianAttributes[_tokenId];
    }
    
    function setBaseURI(string memory __baseURI) external onlyRole(DAO_AGENT_ROLE) {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    /*@dev This allows an adapter in future to mint the necessary tokens
    * @dev If they are not locked in a deposit account in the adapter
    * @dev The apprentice upon becoming a guardian will have his attributeSet same as parent guardian
    */
    function mint(
        address to, 
        uint _tokenId, 
        uint16 _attributeSet
    )
        public 
        onlyCrossChainAdapter() 
        onlyAfterCrossChainActive() 
    {
        currentGuardiansInThisNetwork++;
        _safeMint(to, _tokenId);
        _setAttributes(_tokenId, _attributeSet);
    }

    function burn(uint256 tokenId) 
        public 
        onlyCrossChainAdapter() 
        onlyAfterCrossChainActive() 
    {
        currentGuardiansInThisNetwork--;        
        _burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isGuardian(address _candidateAddress) public view returns(bool) {
        return guardians[_candidateAddress];
    }

    function isEarlyBird(address _checkIfEarlyBird) public view returns(bool) {
        return earlyBirds[_checkIfEarlyBird];
    }

    /** 
     * Requests randomness from the chainlink cryptoverse
     */
    function getRandomNumber() external onlyRole(DAO_AGENT_ROLE) returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * @notice messageFromTheUniverse is used as a seed to ensure fairness in our NFT assignment procedure
     * @notice chosenLeader is used to find a leader amongst the guardians every human epoch
     */
    function fulfillRandomness(
        bytes32, 
        uint256 randomness
    ) 
        internal 
        override 
    {
        messageFromTheUniverse = randomness;
        chosenLeader = randomness % currentGuardiansInThisNetwork; 
        emit etherealMessageReceived(messageFromTheUniverse);
    }

    function _beforeTokenTransfer(
        address from, 
        address to, 
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable)
    {
        require(balanceOf(to) == 0, "KP: Already a guardian!");

        guardians[from] = false;
        guardians[to] = true;

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
        
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /*** 
    *@dev initialize and upgrade the attributes of the guardian
    */
    function _setAttributes(uint _tokenId, uint16 _attributeSet) private {
        guardianAttributes[_tokenId] = _attributeSet;
        emit SetAttributes(_tokenId, _attributeSet);
    }
}
