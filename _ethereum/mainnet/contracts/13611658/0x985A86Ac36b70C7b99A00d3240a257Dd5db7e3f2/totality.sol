pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721Enumerable.sol";

contract Totality is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    address private TREASURY_WALLET = 0x7772005Ad71b1BC6c1E25B3a82A400B0a8FC7680;
    address private _signerAddress = 0x49de30dC31D33D7da03d71b75132ef82251B1D2f;
    string private _tokenBaseURI =
        "https://api-totality-nft-placeholder.herokuapp.com/api/metadata/";

    constructor(
        string memory _name,
        string memory _symbol) ERC721(_name, _symbol) {}

    uint256 public constant PRIVATE = 200;
    uint256 public constant PUBLIC = 1919;
    uint256 public constant MAX_SUPPLY_LIMIT = PRIVATE + PUBLIC;
    uint256 public constant LAUNCH_PRICE = 0.1919 ether;
    uint256 public constant PRESALE_PRICE = 0.0919 ether;
    uint256 public constant LIMIT_PER_MINT = 5;

    uint256 public requested;
    uint256 public giftedAmountMinted;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;

    bool public presaleLive;
    bool public saleLive;

    function presaleBuy(bytes calldata signature, string calldata nonce, uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require( privateAmountMinted + tokenQuantity <= PRIVATE, "EXCEED_PRIVATE");
        require( PRESALE_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(matchAddresSigner(hashTransaction(msg.sender, tokenQuantity, nonce), signature), "DIRECT_MINT_DISALLOWED");

        privateAmountMinted += tokenQuantity;
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
         
        payable(TREASURY_WALLET).transfer(msg.value);
    }

    function hashTransaction( address sender, uint256 qty, string memory nonce) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce))
            )
        );
        return hash;
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns (bool)
    {
        return _signerAddress == hash.recover(signature);
    }

    function buy(uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(!presaleLive, "ONLY_PRESALE");
      require(totalSupply() < MAX_SUPPLY_LIMIT, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= PUBLIC, "EXCEED_PUBLIC");
      require(tokenQuantity <= LIMIT_PER_MINT, "EXCEED_LIMIT_PER_MINT");
      require(LAUNCH_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

      for (uint256 i = 0; i < tokenQuantity; i++) {
        publicAmountMinted++;
        _safeMint(msg.sender, totalSupply() + 1);
      }
        payable(TREASURY_WALLET).transfer(msg.value);
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}
