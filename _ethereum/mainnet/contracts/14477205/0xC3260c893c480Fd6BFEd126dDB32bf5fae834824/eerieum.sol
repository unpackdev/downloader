// SPDX-License-Identifier: MIT
// Creator: LIBC (https://liblockchain.org)
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

 /*
  <__>
   ||____________________________
   ||############################|
   ||############################|
   ||############################|
   ||############################|
   ||############################|
   ||::::::::::::::::::::::::::::|
   ||::::::::::::::::::::::::::::|
   ||::::::::::::::::::::::::::::|
   ||::::::::::::::::::::::::::::|
   ||::::::::::::::::::::::::::::|
   ||~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ||
   || National Flag of the Ukraine
   || Peace for Ukraine
   ||
   ||   # (blue)   : (yellow)
*/

contract Eerieum is ERC721A, Ownable, ReentrancyGuard {

    uint256 public immutable amountForDevs;
    uint256 public immutable amountForSaleAndDev;
    uint256 public immutable collectionSize;
    uint256 public maxPerAddressDuringMint;
    uint256 public price;

    mapping(address => uint256) public allowlist;
    
    string private _baseTokenURI;
    string private _contractMeta;

    address private _royaltyAddr;
    uint256 private _royaltyBps;

    bool public hasSaleStarted;

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForSaleAndDev_,
        uint256 amountForDevs_,
        uint256 price_,
        string memory contractMeta_,
        string memory baseURI_) ERC721A("PeaceForUkraine", "PEACE") {
        _contractMeta = contractMeta_;
        _baseTokenURI = baseURI_;

        maxPerAddressDuringMint = maxBatchSize_;
        amountForSaleAndDev = amountForSaleAndDev_;
        amountForDevs = amountForDevs_;
        collectionSize = collectionSize_;
        price = price_;
        hasSaleStarted = false;

        require(
            amountForSaleAndDev_ <= collectionSize_,
            "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity) external payable {
        require(hasSaleStarted == true, "Sale has not started");
        require(
            totalSupply() + quantity <= amountForSaleAndDev,
            "not enough remaining reserved for sale to support desired mint amount"
        );
        require(
            quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );

        uint256 totalCost = price * quantity;

        require(
            msg.value >= totalCost,
            "not enough ETH sent to mint"
        );
        
        _safeMint(msg.sender, quantity);

        refundIfOver(price);
    }
    
    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxPerAddressDuringMint(uint256 maxPerAddressDuringMint_) external onlyOwner {
        maxPerAddressDuringMint = maxPerAddressDuringMint_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractMeta;
    }

    function setContractURI(string memory uri) public {
        _contractMeta = uri;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function allowlistMint() external payable callerIsUser {
        require(price != 0, "allowlist sale has not begun yet");
        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
        refundIfOver(price);
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
        require(
            addresses.length == numSlots.length,
            "addresses does not match numSlots length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function refundIfOver(uint256 price_) private {
        require(msg.value >= price_, "Need to send more ETH.");

        if (msg.value > price_) {
            payable(msg.sender).transfer(msg.value - price_);
        }
    }

    function royaltyInfo(uint256 tokenId_, uint256 value_) public view returns (address _reciever, uint256 _royaltyAmount) {
        return (_royaltyAddr, _royaltyBps);
    }

    function setRoyalty(uint256 bps, address distAddress) external onlyOwner {
        _royaltyBps = bps;
        _royaltyAddr = distAddress;
    }

    function startSale() external onlyOwner  {
        hasSaleStarted = true;
    }

    function pauseSale() external onlyOwner  {
        hasSaleStarted = false;
    }

    // Support the Royalties Interface ERC-2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return interfaceId == 0x2a55205a // ERC-2981
            || super.supportsInterface(interfaceId);
    }
}