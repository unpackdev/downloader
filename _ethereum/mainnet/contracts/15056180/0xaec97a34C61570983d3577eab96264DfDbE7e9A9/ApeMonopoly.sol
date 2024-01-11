// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract ApeMonopoly is ERC721A, Ownable, ReentrancyGuard
{  
    using Strings for uint256;

    bool public mintOpen;
    uint256 public maxSupply;
    uint256 public maxMints;
    uint256 public mintPrice;
    string public _tokenURI;
    mapping(address => uint256) public mints;

	constructor(
        uint256 _maxSupply,
        uint256 _maxMints,
        uint256 _mintPrice,
        string memory _newTokenURI
    ) ERC721A("Ape Monopoly", "MNPLY") {
        setMintOpen(false);
        setMaxSupply(_maxSupply);
        setMaxMints(_maxMints);
        setMintPrice(_mintPrice);
        setTokenURI(_newTokenURI);
    }

    function setMintOpen(bool _mintOpen)
        public onlyOwner
    {
        mintOpen = _mintOpen;
    }

    function setMaxSupply(uint256 _maxSupply)
        public onlyOwner
    {
        uint256 supply = totalSupply();
        require(_maxSupply >= supply, "max supply cannot be less than current supply");
        maxSupply = _maxSupply;
    }

    function setMaxMints(uint256 _maxMints)
        public onlyOwner
    {
        maxMints = _maxMints;
    }

    function setMintPrice(uint256 _mintPrice)
        public onlyOwner
    {
        mintPrice = _mintPrice;
    }

    function setTokenURI(string memory _newTokenURI)
        public onlyOwner
    {
        _tokenURI = _newTokenURI;
    }

 	function mint(address _address, uint256 _qty)
        external payable nonReentrant
    {
  	    uint256 supply = totalSupply();
        uint256 newSupply = supply + _qty;
        require(mintOpen, "mint is not currently open");
        require(msg.sender == tx.origin, "msg.sender must initiate the transaction");
        require(newSupply <= maxSupply, "not enough supply for the chosen qty");
    	require(mints[_address] + _qty <= maxMints, "qty cannot be greater than max allowed mints");
        require(msg.value == ( mintPrice * _qty ), "insufficient value supplied");
        mints[_address] += _qty;
        _safeMint(_address, _qty);
    }

 	function mintOwner(address _address, uint256 _qty)
        public onlyOwner
    {
  	    uint256 supply = totalSupply();
        uint256 newSupply = supply + _qty;
	    require(newSupply <= maxSupply, "not enough supply for the chosen qty");
        _safeMint(_address, _qty);
    }

    function withdraw()
        public payable onlyOwner
    {
	    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

    function tokenURI(uint256 _tokenId) 
        public view virtual override returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(_tokenId), ".json")) : "";
    }

    function _baseURI() 
        internal view virtual override returns (string memory)
    {
        return _tokenURI;
    }
}