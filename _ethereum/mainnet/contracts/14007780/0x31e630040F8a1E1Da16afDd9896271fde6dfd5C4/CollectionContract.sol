// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./console.sol";

contract CollectionContract is ERC721Tradable {
    using Strings for uint256;
    uint256 public cost = 0.05 ether;
    uint256 public presaleCost = 0.03 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10000;
    bool public launched = false;
    bool public paused = false;
    mapping(address => bool) public noFeeWallets;
    mapping(address => bool) public presaleWallets;

    constructor(address _proxyRegistryAddress) ERC721Tradable("Sheepzy", "SHPZY", _proxyRegistryAddress) {
    }

    function baseTokenURI() override public pure returns (string memory) {
        return 'ipfs://QmeyFkV9qrvcRzsvxB7pjzQ9RivKXThwHyBv6ZpWryrKNi/';
    }

    function _baseURI() internal pure override returns (string memory) {
        return baseTokenURI();
    }

    function contractURI() public pure returns (string memory) {
        return 'https://us-central1-sheepzynft.cloudfunctions.net/openseameta/';
    }

    function remainingSupply() public view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
        bytes(currentBaseURI).length > 0
        ? string(
            abi.encodePacked(
                currentBaseURI,
                tokenId.toString(),
                '.json'
            )
        )
        : "";
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, 'Mint amount must be a positive number');
        require(_mintAmount <= maxMintAmount, 'Amount exceeds the maximum mints allowed for this wallet.');
        require(supply + _mintAmount <= maxSupply, 'Insufficient supply.');
        require(!paused || msg.sender == owner(), 'Minting is currently paused');
        if (msg.sender != owner() && !noFeeWallets[msg.sender]) {
            if (launched) {
                //general public
                require(msg.value >= cost * _mintAmount, 'Insufficient ETH supplied');
            } else {
                //presale
                require(presaleWallets[msg.sender], 'Only presale buyers are allowed at the moment.');
                require(msg.value >= presaleCost * _mintAmount, 'Insufficient ETH supplied');
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mintNext(_to);
        }
    }

    //only owner
    function launchCollection() public onlyOwner {
        require(!launched, 'Collection is already launched.');
        launched = true;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function addNoFeeUser(address _user) public onlyOwner {
        noFeeWallets[_user] = true;
    }

    function removeNoFeeUser(address _user) public onlyOwner {
        noFeeWallets[_user] = false;
    }

    function addPresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = true;
    }

    function add100PresaleUsers(address[100] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 100; i++) {
            if (_users[i] == address(0)) break;
            presaleWallets[_users[i]] = true;
        }
    }

    function removePresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success,) = payable(msg.sender).call{
        value : address(this).balance
        }("");
        require(success);
    }
}
