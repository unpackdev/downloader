// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";
import "./IERC721A.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ERC2981.sol";



contract Spy is ERC721AQueryable, Ownable, ERC2981 {
    using Strings for uint256;
    string public baseURI;

    bool public preSaleOpen = false;
    bool public publicSaleOpen = false;

    uint16 public maxSupplyAmount = 10000;
    uint256 public preSalePrice = 0.02 ether;
    uint256 public publicSalePrice = 0.05 ether;

    // per account
    uint32 public maxPreSaleMint = 1000;
    uint8 public maxPreSaleMintPerAddr = 10;
    uint8 public maxPublicSaleMint = 20;

    address public signer = 0xAfecCABA00fAfb6596047a08e7Ff0d5fe40d2bf2;
    string public notRevealedURI = "https://spybubby.s3.amazonaws.com/SpyXpets.metadata.json";
    bool public revealed = false;

    //pre sale minted
    mapping (address => uint16) public preSaleMinted;

    //public sale minted
    mapping (address => uint16) public publicSaleMinted;

    constructor(
    ) ERC721A("Crypto SPY Bubby", "CSB") {
        setFeeNumerator(500);
    }

    /*************************************** public **********************/
    function preSaleMint(uint16 amount, bytes memory signature) external payable {
        require(preSaleOpen, "PRE SALE HAS NOT OPEN YET");
        require(_numberMinted(msg.sender) + amount <= maxPreSaleMintPerAddr, "SORRY, EXCEED THE MAXIMUM NUMBER OF MINT");
        require(totalSupply() + amount <= maxPreSaleMint, "REACHED MAX SUPPLY AMOUNT");
        require(signer == signatureWallet(msg.sender, signature), "NOT AUTHORIZED TO PRE SALE MINT");

        // require(preSaleMinted[msg.sender] + amount <= maxPreSaleMintPerAddr, "REACHED MAX PRE SUPPLY AMOUNT") ;
        
        uint256 payAmount = preSaleMinted[msg.sender] > 0 ? amount : amount - 1;
        
        uint256 requirePay = payAmount * preSalePrice;

        require(msg.value >= requirePay, "INSUFFICIENT ETH AMOUNT");
        if (msg.value > requirePay) {
            payable(msg.sender).transfer(msg.value - requirePay);
        }

        preSaleMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint16 amount) external payable {
        require(publicSaleOpen, "PUBLIC SALE HAS NOT OPEN YET");
        require(totalSupply() + amount <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");

        uint16 mintedAmount = publicSaleMinted[msg.sender];
        require(mintedAmount + amount <= maxPublicSaleMint, "EXCEEDS MAX PUBLIC SALE MINT");
        require(msg.value >= amount * publicSalePrice, "INSUFFICIENT ETH AMOUNT");
        if (msg.value > amount * publicSalePrice) {
            payable(msg.sender).transfer(msg.value - amount * publicSalePrice);
        }
        publicSaleMinted[msg.sender] = mintedAmount + amount;
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed == false) {
            return notRevealedURI;
        }

        string memory currentBaseURI = baseURI;
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    struct Status {
        bool preSaleOpen;
        bool publicSaleOpen;

        uint256 preSalePrice;
        uint256 publicSalePrice;

        // per account
        uint256 maxPreSaleMintPerAddr;
        uint256 maxPublicSaleMint;
        uint256 maxSupply;
        uint16 userMintedPreSale;
        uint16 userMintedPublicSale;
        bool soldout;
    }

    function status(address minter) external view returns (Status memory) {
        return Status({
            preSaleOpen: preSaleOpen,
            publicSaleOpen: publicSaleOpen,
            preSalePrice: preSalePrice,
            publicSalePrice: publicSalePrice,

            maxPreSaleMintPerAddr: maxPreSaleMintPerAddr,
            maxPublicSaleMint: maxPublicSaleMint,
            maxSupply: maxSupplyAmount,

            userMintedPreSale: preSaleMinted[minter],
            userMintedPublicSale: publicSaleMinted[minter],
            soldout: totalSupply() >= maxSupplyAmount
        });
    }

    /*************************************** private **********************/
    function signatureWallet (address sender, bytes memory signature) private pure returns (address){
            bytes32 hash = keccak256(
                abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender))
                )
            );
            return ECDSA.recover(hash, signature);
    }

    /*************************************** onlyOwner **********************/
    function giftMint(address xer, uint256 amount) external onlyOwner {
        require(amount > 0, "GIFT AT LEAST ONE");
        require(amount + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
        _safeMint(xer, amount);
    }

    function setNotRevealedURI(string memory newNotRevealedURI) external onlyOwner {
        notRevealedURI = newNotRevealedURI;
    }

    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    //setting
    function togglePreSale() external onlyOwner {
        preSaleOpen = !preSaleOpen;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setPreSalePrice(uint256 newPreSalePrice) external onlyOwner {
        preSalePrice = newPreSalePrice;
    }

    function setPublicSalePrice(uint256 newPublicSalePrice) external onlyOwner {
        publicSalePrice = newPublicSalePrice;
    }

    function setSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    //withdraw
    address private wallet1 = 0x5Df9355C5A8FD35D681aCaDEd9694D8bd5a02913;
    address private wallet2 = 0x7e1E3A55214e10Def23f62aCac197cFB3C5B7d0e;
    address private wallet3 = 0xb3a0672FAA993eED6a785a89346E61Dd64Ae8caB;
    address private wallet4 = 0xb3a0672FAA993eED6a785a89346E61Dd64Ae8caB;

    function withdraw(uint256 pay4) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "NOT ENOUTH BALANCE TO WITHDRAW");
        require(balance > pay4, "NOT ENOUTH BALANCE TO WITHDRAW");

        balance = balance - pay4;
        uint256 pay1 = balance * 4 / 10;
        uint256 pay2 = balance * 3 / 10;
        uint256 pay3 = balance - pay1 - pay2;

        (bool success1, ) = payable(wallet1).call{value: pay1}("");
        require(success1, "Failed to withdraw to wallet1");

        (bool success2, ) = payable(wallet2).call{value: pay2}("");
        require(success2, "Failed to withdraw to wallet2");

        (bool success3, ) = payable(wallet3).call{value: pay3}("");
        require(success3, "Failed to withdraw to wallet3");

        (bool success4, ) = payable(wallet4).call{value: pay4}("");
        require(success4, "Failed to withdraw to wallet4");
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxPreSaleMint(uint32 _new) public onlyOwner {
        maxPreSaleMint = _new;
    }

    function setMaxPreSaleMintPerAddr(uint8 _new) public onlyOwner {
        maxPreSaleMintPerAddr = _new;
    }

    function setMaxPublicSaleMint(uint8 _new) public onlyOwner {
        maxPublicSaleMint = _new;
    }

    function setMaxSupplyAmount(uint16 _new) public onlyOwner {
        maxSupplyAmount = _new;
    }

    receive() external payable {}
}