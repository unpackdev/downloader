pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./console.sol";

contract SuperGiants is ERC721A, Ownable {

    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant RESERVED = 100;
    uint256 public constant MAX_MINT = 50;

    uint256 public constant MAX_PER_WALLET = 50;

    uint256 public MAX_EARLY_BIRD = 185; // first 185 mint
    uint256 public MAX_SECOND_BATCH_NR = 370; // up to 370 mint
    uint256 public MAX_THIRD_BATCH_NR = 555; // up to 555 mint

    uint256 public constant PRICE_EARLY_BIRD = 0.015 ether; // first 185 mint
    uint256 public constant PRICE_SECOND_BATCH = 0.017 ether;
    uint256 public constant PRICE_THIRD_BATCH = 0.019 ether;
    uint256 public constant PRICE_LAST = 0.03 ether; // more than 555 up to 5555

    string public baseTokenURI;

    constructor(string memory _baseTokenURI, uint256 _MAX_EARLY_BIRD, uint256 _MAX_SECOND_BATCH_NR, uint256 _MAX_THIRD_BATCH_NR) ERC721A("Supergiants", "CEO") {
        console.log("SuperGiants: creating smart contract with URI [%s]", _baseTokenURI);
        baseTokenURI = _baseTokenURI;
        MAX_EARLY_BIRD = _MAX_EARLY_BIRD;
        MAX_SECOND_BATCH_NR = _MAX_SECOND_BATCH_NR;
        MAX_THIRD_BATCH_NR = _MAX_THIRD_BATCH_NR;
    }

    // ------------------------------------------------------------------------
    // MINT
    // ------------------------------------------------------------------------

    function mint(uint256 quantity) external payable {
        // check max mint
        require(quantity <= MAX_MINT, "SuperGiants: max mint quantity exceeded");

        // check enough available nfts
        require(totalSupply().add(quantity) < MAX_SUPPLY.sub(RESERVED), "SuperGiants: not enough NFTs available");

        // check max token owned
        uint256 ownedTokens = balanceOf(msg.sender);
        require(ownedTokens.add(quantity) <= MAX_PER_WALLET, "SuperGiants: max quantity per wallet exceeded");

        // mint nfts
        uint256 startTokenId = totalSupply();
        uint256 price = currentPrice(startTokenId);
        require(msg.value >= price.mul(quantity), "SuperGiants: not enough ETH to purchase");

        console.log("SuperGiants: minting [%s] NFTs with price [%d]", quantity, price);

        _safeMint(msg.sender, quantity);
    }

    // return the current price which depends on the quantity of minted NFTs
    function currentPrice(uint256 currentMintedIndex) public view returns (uint256) {
        if (currentMintedIndex < MAX_EARLY_BIRD) {
            return PRICE_EARLY_BIRD;
        } else if (currentMintedIndex < MAX_SECOND_BATCH_NR) {
            return PRICE_SECOND_BATCH;
        } else if (currentMintedIndex < MAX_THIRD_BATCH_NR) {
            return PRICE_THIRD_BATCH;
        } else {
            return PRICE_LAST;
        }
    }

    // ------------------------------------------------------------------------
    // RESERVE
    // ------------------------------------------------------------------------

    // reserve a specific quantity of NFTs for the team
    function reserveNFTs() public onlyOwner {
        uint256 startTokenId = totalSupply();
        require(startTokenId.add(RESERVED) < MAX_SUPPLY, "SuperGiants: not enough NFTs available");
        for (uint256 i = 0; i < RESERVED; i++) {
            _safeMint(msg.sender, RESERVED);
        }
    }

    // ------------------------------------------------------------------------
    // TOKEN URI
    // ------------------------------------------------------------------------

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // allow to change the token URI whenever needed
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // ------------------------------------------------------------------------
    // WITHDRAW
    // ------------------------------------------------------------------------

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "SuperGiants: No ether left to withdraw");
        payable(msg.sender).transfer(balance);
    }

    // ------------------------------------------------------------------------
    // CEO GAME
    // ------------------------------------------------------------------------

    function sendMoneyToWinners(address[] calldata addresses, uint256[] calldata quantity) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            payable(addresses[i]).transfer(quantity[i]);
        }
    }

}
