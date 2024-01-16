// SPDX-License-Identifier: MIT
// Your nft's are worth shit, this one is just being honest about it.

pragma solidity ^0.8.0;


import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


pragma solidity ^0.8.7;

contract Web3Turds is Ownable, ERC721A {
    
    uint256 public maxSupply                    = 999;
    uint256 public maxFreeSupply                = 111;
    uint256 public maxPerAddressDuringMint      = 5;
    uint256 public maxPerAddressDuringFreeMint  = 1;
    
    uint256 public price                        = 0.0005 ether;

    string private _baseTokenURI = "ipfs://bafybeibh4nlyqrqaqtb7lj5abtpajiefiis7v24auw2vbapvupchhr4fkm/";

    mapping(address => uint256) public mintedAmount;
    mapping(address => uint256) public freeMintedAmount;

    constructor() ERC721A("Web3 Turds Official", "WTURD") {
       
    }

    function freemint(uint256 _quantity) external payable {
                require(maxFreeSupply >= totalSupply()+_quantity,"NO MORE FREE MINT");
                uint256 _freeMintedAmount = freeMintedAmount[msg.sender];
                require(_freeMintedAmount + _quantity <= maxPerAddressDuringFreeMint,"WANT MORE? GO BUY ONE");
                freeMintedAmount[msg.sender] = _freeMintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }

    function mint(uint256 _quantity) external payable {
         require(msg.value >= price * _quantity, "YOU ARE OUT OF ETH");
                require(maxSupply >= totalSupply() + _quantity,"WE SOLD OUT MFER");
                uint256 _mintedAmount = mintedAmount[msg.sender];
                require(_mintedAmount + _quantity <= maxPerAddressDuringMint,"TOO MANY TURDS");
                mintedAmount[msg.sender] = _mintedAmount + _quantity;
                _safeMint(msg.sender, _quantity);
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),".json")) : '';
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function withdraw() public onlyOwner {
		( bool os, ) = payable( owner() )
			.call {value: address( this ).balance}( "" );
		require( os );
	}
        

}