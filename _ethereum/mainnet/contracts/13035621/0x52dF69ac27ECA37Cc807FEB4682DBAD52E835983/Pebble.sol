pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Pebble is ERC721Enumerable, Ownable {
    uint256 public constant MAX_NFT_SUPPLY = 2800;
    uint public constant MAX_PURCHASABLE = 30;
    uint256 public PEBBLE_PRICE = 30000000000000000; // 0.03 ETH
    string public PROVENANCE_HASH = "";

    bool public saleStarted = false;

    constructor() ERC721("PebbleNFT", "PEBBLENFT") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://pebblenft.com/api/";
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

   function mint(uint256 amountToMint) public payable {
        require(saleStarted == true, "This sale has not started.");
        require(totalSupply() < MAX_NFT_SUPPLY, "All NFTs have been minted.");
        require(amountToMint > 0, "You must mint at least one Pebble.");
        require(amountToMint <= MAX_PURCHASABLE, "You cannot mint more than 30 Pebble.");
        require(totalSupply() + amountToMint <= MAX_NFT_SUPPLY, "The amount of Pebble you are trying to mint exceeds the MAX_NFT_SUPPLY.");

        require(PEBBLE_PRICE * amountToMint == msg.value, "Incorrect Ether value.");

        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
   }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function setProvenanceHash(string memory _hash) public onlyOwner {
        PROVENANCE_HASH = _hash;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
