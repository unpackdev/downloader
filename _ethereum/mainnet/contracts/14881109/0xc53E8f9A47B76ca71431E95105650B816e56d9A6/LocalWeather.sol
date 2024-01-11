// SPDX-License-Identifier: MIT

/***
 __          __      _______          _____  _       _ _        _
 \ \        / /     |__   __|        |  __ \(_)     (_) |      | |
  \ \  /\  / /_ _ _   _| | ___   ___ | |  | |_  __ _ _| |_ __ _| |
   \ \/  \/ / _` | | | | |/ _ \ / _ \| |  | | |/ _` | | __/ _` | |
    \  /\  / (_| | |_| | | (_) | (_) | |__| | | (_| | | || (_| | |
     \/  \/ \__,_|\__, |_|\___/ \___/|_____/|_|\__, |_|\__\__,_|_|
                   __/ |                        __/ |
                  |___/                        |___/
***/
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract LocalWeather is ERC721A, Ownable {
    using MerkleProof for bytes32[];
    using Strings for uint256;

    uint8 public constant maxPerWallet = 3;
    uint8 public constant maxPerTransaction = 3;

    uint16 public reservedNFTsAmount;

    bytes32 public merkleRoot;

    bool public preReveal = true;

    string private baseURI;
    string private preRevealBaseURI;

    bool public saleStarted = false;
    bool public publicSaleStarted = false;

    uint16 public constant totalNFTs = 18888;
    uint16 private constant basicNFTs = 18500;
    uint16 private constant reservedNFTs = 388;

    uint256 public nftPrice = 0.1495 ether;

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    constructor(string memory name, string memory symbol) ERC721A(name, symbol) {
        reservedNFTsAmount = 0;
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setPreRevealBaseURI(string memory _preRevealBaseUri) public onlyOwner {
        preRevealBaseURI = _preRevealBaseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function mint(
        bytes32[] memory proof,
        bytes32 leaf,
        uint8 amount
    ) public payable {
        require(amount <= maxPerTransaction,"Cannot mint more than 3 in a single transaction");
        require(msg.value == (nftPrice * amount), "The price is invalid");
        require(saleStarted == true, "The sale is paused");
        require(totalSupply() + amount <= basicNFTs, "Mint limit reached");
        require(_numberMinted(msg.sender) + amount <= maxPerWallet, "Amount requested is over max amount per wallet");
        require(tx.origin == msg.sender, "Caller must be an account");

        if (publicSaleStarted == false) {
            require(keccak256(abi.encodePacked(msg.sender)) == leaf, "This leaf does not belong to the sender");
            require(proof.verify(merkleRoot, leaf), "You are not in the list");
        }

        _mint(msg.sender, amount);
    }

    function reserveNFT(address to, uint16 amount) public onlyOwner {
        require(reservedNFTsAmount + amount <= reservedNFTs, "Out of stock");

        _mint(to, amount);
        reservedNFTsAmount += amount;
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleStarted = !publicSaleStarted;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setNFTPrice(uint256 price) public onlyOwner {
        nftPrice = price;
    }

    function reveal() public onlyOwner {
        preReveal = false;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (preReveal == true) return string(abi.encodePacked(preRevealBaseURI, tokenId.toString()));
        else return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}
