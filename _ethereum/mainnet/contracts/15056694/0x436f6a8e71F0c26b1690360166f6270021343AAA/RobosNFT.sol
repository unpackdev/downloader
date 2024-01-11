//SPDX-License-Identifier: MIT
/// @title Robos NFT Contract
/// @author 0xOrphan
/// @notice This contract is used to manage the NFTs of the Robos contract.
/// @dev This contract is used to manage the NFTs of the Robos contract.

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Namable.sol";
import "./ClankToken.sol";

contract RobosNFT is ERC721Namable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter internal _tokenIdTracker;

/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    Robo Generation struct's
///////////////////////////////////////////////////////////////////////////////////////////////*/  
    struct ManufactureHistory {
        uint256 tokenId;
        uint256 time;
    }

    struct Robo {
        uint8 generation;
    }

    enum Generation {
        GENESIS_ROBO,
        ROBO_JR
    }

/*///////////////////////////////////////////////////////////////////////////////////////////////
                                        Public Vars
///////////////////////////////////////////////////////////////////////////////////////////////*/  
    //Public Strings
    string public baseURI;
    string public baseExtension  = ".json";
    bytes32 private merkleRoot = 0xcbf6af9d264d54292d5676cc3a5c0cefb8f60d05172c5ee5d01d803de1bd97c8;

    // Booleans
    bool public paused = true; 
    bool public preSale = true;
    bool public breeding = false;

    //Public Addresses
    address public constant burn = address(0x000000000000000000000000000000000000dEaD);
    address payable public xurgi;
    //OPENSEA ADDY 
    //      Rinkeby: 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A
    //      Mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
    address public proxyRegistryAddress = 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A;


    // Minting Variables
    // Whitelist Max per wallet kinda easy to get past tho
    uint16 public nftPerAddress = 2;
    uint16 public bulkBuyLimit;
    uint256 public price;
    uint256 public MANUFACTURE_PRICE = 69 ether;

    //Genesis Robo &RoboJr supply vars
    uint256 public robosSupply; 
    uint256 public roboJrSupply;
    uint256 public roboMaxSupply = 2222;
    uint256 public roboJrMaxSupply =  1111;
	uint256 public nameChangePrice = 25 ether;
	uint256 public BioChangePrice = 25 ether;

    //Set Yield token as RoboToken
    ClankToken public clankToken;
/*///////////////////////////////////////////////////////////////////////////////////////////////
                                        Mappings
///////////////////////////////////////////////////////////////////////////////////////////////*/
    mapping(address => uint256) public addressMintedBalance;
    mapping(address => uint256) public balanceOG;
    mapping(address => uint256) public balanceJR;
    mapping(uint256 => ManufactureHistory) public manufactureHistory;
    mapping(uint256 => Robo) public roboz ;
    mapping(uint256 => uint256) public robosManufacture ;
/*///////////////////////////////////////////////////////////////////////////////////////////////
                                        Events
///////////////////////////////////////////////////////////////////////////////////////////////*/

/*///////////////////////////////////////////////////////////////////////////////////////////////
                                        Constructor
///////////////////////////////////////////////////////////////////////////////////////////////*/
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string[] memory _names,
        uint256[] memory _ids,
        address payable _xurgi
    ) ERC721Namable(_name, _symbol, _names, _ids) {
        xurgi = _xurgi;
        setBaseURI(_initBaseURI);
        price = 0.1 ether;
        bulkBuyLimit = 4;
        _preMint(30);
    }

/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    Modifier Functions
///////////////////////////////////////////////////////////////////////////////////////////////*/
    modifier unPaused() {
        require(
            paused == false,
            "Contract Paused"
        );
        _;
    }
        
    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract.');
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier isPresale() {
        require(preSale == true, "Presale not active");
        _;
    }

    modifier notMaxSupply(uint256 amount) {
        require(amount +robosSupply <= roboMaxSupply);
        _;
    }

    modifier isPublicSale() {
        require(!preSale, "Sale not Public");
        _;
    }

    modifier isCorrectPayment(uint256 _price, uint256 amount) {
        uint256 total = price * amount;
        require(
            total == msg.value,
            "Incorrect ETH value sent"
        );
        (bool transferToDaoStatus, ) = xurgi.call{value: total}("");
        require(
            transferToDaoStatus,
            "Address: unable to send value."
        );
        _;
    }
/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    External Functions
///////////////////////////////////////////////////////////////////////////////////////////////*/  

    function manufactureRoboJr(uint256 tokenIdA, uint256 tokenIdB) external unPaused() {
        require(breeding == true, "Breeding disabled");
        require(roboJrSupply <= roboJrMaxSupply, "supply exceeded");

        //requires msgSender to own to tokenIds 
        require(ownerOf(tokenIdA) == msg.sender, "not ownerOf");
        require(ownerOf(tokenIdB) == msg.sender, "not ownerOf");
        //requires tokenIds to be a GENESIS_ROBO
        require(roboz[tokenIdA].generation  == uint256(Generation.GENESIS_ROBO), "Can only breed GenesisRobos");
        require(roboz[tokenIdB].generation  == uint256(Generation.GENESIS_ROBO), "Can only breed GenesisRobos");

        require(robosManufacture[tokenIdA] + 7 days < block.timestamp, "wait 7 days");
        require(robosManufacture[tokenIdB] + 7 days < block.timestamp, "wait 7 days");

        require(clankToken.balanceOf(msg.sender) >= MANUFACTURE_PRICE);
        
        clankToken.burn(msg.sender, MANUFACTURE_PRICE);
    
        roboJrSupply = roboJrSupply + 1;

        return _manufacture(tokenIdA, tokenIdB);
    }

    function getReward() external unPaused() {
        clankToken.updateReward(msg.sender, address(0), 0);
        clankToken.getReward(msg.sender);
    }

    function setMintCost(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setTxLimit(uint16 _bulkBuyLimit) external onlyOwner {
        bulkBuyLimit = _bulkBuyLimit;
    }

    function setWlTxLimit(uint16 _newNftPerAddress) external onlyOwner {
        nftPerAddress = _newNftPerAddress;
    }

    function enableBreeding() external onlyOwner {
        breeding = true;
    }
    
    function disableBreeding() external onlyOwner {
        breeding = false;
    }

    function changeNamePrice(uint256 _namePrice) external onlyOwner {
        nameChangePrice = _namePrice;
    }

    function changeBioPrice(uint256 _bioPrice) external onlyOwner {
        BioChangePrice = _bioPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setWLMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setOnlyPreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

    function setClankToken(address _yield) external onlyOwner {
        clankToken = ClankToken(_yield);
    }

/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    Public Mint/Breed Functions
///////////////////////////////////////////////////////////////////////////////////////////////*/
    function mintGenesisRobo(uint256 amount) 
        public 
        payable 
        unPaused() 
        callerIsUser() 
        isPublicSale() 
        notMaxSupply(amount) 
        isCorrectPayment(price, amount) 
    {
        require(amount <= bulkBuyLimit, "amount exceeds limit");

        robosSupply = robosSupply + amount;
        for (uint256 i = 0; i < amount; i++) {
            clankToken.updateRewardOnMint(msg.sender, 1);
            balanceOG[msg.sender]++;
            _mintByGeneration(_msgSender(), Generation.GENESIS_ROBO);
        }
    }

    function whitelistMint(bytes32[] calldata proof, uint256 amount) 
        public
        payable 
        unPaused() 
        callerIsUser() 
        isPresale() 
        isValidMerkleProof(proof, merkleRoot) 
        notMaxSupply(amount) 
        isCorrectPayment(price, amount) 
    {
        uint256 mintedCount = addressMintedBalance[msg.sender];
        require(mintedCount + amount <= nftPerAddress, "max per address");

        robosSupply = robosSupply + amount;
        for (uint256 i = 0; i < amount; i++) {
            clankToken.updateRewardOnMint(msg.sender, 1);
            balanceOG[msg.sender]++;
            addressMintedBalance[msg.sender]++;
            _mintByGeneration(_msgSender(), Generation.GENESIS_ROBO);
        }
    }
    
    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    Public View Functions
///////////////////////////////////////////////////////////////////////////////////////////////*/
    function changeName(uint256 tokenId, string memory newName) public override {
        clankToken.burn(msg.sender, nameChangePrice);
        super.changeName(tokenId, newName);
    }

    function changeBio(uint256 tokenId, string memory _bio) public override {
        clankToken.burn(msg.sender, BioChangePrice);
        super.changeBio(tokenId, _bio);
    }
    
   
    function generationOf(uint256 tokenId) public view returns(uint256 generation) {
        return roboz[tokenId].generation;
    }

    function lastTokenId() public view returns(uint256 tokenId) {
        return _tokenIdTracker.current();
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory tokenId = toString(_tokenId);
        string memory currentBaseURI = _baseURI();
        string memory  generationPath = "/";
        uint256 generation = roboz[_tokenId].generation;
        if (generation == 0) {
            generationPath = "genesisRobo";
        } else if (generation == 1) {
            generationPath = "roboJr";
        }
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, generationPath, tokenId, baseExtension)) : "";    
    }

    function transferFrom(
        address from, 
        address to, 
        uint256 tokenId
    ) public override {
        clankToken.updateReward(from, to, tokenId);
        if (tokenId < 2223) {
            balanceOG[from]--;
            balanceOG[to]++;
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to, 
        uint256 tokenId, 
        bytes memory _data
    ) public override {
        clankToken.updateReward(from, to, tokenId);
        if (tokenId < 2223) {
            balanceOG[from]--;
            balanceOG[to]++;
        }
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    } 
        
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    Internal functions
///////////////////////////////////////////////////////////////////////////////////////////////*/
    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }
    
/*///////////////////////////////////////////////////////////////////////////////////////////////
                                    private functions
///////////////////////////////////////////////////////////////////////////////////////////////*/ 
    function _preMint(uint256 amount) private {
        robosSupply = robosSupply + amount;
        for (uint256 i = 0; i < amount; i++) {
            balanceOG[msg.sender]++;
            _mintByGeneration(xurgi, Generation.GENESIS_ROBO);
        }
    }
    
    function _mintByGeneration(address to, Generation generation) private {
        uint8 _generation = uint8(generation);
        _tokenIdTracker.increment();
        uint256 tokenId = _tokenIdTracker.current();
        roboz[tokenId].generation = _generation;

        _safeMint(to, tokenId);
    }

    function _manufacture(uint256 tokenIdA, uint256 tokenIdB) private {
        robosManufacture[tokenIdA] = block.timestamp;
        robosManufacture[tokenIdB] = block.timestamp;

        manufactureHistory[tokenIdA].tokenId = tokenIdA;
        manufactureHistory[tokenIdA].time = block.timestamp;

        manufactureHistory[tokenIdB].tokenId = tokenIdB;
        manufactureHistory[tokenIdB].time = block.timestamp;

    
        balanceJR[msg.sender]++;
        _mintByGeneration(_msgSender(), Generation.ROBO_JR);
    }

    function toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}