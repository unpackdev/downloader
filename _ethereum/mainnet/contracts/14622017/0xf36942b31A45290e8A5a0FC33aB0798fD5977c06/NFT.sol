// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// Contract: Stoned Sloths
// Author: Seth Kawalec
// ---- CONTRACT BEGINS HERE ----

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public baseURI =
        "https://gateway.pinata.cloud/ipfs/QmZbuPCPj8wseDnDGi4rQLdYEJTuLPQZTNq57HjgGgJtyG/";
    string public baseExtension = ".json";
    uint256 public presalePrice = 0.06 ether;
    uint256 public presaleAmount = 250;
    uint256 public normalPrice = 0.09 ether;
    uint256 public maxSupply = 999;
    uint256 public maxMintAmount = 5;
    bool public paused = false;
    uint256 public walletLimit = 5;
    address public OwnerWallet = 0x4e7C0863c075f29fd6a6629b6dA777C92f68e61d;
    address public MarketingWallet = 0x7B3b9CFE3A883fdAdD61CD454cBe41f29a2Af2Af;
    uint256 public duration = 7 days;
    uint256 public endedTime;
    uint256 public startTime;

    constructor() ERC721("Stoned Sloths", "STOSLO") {
        startTime = block.timestamp;
        endedTime = startTime + duration;
    }

    modifier endDuration() {
        require(block.timestamp > endedTime, "Not Yet");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused, "Mint Paused.");
        require(_mintAmount > 0, "You can't mint zero NFT.");
        require(
            _mintAmount <= maxMintAmount,
            "You can't mint more then Max Mint Amount at once."
        );
        require(supply + _mintAmount <= maxSupply, "You can't mint more then ");
        require(
            (balanceOf(msg.sender) + _mintAmount) <= walletLimit,
            "Wallet limit is reached."
        );

        uint256 totalPrice = 0;
        if (supply + _mintAmount <= presaleAmount)
            totalPrice = presalePrice * _mintAmount;
        if (supply < presaleAmount && supply + _mintAmount > presaleAmount)
            totalPrice =
                presalePrice *
                (presaleAmount - supply) +
                normalPrice *
                (supply + _mintAmount - presaleAmount);
        if (supply >= presaleAmount) totalPrice = normalPrice * _mintAmount;
        require(msg.value >= totalPrice, totalPrice.toString());

        for (uint256 i; i < _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent Boo Crew NFT"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setWalletLimit(uint256 _newWalletLimit) public onlyOwner {
        walletLimit = _newWalletLimit;
    }

    function setMaxMintAmountAndWalletLimit(
        uint256 _newmaxMintAmount,
        uint256 _newWalletLimit
    ) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
        walletLimit = _newWalletLimit;
    }

    // This sets the max supply. This will be set to 10,000 by default, although it is changable.
    function setMaxSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setDuration(uint256 amount) public onlyOwner {
        duration = amount * 10 minutes;
        endedTime = startTime + duration;
    }

    function payReward(address to, uint256 amount)
        public
        endDuration
        onlyOwner
    {
        require(payable(to).send(amount));
    }

    function withdraw() public endDuration {
        if (msg.sender == OwnerWallet)
            require(
                payable(msg.sender).send(
                    (address(this).balance * uint256(80)) / uint256(100)
                )
            );
        if (msg.sender == MarketingWallet)
            require(
                payable(msg.sender).send(
                    (address(this).balance * uint256(20)) / uint256(100)
                )
            );
    }
}
