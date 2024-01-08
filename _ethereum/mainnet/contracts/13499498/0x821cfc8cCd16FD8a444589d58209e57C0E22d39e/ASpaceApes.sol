// SPDX-License-Identifier: GPL-3.0-only

/**
    ASpace Apes (ASA) is an exclusive collection of 5,050 NFTs that govern the Aspace decentralized social network, provide travel perks & real-life rewards,
    and produce $AETH for holders in the Aspace Ecosystem.
    Created by the Aspace Development Team. Welcome to the future of decentralized social networks ;-)
    // https://aspaceape.com // https://aspace.app
    Based on generative-art-node, maintained by @HashLips. Thanks for everything, you south-african madman.
        --The AspaceApe development team
*/

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract ASpaceApes is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public maxSupply = 5050;
    uint256 public maxMintAmount = 20;
    bool public paused = true;
    bool public revealed = false;
    string public notRevealedUri;
    // SpaceApe update 0.3: Adding whitelisting tiers!
    bool private whitelistEnabled = true;
    mapping(address => bool) public bronzeWhitelist;
    mapping(address => bool) public silverWhitelist;
    mapping(address => bool) public goldWhitelist;
    mapping(address => uint256) public howManyMinted;
    
    uint256 private bronzeCost = 0.04 ether;
    uint256 private silverCost = 0.03 ether;
    uint256 private goldCost = 0.025 ether;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    /* ####### Internals ######## */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
  
    /* ####### Privates (heh) ######## */
    function isOwner() internal view returns (bool) {
        if(msg.sender == owner()) {
            return true;
        }
        return false;
    }

    /* ####### Publics ######## */
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused || isOwner(), "Space Apes are paused, please wait and stay updated on our Discord!");
        require(_mintAmount > 0, "You can't mint 0 Space Apes!");
        require(_mintAmount <= maxMintAmount || isOwner(), "Only 20 mints allowed at a time!");
        require(supply + _mintAmount <= maxSupply, "Sorry, Space Apes has finished its launch minting! You can still buy them on OpenSea!");

        if (!isOwner()) {
            if(whitelistEnabled) {
                require(
                    goldWhitelist[msg.sender] || silverWhitelist[msg.sender] || bronzeWhitelist[msg.sender],
                    "Space Apes are still in WHITELISTED-ONLY mode, only whitelisters allowed for now, please wait!"
                    );
                require(howManyMinted[msg.sender] + _mintAmount <= 5, "You can't mint more than 5 Space Apes, whitelister!");
                
                if(goldWhitelist[msg.sender]){
                    require(msg.value >= goldCost * _mintAmount, "You need to pay in multiples of 0.025 ETH, gold whitelister!");
                }
                else if(silverWhitelist[msg.sender]){
                    require(msg.value >= silverCost * _mintAmount, "You need to pay in multiples of 0.03 ETH, silver whitelister!");
                }
                else if(bronzeWhitelist[msg.sender]){
                    require(msg.value >= bronzeCost * _mintAmount, "You need to pay in multiples of 0.04 ETH, bronze whitelister!");
                }
            }
            else {
                require(msg.value >= cost * _mintAmount);
            }
            
            howManyMinted[msg.sender] = howManyMinted[msg.sender] + _mintAmount;
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        
        if(!revealed) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    /* ####### OnlyOwner functions ######## */
    function reveal() public onlyOwner() {
        revealed = true;
    }
  
    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }
  
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function setWhitelistEnabled(bool toggle) public onlyOwner {
        whitelistEnabled = toggle;
    }
    
    function addToWhitelist(address[] memory addrs, uint256 id) public onlyOwner {
        require(id >= 0 && id < 3, "Whitelist ID out of bounds.");
  
        if(id == 0) {
            for (uint i = 0; i < addrs.length; i++) {
                goldWhitelist[addrs[i]] = true;
            }
        }
        else if(id == 1) {
            for (uint i = 0; i < addrs.length; i++) {
                silverWhitelist[addrs[i]] = true;
            }
        }
        else if(id == 2) {
            for (uint i = 0; i < addrs.length; i++) {
                bronzeWhitelist[addrs[i]] = true;
            }
        }
    }
 
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}
