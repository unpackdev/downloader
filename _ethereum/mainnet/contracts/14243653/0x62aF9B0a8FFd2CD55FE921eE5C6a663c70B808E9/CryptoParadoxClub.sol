// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CryptoParadoxClub is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    // config
    string constant notRevealedURI = "ipfs://QmWj2RcjV9Ve7UVmQb7wGu4tJvxjZVqLuKPo5zGVYX7xjZ/";
    uint256 constant maxSupply = 7777;
    uint256 constant nftPerAddress = 10;

    uint256 public price = 0.05 ether;

    Counters.Counter private _tokenIDCounter;

    string public baseURI;
    string public baseExtension = ".json";
    bool public collectionRevealed = false;
    
    mapping(address => uint256) public addressMintedBal;
    

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    // Internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public methods

    /**
     * Required `proof` a valid merkle proof that msg.sender is whitelisted
     * Provide an empty proof for the public sale
     *
     * Emits a {Transfer} event.
     */
    
    function buy(address _to, uint256 _quantity) public payable {
        uint256 userMintLimit = nftPerAddress;

        require(_quantity > 0, "Need to mint at least 1 NFT");
        require(addressMintedBal[msg.sender] + _quantity <= userMintLimit, "Mint quantity exceeds allowance for this address");
	    require(_tokenIDCounter.current() <= maxSupply, "Sold out");
		require(_tokenIDCounter.current() + _quantity <= maxSupply, "Mint quantity exceeds max supply");
        require(msg.value >= price * _quantity, "Insufficient funds");

        for (uint i = 0; i < _quantity; i++){
            _tokenIDCounter.increment();
            addressMintedBal[_to]++;
            _mint(_to, _tokenIDCounter.current());
        }
    }

    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "ERC721Metadata: URI query for nonexistent token");

        if(collectionRevealed == false ){
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenID.toString(), baseExtension))
        : "";
    }


    // Owner methods

    function reveal(string memory _newBaseURI) public onlyOwner {
        // One way function.
        require(!collectionRevealed, "Collection was already revealed!");
        collectionRevealed = true;
        baseURI = _newBaseURI;
    }

   function AirDrop(address[] calldata _inf) public onlyOwner{
        require(_inf.length > 0, "Need to mint at least 1 NFT");
	    require(_tokenIDCounter.current() <= maxSupply, "Sold out");
		require(_tokenIDCounter.current() + _inf.length <= maxSupply, "Mint quantity exceeds max supply");

        for (uint i = 0; i < _inf.length; i++){
            _tokenIDCounter.increment();
            addressMintedBal[_inf[i]]++;
            _mint(_inf[i], _tokenIDCounter.current());
        }
    }


    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
	
	function withdraw() public payable onlyOwner {
		(bool success, ) = payable(owner()).call{value: address(this).balance}("");
		require(success, "Withdrawal failed");
	}

    /**
     * @inheritdoc ERC721
     */
   
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }

    function _beforeTokenTransfer(address from, address to, uint256 _tokenID)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, _tokenID);
    }
}