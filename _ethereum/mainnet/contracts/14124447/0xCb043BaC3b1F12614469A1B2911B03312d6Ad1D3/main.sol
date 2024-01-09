pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";


import "./ERC721Tradable.sol";

contract AbstractWarriors is ERC721Tradable {
    using Strings for uint256;
	using SafeMath for uint256;

    event MintAbstract (address indexed sender, uint256 startWith, uint256 times);

    //uints 
    uint256 public totalAbstract;
    uint256 public totalCount = 333;
    uint256 public maxPurchase = 3;
    uint256 public price = 100000000000000000;
    string public baseURI;
	uint[] public mintedIds;
	string private _contractURI;

    //bool
    bool public sale_active = true;    

	// Wallets
	address private artist_1 = 0xA09b6583fb1dE9a183b403EBEF04194Bb76894e6;
	address private artist_2 = 0x4E0acB5a71ccE2187e60E4b10eD0e5CE13b03A46;
	address private artist_3 = 0x4b6232E1E198A3b6C03494BE0669Cf3Fc25996C4;

	mapping(address => uint) public mintedNFTs;

    

	constructor(address _proxyRegistryAddress, string memory _cURI) ERC721Tradable("AbstractWarriors", "ABWA", _proxyRegistryAddress) {_contractURI = _cURI; }


    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string memory _cURI) external onlyOwner {
        _contractURI = _cURI;
    }

	function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

	function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

	function setSaleStatus(bool _start) public onlyOwner {
        sale_active = _start;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }


    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxPurchase = _newBatch;
    }

    function mintAbstract(uint256 _count) payable public {
		uint256 TotalSupply = totalSupply();
        require(sale_active, "sale has to be active");
        require(_count >0 && _count <= maxPurchase, "Violated Max Tx Purchase Constraint");
        require(TotalSupply + _count <= totalCount, "Exceeds Max Tokens Available");
        require(msg.value == _count * price, "value error");
		require(msg.value >= price.mul(_count), "Ether value sent is not correct");
        emit MintAbstract(_msgSender(), TotalSupply+1, _count);

        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
    }  
    
    function devMint(uint256 _count) public onlyOwner {
		uint256 TotalSupply = totalSupply();
		require(TotalSupply + _count <= totalCount, "Exceeds Max Tokens Available");
        emit MintAbstract(_msgSender(), TotalSupply+1, _count);


        for(uint256 i=0; i < _count; i++){
            _mint(_msgSender(), _getNextTokenId());
            mintedIds.push(_getNextTokenId());
            _incrementTokenId();

        }
    }


	function withdraw_emerg() public payable onlyOwner {

        uint balance = address(this).balance;
        payable(artist_3).transfer(balance);


    }


	function get_all() public view  returns (uint[] memory) {
        return mintedIds;
    }



}