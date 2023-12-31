// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./IERC721AQueryable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./DefaultOperatorFilterer.sol";


contract theclassiques is ERC721A, ERC721AQueryable, DefaultOperatorFilterer, Ownable {

    string public baseURI = "ipfs://bafybeidlsiwb5jetffwz62hudx4sqp3tege2dwoumj2g65gmb3fj5d2teq/";
    uint256 public degentsPrice = 0.001 ether;
    uint256 public publicPrice = 0.003 ether;
    uint256 public maxSupply = 2048;
    uint256 public degMaxPerTransaction = 10;
    uint256 public pubMaxPerTransaction = 3;
    uint256 public degMaxPerWallet = 10;
    uint256 public pubMaxPerWallet = 6;
    address public degents = 0x0F6979e74E4aF9aBeD72298D818A2434fE0b95B6;

    bool public degSaleActive;
    bool public pubSaleActive;
    
    mapping(address => uint256) private redeemedTokens;
    
    constructor () ERC721A("theclassiques", "classq") {
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function startDegSale() external onlyOwner {
        require(degSaleActive == false);
        degSaleActive = true;
    }

    function stopDegSale() external onlyOwner {
        require(degSaleActive == true);
        degSaleActive = false;
    }

    function startPubSale() external onlyOwner {
        require(pubSaleActive == false);
        pubSaleActive = true;
    }

    function stopPubSale() external onlyOwner {
        require(pubSaleActive == true);
        pubSaleActive = false;
    }

    function degentsMint(uint256 amount) public payable {
            require(degSaleActive);
            require(IERC721A(degents).balanceOf(msg.sender) > 0, "You must own degents for early sale and discount price. aye?");
            require(_numberMinted(msg.sender) + amount <= degMaxPerWallet);
            require(amount <= degMaxPerTransaction);
            uint256 totalPrice = degentsPrice * amount;
            require(msg.value >= totalPrice, "Insufficient funds");
            require(totalSupply() + amount <= maxSupply);
            _safeMint(msg.sender, amount);
            redeemedTokens[msg.sender] += amount;
    }

    function publicMint(uint256 amount) public payable {
            require(pubSaleActive);
            require(_numberMinted(msg.sender) + amount <= pubMaxPerWallet);
            require(amount <= pubMaxPerTransaction);
            uint256 totalPrice = publicPrice * amount;
            require(msg.value >= totalPrice, "Insufficient funds");
            require(totalSupply() + amount <= maxSupply);
            _safeMint(msg.sender, amount);
            redeemedTokens[msg.sender] += amount;
    }


    function setDegentsPrice(uint256 newPrice) public onlyOwner {
        degentsPrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function cutSupply(uint256 newSupply) public onlyOwner {
        maxSupply = newSupply;
    }

    function setPubMaxPerTransaction(uint256 newmaxPerTransaction) public onlyOwner {
        pubMaxPerTransaction = newmaxPerTransaction;
    }

    function setPubMaxPerWallet(uint256 newmaxPerWallet) public onlyOwner {
        pubMaxPerWallet = newmaxPerWallet;
    }

    function setDegMaxPerTransaction(uint256 newmaxPerTransaction) public onlyOwner {
        degMaxPerTransaction = newmaxPerTransaction;
    }

    function setDegMaxPerWallet(uint256 newmaxPerWallet) public onlyOwner {
        degMaxPerWallet = newmaxPerWallet;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply);
        _safeMint(msg.sender, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
    require(recipients.length == amounts.length, "Invalid input: recipients and amounts length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
            _safeMint(recipient, amount);
        }
    }
}