// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Address.sol";


contract OwnableDelegateProxy {}


contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract RGC is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  string public _metadataURI = "";


  constructor(string memory customBaseURI_, address proxyRegistryAddress_)
    ERC721( "RG-Cars", "RGC" ){
	customBaseURI = customBaseURI_;
	proxyRegistryAddress = proxyRegistryAddress_;
    }


    mapping(address => uint256) private mintCountMap;
    mapping(address => uint256) private allowedMintCountMap;
    uint256 public MINT_LIMIT_PER_WALLET = 5;
    function setMINT_LIMIT_PER_WALLET(uint256 _count) external onlyOwner {
      MINT_LIMIT_PER_WALLET = _count;
    }
    function allowedMintCount(address minter) public view returns (uint256) {
      return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
    }
    function updateMintCount(address minter, uint256 count) private {
      mintCountMap[minter] += count;
    }


    uint256 public constant MAX_SUPPLY = 100;
    Counters.Counter private supplyCounter;


    uint256 public MAX_MULTIMINT = 5;
    function setMAX_MULTIMINT(uint256 _count) external onlyOwner {
      MAX_MULTIMINT = _count;
    }


    uint256 public PRICE_WL = 10000000000000000;
    function setPRICE_WL(uint256 _price) external onlyOwner {
      PRICE_WL = _price;
    }
    uint256 public PRICE_PUBLIC = 20000000000000000;
    function setPRICE_PUBLIC(uint256 _price) external onlyOwner {
      PRICE_PUBLIC = _price;
    }


    function mintGod(address to, uint256 count) external onlyOwner {
      require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");
      for (uint256 i = 0; i < count; i++) {
        _mint(to, totalSupply());
        supplyCounter.increment();
      }
    }


    function mintWL(uint256 count) public payable nonReentrant onlyWhitelisted {
      require( count > 0, "0 tokens to mint" );
      require( sale_WL_IsActive, "WL Sale not active" );
      if ( allowedMintCount(msg.sender) == MINT_LIMIT_PER_WALLET ) {
        updateMintCount( msg.sender, count );
      } else {
        revert( "Minting limit exceeded" );
      }
      require( totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply" );
      require( count <= MAX_MULTIMINT, "Mint at most 2 at a time" );
      require( msg.value >= PRICE_WL * count - PRICE_WL, "Insufficient payment" );
      for (uint256 i = 0; i < count; i++) {
        _safeMint(msg.sender, totalSupply());
        supplyCounter.increment();
      }
       _withdraw( payable(msg.sender), msg.value );
    }


    function mint(uint256 count) public payable nonReentrant {
      require(count > 0, "0 tokens to mint");
      require(sale_Public_IsActive, "Public Sale not active");
      if (allowedMintCount(msg.sender) >= count) {
        updateMintCount(msg.sender, count);
      } else {
        revert("Minting limit exceeded");
      }
      require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");
      require(count <= MAX_MULTIMINT, "Mint at most 2 at a time");
      require(
        msg.value >= PRICE_PUBLIC * count, "Insufficient payment"
      );
      for (uint256 i = 0; i < count; i++) {
        _safeMint(msg.sender, totalSupply());
        supplyCounter.increment();
      }
      if( count > 1 && random( 25-(count-1)*5 ) == 1 ){
	_withdraw( payable(msg.sender), msg.value );
      }
    }


    function _withdraw(address _address, uint256 _amount) private {
	(bool success, ) = _address.call{value: _amount}("");
	require(success, "Transfer failed.");
    }


    function totalSupply() public view returns (uint256) {
      return supplyCounter.current();
    }


    bool public sale_WL_IsActive = false;
    function setSale_WL_IsActive(bool saleIsActive_) external onlyOwner {
      sale_WL_IsActive = saleIsActive_;
    }


    bool public sale_Public_IsActive = false;
    function setSale_Public_IsActive(bool saleIsActive_) external onlyOwner {
      sale_Public_IsActive = saleIsActive_;
    }


    string private customBaseURI;
    function setBaseURI(string memory customBaseURI_) external onlyOwner {
      customBaseURI = customBaseURI_;
    }
    function _baseURI() internal view virtual override returns (string memory) {
      return customBaseURI;
    }


    function withdraw() public nonReentrant onlyOwner {
      uint256 balance = address(this).balance;
      Address.sendValue(payable(owner()), balance);
    }


    address private immutable proxyRegistryAddress;
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
      ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
      if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
      }
      return super.isApprovedForAll(owner, operator);
    }


    /////////////////////////////////////////////////////////////////////////////////
    //
    // WhiteList
    //
    mapping(address => bool) private whitelist;
    function addWhitelist(address beneficiary) external onlyOwner{
        whitelist[beneficiary] = true;
    }
    function addManyWhitelist(address[] calldata beneficiary) external onlyOwner{
      for (uint i = 0; i < beneficiary.length; i++){
        whitelist[beneficiary[i]] = true;
      }
    }
    function removeWhitelist(address beneficiary) external onlyOwner{
      whitelist[beneficiary] = false;
    }
    modifier onlyWhitelisted {
      require(whitelist[msg.sender]);
      _;
    }
    function checkWhitelist(address beneficiary) public view returns (bool) {
      if ( whitelist[beneficiary] ){
        return true;
      } else {
        return false;
      }
    }
    //
    /////////////////////////////////////////////////////////////////////////////////


    function random(uint number) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
        msg.sender))) % number;
    }


}