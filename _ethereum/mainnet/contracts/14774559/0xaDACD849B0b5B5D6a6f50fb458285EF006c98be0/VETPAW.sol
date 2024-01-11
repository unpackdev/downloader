//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract THEGUARDIAN is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 500;
    uint256 public presaleMaxSupply = 250;
    uint256 public price = 0.15 ether;
    uint256 public presalePrice = 0.1 ether;


    address private whitelistAddress = 0x018cF2d70F43aB1F4bf9b5FfA432a7A3A12D15E5;

    uint256 public saleStart = 1653191940;
    uint256 public presaleStart = 1652587140;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public presaleMinted;

    address[] private team_ = [ 0x25b619B7efd562b8EC2C3D27C47D61727008d799 ];
    uint256[] private teamShares_ = [100];

    constructor() ERC721A("THEGUARDIAN", "GUARD") PaymentSplitter(team_, teamShares_) {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmVxqV3XA4poWTh4xoNvjeJRYaDycL7nNz41zwb9kwhzbU");
        _safeMint(msg.sender, 1); // To configure OpenSea correctly
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

    function setPresaleStart(uint256 _newStart) public onlyOwner {
        presaleStart = _newStart;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
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
            presaleStart > 0 && block.timestamp >= presaleStart,
            "THEGUARDIAN: Whitelist mint is not started yet!"
        );
        require(
            block.timestamp < saleStart,
            "THEGUARDIAN: Whitelist mint is finished!"
        );
        require(
            presaleMinted[msg.sender] + amount <= max,
            "THEGUARDIAN: You can't mint more NFTs!"
        );
        require(
            supply + amount <= presaleMaxSupply,
            "THEGUARDIAN: PRESALE SOLD OUT!"
        );
        require(
            msg.value >= presalePrice * amount,
            "THEGUARDIAN: Insuficient funds"
        );

        presaleMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "THEGUARDIAN: Sold out!");
        require(
            saleStart > 0 && block.timestamp >= saleStart,
            "THEGUARDIAN: public sale not started."
        );
        require(
            msg.value >= price * amount,
            "THEGUARDIAN: Insuficient funds"
        );

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "THEGUARDIAN: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function forceMint(uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            "THEGUARDIAN: You can't mint more than max supply"
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