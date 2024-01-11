// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//       ___           ___           ___       ___           ___           ___           ___                                 
//      /  /\         /  /\         /  /\     /  /\         /  /\         /  /\         /  /\          ___           ___     
//     /  /::\       /  /::\       /  /:/    /  /::\       /  /::|       /  /::\       /  /::|        /  /\         /__/\    
//    /  /:/\:\     /  /:/\:\     /  /:/    /  /:/\:\     /  /:|:|      /__/:/\:\     /  /:|:|       /  /::\        \  \:\   
//   /  /:/  \:\   /  /:/  \:\   /  /:/    /  /::\ \:\   /  /:/|:|__   _\_ \:\ \:\   /  /:/|:|__    /  /:/\:\        \__\:\  
//  /__/:/_\_ \:\ /__/:/ \__\:\ /__/:/    /__/:/\:\ \:\ /__/:/_|::::\ /__/\ \:\ \:\ /__/:/ |:| /\  /  /::\ \:\       /  /::\ 
//  \  \:\__/\_\/ \  \:\ /  /:/ \  \:\    \  \:\ \:\_\/ \__\/  /~~/:/ \  \:\ \:\_\/ \__\/  |:|/:/ /__/:/\:\ \:\     /  /:/\:\
//   \  \:\ \:\    \  \:\  /:/   \  \:\    \  \:\ \:\         /  /:/   \  \:\_\:\       |  |:/:/  \__\/  \:\_\/    /  /:/__\/
//    \  \:\/:/     \  \:\/:/     \  \:\    \  \:\_\/        /  /:/     \  \:\/:/       |__|::/        \  \:\     /__/:/     
//     \  \::/       \  \::/       \  \:\    \  \:\         /__/:/       \  \::/        /__/:/          \__\/     \__\/      
//      \__\/         \__\/         \__\/     \__\/         \__\/         \__\/         \__\/                                

import "./ERC721A.sol";
import "./Ownable.sol";

contract GolemsNFT is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public price = 0.002 ether;
    uint8 public mintsPerWallet;
    uint256 public maxSupply;

    bool public paused = true;
    bool public revealed = false;

    string public hiddenMetadataUri;
    string public baseURI;

    constructor(
        uint256 _maxSupply,
        uint8 _mintsPerWallet
    ) ERC721A("GolemsNFT", "GNFT") {
        maxSupply = _maxSupply;
        mintsPerWallet = _mintsPerWallet;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint8 _mintAmount) public payable {
        require(msg.value >= price * _mintAmount, "wrong ammount");
        require(!paused, "paused");
        require(
            _mintAmount + _numberMinted(msg.sender) <= mintsPerWallet,
            "minted too many"
        );
        require(_totalMinted() + _mintAmount <= maxSupply, "sold out");
        _safeMint(msg.sender, _mintAmount);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function remainingMints(address userAddress) public view returns (uint256) {
        return mintsPerWallet - _numberMinted(userAddress);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "token does not exist");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
