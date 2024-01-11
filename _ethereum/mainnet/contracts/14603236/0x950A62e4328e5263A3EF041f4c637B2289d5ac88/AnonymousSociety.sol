//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract AnonymousSociety is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 999;
    uint256 public price = 0.15 ether;
    uint256 public presalePrice = 0.13 ether;
    uint256 public maxMintable = 4;

    address private whitelistAddress = 0xC71a6328F29CA9A1bF8D6243c6544fd8E0552071;

    uint256 public saleStart = 1650225540;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public tokensMinted;

    address[] private team_ = [ 0x578e573B9e43E978FaCE7d66c9B89A629F5d9c1a,
                                0xcd7A6bBf30Ee54Eb2CcFdfE2b8f844d8C2017724
                                ];
    uint256[] private teamShares_ = [97, 3];

    constructor() ERC721A("AnonymousSociety", "AS") PaymentSplitter(team_, teamShares_) {
        setBaseURI("ipfs://QmZ9sTs9W81SQ9NhMZXU6AdbysUAGwTdJEjkqEYQFKAQYn/");
        setNotRevealedURI("");
        reveal();
        _safeMint(msg.sender, 1);
    }

    modifier whenNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    //GETTERS

    function getSaleStart() public view returns (uint256) {
        return saleStart;
    }

    function getSalePrice() public view returns (uint256) {
        return price;
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    //END GETTERS

    //SETTERS

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }

    function setSaleStart(uint256 _newStart) public onlyOwner {
        saleStart = _newStart;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintable(uint256 _maxMintable) public onlyOwner {
        maxMintable = _maxMintable;
    }

    function switchPause() public onlyOwner {
        paused = !paused;
    }

    //END SETTERS

    //SIGNATURE VERIFICATION

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

    //END SIGNATURE VERIFICATION

    //MINT FUNCTIONS

    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                whitelistAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            saleStart > 0 && block.timestamp >= saleStart,
            "Anonymous Society: Whitelist mint is not started yet!"
        );
        require(
                tokensMinted[msg.sender] + amount <= max,
            "Anonymous Society: You can't mint more NFTs!"
        );
        require(
            supply + amount <= maxSupply,
            "Anonymous Society: SOLD OUT!"
        );
        require(
            msg.value >= presalePrice * amount,
            "Anonymous Society: Insuficient funds"
        );

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "Anonymous Society: Sold out!");
        require(
            saleStart > 0 && block.timestamp >= saleStart,
            "Anonymous Society: public sale not started."
        );
        require(
            msg.value >= price * amount,
            "Anonymous Society: Insuficient funds"
        );
        require(
            tokensMinted[msg.sender] + amount <= maxMintable,
            "Anonymous Society: You cannot mint more NFTs"
        );

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "Anonymous Society: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function forceMint(uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            "Anonymous Society: You can't mint more than max supply"
        );

        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
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