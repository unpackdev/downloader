// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";


contract reeCats is ERC721, Ownable {
	using SafeMath for uint256;
    using Counters for Counters.Counter;

    bool public sale_active = false;    

    uint256 public totalCount = 3333;
    uint256 public maxPurchase = 20;
    uint256 public price = 33000000000000000; 
    uint256 public freeMint = 500;
    string public baseURI;

    Counters.Counter private _tokenSupply;
        
    
    function setURIs(string memory _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
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
    function changeFM(uint256 _new) public onlyOwner {
        freeMint = _new;
    }

    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxPurchase = _newBatch;
    }

    function mint (uint256 _count) payable public {
        uint256 mintIndex = _tokenSupply.current();

        require(sale_active, "Sale Not Active");
        require(_count >0 && _count <= maxPurchase, "Max Mint Per Transaction Restriction");
        require(mintIndex + _count <= totalCount, "Sold Out");
        if (mintIndex + _count < freeMint)
            require(msg.value == 0, "Mint is Free");
        else
		    require(msg.value == price.mul(_count), "Exact ETH Required");

        for(uint256 i=0; i < _count; i++){
            _tokenSupply.increment();
            _safeMint(_msgSender(), _tokenSupply.current());
        }
    }  

	function withdraw() public payable onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

	constructor() ERC721 ("Celestial Cats", "CATS") {}

}