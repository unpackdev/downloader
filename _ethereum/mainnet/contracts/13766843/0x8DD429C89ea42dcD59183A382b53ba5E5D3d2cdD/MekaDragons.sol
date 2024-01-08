// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract MekaDragons is ERC721Enumerable, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    uint256 private constant MAX_SALE_SUPPLY = 5000;
    uint256 private constant MAX_PRESALE = 1500;
    uint256 public constant MAX_SELF_MINT = 10; // Might change
    uint256 public constant MAX_PRESALE_MINT = 2; // Might change
    uint256 public constant PRESALE_PRICE = 0.1 ether;
    uint256 public constant TEAM_RESERVE = 25; //Might change

    uint256 private publicSalePrice = 0.2 ether;

    //Placeholder
    address private presaleAddress = 0xDFc148B90146dA2ee5BD0b5B341dAE46C1576a87;
    address private giftAddress = 0xdDBA858bA06bbcA4df4fcfD430d3813E36fE64A0;

    uint256 private presaleCount;
    uint256 public saleStart;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;

    bool private teamReserved;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal,
        Paused
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;
    mapping(address => bool) public premintClaimed;

    //Placeholders, shall be changed to the real team addresses and shares
    address[] private team_ = [
        0xB7D903cBA1165CbE48bA92957aBEc48386fEE987,
        0xbAAbDA55A4C7aF05E10cF51E61fF14c723fC3530,
        0x3662324b4bB5E437eD53d7e1BD1595CB84f94e61,
        0x67768e0359B87c7421BFAcB7e097cf9F1a4aa2a1,
        0xC47Bda148A023Ef85460bedaa7eDE8E22E68E377,
        0x36056c6794504Bf33CAfE9140D9Ee4e35F8f1c0F
    ];
    uint256[] private teamShares_ = [455, 455, 50, 30, 5, 5];

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721("MekaDragons", "MKD")
        PaymentSplitter(team_, teamShares_)
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    //GETTERS

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function getSalePrice() public view returns (uint256) {
        return publicSalePrice;
    }

    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(uint256 number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(number, sender));
    }

    /**
        Claims tokens for free paying only gas fees
     */
    function preMint(
        uint256 number,
        bytes32 messageHash,
        bytes calldata signature
    ) external virtual {
        require(
            hashMessage(number, msg.sender) == messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifyAddressSigner(giftAddress, messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            premintClaimed[msg.sender] == false,
            "MekaDragons: You already claimed your premint NFTs."
        );

        premintClaimed[msg.sender] = true;

        for (uint256 i = 0; i < number; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    /**
        Mints reserve for the team. Only callable once. Amount fixed.
     */
    function teamReserve() external onlyOwner {
        require(teamReserved == false, "MekaDragons: Team already reserved");
        teamReserved = true;
        for (uint256 i = 0; i < TEAM_RESERVE; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function presaleMint(
        uint256 number,
        bytes32 messageHash,
        bytes calldata signature
    ) external payable {
        require(number > 0, "You must mint at least one token");
        require(
            hashMessage(number, msg.sender) == messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifyAddressSigner(presaleAddress, messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            workflow == WorkflowStatus.Presale,
            "MekaDragons: Presale is not started yet!"
        );
        require(block.timestamp < saleStart, "Presale has ended.");
        require(
            tokensPerWallet[msg.sender] + number <= MAX_PRESALE_MINT,
            "MekaDragons: You can only mint 2 NFTs at presale."
        );
        require(
            presaleCount + number <= MAX_PRESALE,
            "MekaDragons: PRESALE SOLD OUT"
        );
        require(
            msg.value >= PRESALE_PRICE * number,
            "MekaDragons: INVALID PRICE"
        );

        tokensPerWallet[msg.sender] += number;
        presaleCount += number;

        for (uint256 i = 0; i < number; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function publicSaleMint(uint256 amount) external payable {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(workflow != WorkflowStatus.SoldOut, "MekaDragons: SOLD OUT!");
        require(
            supply + amount <= MAX_SALE_SUPPLY,
            "MekaDragons: Mint too large!"
        );
        require(
            workflow != WorkflowStatus.Paused,
            "MekaDragons: public sale is paused."
        );
        require(
            block.timestamp >= saleStart,
            "MekaDragons: public sale is not started yet"
        );
        require(
            msg.value >= publicSalePrice * amount,
            "MekaDragons: Insuficient funds"
        );
        require(
            amount <= MAX_SELF_MINT,
            "MekaDragons: You can only mint up to ten NFTs at once!"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= MAX_SELF_MINT,
            "MekaDragons: You already minted 10 NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        if (supply + amount == MAX_SALE_SUPPLY) {
            workflow = WorkflowStatus.SoldOut;
        }
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function forceMint(uint256 number) external onlyOwner{

        require(totalSupply() + number <= MAX_SALE_SUPPLY, "MekaDragons: You can't mint more than max supply");

        for (uint256 i = 0; i < number; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }

    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
        saleStart = block.timestamp + 24 hours;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    /**
        Automatic reveal is too dangerous : manual reveal is better. It allows much more flexibility and is the reveal is still instantaneous.
        Note that images on OpenSea will take a little bit of time to update. This is OpenSea responsability, it has nothing to do with the contract.    
     */
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setGiftAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        giftAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }
}
