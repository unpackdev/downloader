//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721AQueryable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract VermilyNFT is ERC721AQueryable, Ownable, ReentrancyGuard {

    uint256 public maxSupply;
   
    string public baseURI;
    
    string public defaultURI;
    
    uint256 public privateStartTime;

    uint256 public privateEndTime;

    uint256 public preSaleStartTime;

    uint256 public preSaleEndTime;

    uint256 public publicStartTime;

    uint256 public tokenCount;
  
    uint256 public phaseNum;

    uint256 public maxPhaseNum;

    using Strings for uint256;


    constructor(
        string memory _baseURI,
        string memory _defaultURI
    ) ERC721A("VERMILYNFT", "VERMILYNFT") {
        uint256 _maxSupply = 10000;
        maxPhaseNum = 2000;

        preSaleStartTime = 1657825200; 
        preSaleEndTime = 1658034000;
        privateStartTime = 1658034000; 
        privateEndTime = 9655902800; 
        publicStartTime = 1658034000; 
       
        setBaseURI(_baseURI);
        maxSupply = _maxSupply;
        defaultURI = _defaultURI;
        phaseNum = 1;     
    }
    
    modifier onlyAfterPublicMintStarted(){
        require(publicStartTime < block.timestamp ,"Public Mint has not started yet");
        _;    
    }

    modifier onlyAfterPrivateMintStarted(){
        require(privateStartTime < block.timestamp ,"Private mint has not started yet");
        _;    
    }
    
    modifier onlyBeforePrivateMintEnded(){
        require(privateEndTime > block.timestamp, "Private mint has ended");
        _;    
    }

    modifier onlyBeforepreSaleEnded(){
        require(preSaleEndTime > block.timestamp, "Pre Sale has ended");
        _;    
    }
    
    modifier onlyAfterpreSaleStarted(){
        require(preSaleStartTime < block.timestamp, "Pre Sale not started yet");
        _;    
    }

    modifier onlyAllowedQuantity(uint256 _num){
        require(totalSupply() + _num <= maxSupply, "Num must be less than maxSupply");
        _;
    }
    
    event ItemCreated (
        uint256 tokenNumber,
        address owner,
        address seller
    );

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    function setMintTime(
        uint256 _privateStartTime,
        uint256 _privateEndTime,
        uint256 _preSaleStartTime,
        uint256 _preSaleEndTime,
        uint256 _publicStartTime    
    ) external onlyOwner {
        privateStartTime = _privateStartTime;
        privateEndTime = _privateEndTime;
        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime =  _preSaleEndTime;
        publicStartTime = _publicStartTime;
    }

    function mint(address _addresss, uint256 _num) internal nonReentrant {
        _safeMint(_addresss, _num);
        tokenCount += _num;

        emit ItemCreated(  
            tokenCount,        
            address(_addresss),
            msg.sender           
        );
    }

    function vermilyPreSale(uint256 _num) external payable
    onlyAfterpreSaleStarted
    onlyBeforepreSaleEnded
    onlyAllowedQuantity(_num)
    {
        mint(msg.sender, _num);
    }

    
    function privateMint( address _addresss, uint256 _num) external payable     
    onlyAfterPrivateMintStarted
    onlyBeforePrivateMintEnded
    onlyAllowedQuantity(_num)
    {
       mint(_addresss, _num);
    }

   function publicMint(uint256 _num) external payable 
    onlyAfterPublicMintStarted
    onlyAllowedQuantity(_num)
    {
        mint(msg.sender, _num);
    }
   
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPhaseNum(uint256 _maxPhaseNum) public onlyOwner {
        maxPhaseNum = _maxPhaseNum;
    }

    function setCurrentPhaseNum(uint256 _phaseNum) public onlyOwner {
        phaseNum = _phaseNum;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
            : defaultURI;

        return imageURI;
    }

    function getMaxTokenNum() public view returns(uint256) {
        return tokenCount;
    }

}
