// SPDX-License-Identifier: MIT
// GodHatesNFTees art is CC0, and in public domain. This is not considered stolen art. We just believe differently, that NO GOD HATES NFTees.


pragma solidity ^0.8.0;


import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


pragma solidity ^0.8.7;

contract GodHatesNFTees is Ownable, ERC721A {
    
    uint256 public maxSupply                    = 5000;
    uint256 public maxFreeSupply                = 4000;
    
    uint256 public maxPerAddressDuringMint      = 20;
    uint256 public maxPerAddressDuringFreeMint  = 1;


    
    uint256 public price                        = 0.001 ether;
    bool    public pause                        = true;

    string private _baseTokenURI = " ipfs://QmfZj2MAGHgSGLWK7K13Y65FXEsDuXSV9ReuX2Uc8WzK4M/";

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("No God Hates NFTs", "NGHN") {
       
    }

    function freemint(uint256 _quantity) external payable mintCompliance() {
                require(maxFreeSupply >= totalSupply()+_quantity,"God only gives half for free.");
                uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
                require(_freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,"God doesn't give you too many per address.");
                freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable mintCompliance(){
         require(msg.value >= price * _quantity, "There is no more funds.");
                require(maxSupply >= totalSupply() + _quantity,"God isn't making more NFTees today.");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= maxPerAddressDuringMint,"Exceeds max mints per address!");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function ActiveContract() public onlyOwner {
        pause = !pause;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId+1),".json")) : '';
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {value: address( this ).balance}( "" );
		require( os );
	}
        modifier mintCompliance() {
        require(!pause, "Sale is not active yet.");
        require(tx.origin == msg.sender, "Caller cannot be a contract.");
        _;
    }

}