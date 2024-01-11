// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

/*
 ____  __  __  ___  _  _____ _   _ _   ____  _____    _    ____   _____
/ ___||  \/  |/ _ \| |/ /_ _| \ | ( ) | __ )| ____|  / \  |  _ \ |__  /
\___ \| |\/| | | | | ' / | ||  \| |/  |  _ \|  _|   / _ \ | |_) |  / /
 ___) | |  | | |_| | . \ | || |\  |   | |_) | |___ / ___ \|  _ <  / /_
|____/|_|  |_|\___/|_|\_\___|_| \_|   |____/|_____/_/   \_\_| \_\/____|
*/

contract SmokinBearz is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    string public baseURI;

    uint256 public constant maxTotalSupply = 10000;
    uint256 public maxMintAmount = 7;
    uint256 public mintCost = 0.3 ether;
    uint256 public constant whitelistMintMaxAmount = 3;
    uint256 public constant maxPremintAmount = 125;
    bool public mintingPaused = true;
    bool public whitelistEnabled = true;
    string public baseSuffix = ".json";
    mapping(bytes32 => uint8) public whitelistMintCount;

    address public wlSignatureAddress =
        0x456B5C3cE9Cf5d43E8B7e2AaF3c0d8a5dd427B82;

    constructor(string memory _baseURI) ERC721A("Smokin' Bearz", "SBC") {
        baseURI = _baseURI;
    }

    function reservedMint(uint8 quantity) external onlyOwner {
        uint256 supply = totalSupply();
        require(mintingPaused, "Minting must be paused");
        require((supply + quantity) <= maxTotalSupply, "Not enough NFTs");
        require((supply + quantity) <= maxPremintAmount);
        _safeMint(msg.sender, quantity);
    }

    function mint(uint8 quantity) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(!mintingPaused, "Minting is currently paused");
        require(!whitelistEnabled, "Whitelist is enabled");
        require(quantity <= maxMintAmount, "Can not mint that amount");
        require((supply + quantity) <= maxTotalSupply, "Not enough NFTs");
        require(msg.value >= (mintCost * quantity), "Not enough ether");

        _safeMint(msg.sender, quantity);
    }

    function whitelistMint(
        uint8 quantity,
        bytes32 discordIdHash,
        bytes calldata signature
    ) external payable nonReentrant {
        uint256 supply = totalSupply();

        require(!mintingPaused, "Minting is currently paused");
        require(whitelistEnabled, "Whitelist is not enabled");
        require(quantity <= whitelistMintMaxAmount, "Can not mint that amount");
        require((supply + quantity) <= maxTotalSupply, "Not enough NFTs");
        require(msg.value >= (mintCost * quantity), "Not enough ether");

        bytes32 digest = keccak256(abi.encodePacked(
            discordIdHash,
            block.chainid,
            msg.sender
        )).toEthSignedMessageHash();

        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == wlSignatureAddress, "Invalid signature");

        uint256 mintCount = whitelistMintCount[discordIdHash];
        require(mintCount + quantity <= whitelistMintMaxAmount,
                "Attempt to mint too many");
        _safeMint(msg.sender, quantity);
        whitelistMintCount[discordIdHash] += quantity;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{ value: address(this).balance }("");
        require(os, "Withdraw failed");
    }

    function tokenURI(uint256 tokenId) public view virtual override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), baseSuffix))
            : "";
    }


    function setMintingPaused(bool _mintingPaused) public onlyOwner {
        mintingPaused = _mintingPaused;
    }

    function setWhitelistEnabled(bool _whitelistEnabled) public onlyOwner {
        whitelistEnabled = _whitelistEnabled;
    }

    function setMintCost(uint256 _mintCost) public onlyOwner {
        mintCost = _mintCost;
    }

    function setSignatureAddress(address _wlSignatureAddress) public onlyOwner {
        wlSignatureAddress = _wlSignatureAddress;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setBaseSuffix(string memory _baseSuffix) public onlyOwner {
        baseSuffix = _baseSuffix;
    }
}

