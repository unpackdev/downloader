// SPDX-License-Identifier: MIT
// PIXEL RENGA

pragma solidity ^0.8.0;


import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


pragma solidity ^0.8.7;

contract PixelRenga is Ownable, ERC721A {
    
    uint256 public price                        = 0.001 ether;
    bool    public pause                        = true;
    uint256 public maxPerAddressDuringMint      = 10;
    uint256 public maxPerAddressDuringFreeMint  = 1;
    uint256 public maxSupply                    = 2222;
    uint256 public maxFreeSupply                = 222;
    string private _baseTokenURI;

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("Pixel Renga", "PRENGA") {
       
    }

    function freemint(uint256 _quantity) external payable mintCompliance() {
                require(maxFreeSupply >= totalSupply()+_quantity,"FREE SUPPLY SOLD OUT");
                uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
                require(_freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,"ONLY 1 FREE MINT PER WALLET");
                freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable mintCompliance(){
         require(msg.value >= price * _quantity, "NO ETH");
                require(maxSupply >= totalSupply() + _quantity,"SOLD OUT");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= maxPerAddressDuringMint,"ALREADY MAX MINTED PER ADDRESS");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function ActiveContract() public onlyOwner {
        pause = !pause;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function burnSupply(uint256 _amount) public onlyOwner {
        require(_amount<maxSupply, "Can't increase supply");
        maxSupply = _amount;
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