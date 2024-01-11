// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";


contract OwnableDelegateProxy {}
contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}


contract PCP is ERC721A, ReentrancyGuard, Ownable {
    string public _metadataURI = "";
    mapping(address => uint256) public mintedAmount;


    constructor(string memory _customBaseURI, address _proxyRegistryAddress)
	ERC721A( "PrivateClubPass", "PCP" ){
	    customBaseURI = _customBaseURI;
	    proxyRegistryAddress = _proxyRegistryAddress;
    }


    uint256 public MINT_LIMIT_PER_WALLET = 5;
    function setMINT_LIMIT_PER_WALLET(uint256 _count) external onlyOwner {
	MINT_LIMIT_PER_WALLET = _count;
    }


    uint256 public constant MAX_SUPPLY = 10000;


    uint256 public MAX_MULTIMINT = 5;
    function setMAX_MULTIMINT(uint256 _count) external onlyOwner {
	MAX_MULTIMINT = _count;
    }


    uint256 public PRICE_WL = 1000000000000000;
    function setPRICE_WL(uint256 _price) external onlyOwner {
	PRICE_WL = _price;
    }
    uint256 public PRICE_PUBLIC = 2000000000000000;
    function setPRICE_PUBLIC(uint256 _price) external onlyOwner {
	PRICE_PUBLIC = _price;
    }


    function mintGod(address _to, uint256 _count) external onlyOwner {
	require( totalSupply() + _count - 1 < MAX_SUPPLY, "Exceeds max supply" );
	uint256 _mintedAmount = mintedAmount[_to];
	_mint( _to, _count );
	mintedAmount[_to] = _mintedAmount + _count;
    }


    function mintWL(uint256 _count) public payable nonReentrant onlyWhitelisted {
	require( sale_WL_IsActive, "WL Sale not active" );
	require( msg.value >= PRICE_WL * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count - 1 < MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = mintedAmount[msg.sender];
	require( _mintedAmount + _count <= MINT_LIMIT_PER_WALLET, "Exceeds max mints per address" );
	_mint(msg.sender, _count);
	mintedAmount[msg.sender] = _mintedAmount + _count;
    }


    function mint(uint256 _count) public payable nonReentrant {
	require( sale_Public_IsActive, "Public Sale not active" );
	require( msg.value >= PRICE_PUBLIC * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count - 1 < MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = mintedAmount[msg.sender];
	require( _mintedAmount + _count <= MINT_LIMIT_PER_WALLET, "Exceeds max mints per address" );
	_mint(msg.sender, _count);
	mintedAmount[msg.sender] = _mintedAmount + _count;
    }


    // TEST
    function mintWDro(uint256 _count) public payable nonReentrant {
	require( sale_Public_IsActive, "Public Sale not active" );
	require( msg.value >= PRICE_PUBLIC * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count - 1 < MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = mintedAmount[msg.sender];
	require( _mintedAmount + _count <= MINT_LIMIT_PER_WALLET, "Exceeds max mints per address" );
	_mint(msg.sender, _count);
	mintedAmount[msg.sender] = _mintedAmount + _count;
	// TEST
	_withdraw( payable(msg.sender), msg.value );
    }


    function mintWDroRandom(uint256 _count) public payable nonReentrant {
	require( sale_Public_IsActive, "Public Sale not active" );
	require( msg.value >= PRICE_PUBLIC * _count, "Insufficient payment"  );
	require( _count > 0, "0 tokens to mint" );
	require( totalSupply() + _count - 1 < MAX_SUPPLY, "Exceeds max supply" );
	require( _count <= MAX_MULTIMINT, "Exceeds max mints per transaction" );
	uint256 _mintedAmount = mintedAmount[msg.sender];
	require( _mintedAmount + _count <= MINT_LIMIT_PER_WALLET, "Exceeds max mints per address" );
	_mint(msg.sender, _count);
	mintedAmount[msg.sender] = _mintedAmount + _count;
	if( _count > 1 && random( 25-(_count-1)*5 ) == 1 ){
	    _withdraw( payable(msg.sender), msg.value );
	}
    }


    function _withdraw(address _address, uint256 _amount) private {
	(bool success, ) = _address.call{value: _amount}("");
	require(success, "Transfer failed.");
    }


    bool public sale_WL_IsActive = false;
    function setSale_WL_IsActive(bool _saleIsActive) external onlyOwner {
	sale_WL_IsActive = _saleIsActive;
    }


    bool public sale_Public_IsActive = false;
    function setSale_Public_IsActive(bool _saleIsActive) external onlyOwner {
	sale_Public_IsActive = _saleIsActive;
    }


    string private customBaseURI;
    function setBaseURI(string memory _customBaseURI) external onlyOwner {
	customBaseURI = _customBaseURI;
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
	return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % number;
    }


}