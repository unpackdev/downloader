// SPDX-License-Identifier: MIT
// @author: sphericon.io

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SpancsCollection is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    address public constant artistAddress = 0x13c4d22a8dbB2559B516E10FE0DE47ba4b4A03EB;

    Counters.Counter private _tokenIdTracker;

    struct Artwork {
        uint editions;
        uint id;
        string name;
        uint price;
        uint minted;
        uint[] burned;
        uint[] owned;
        bool publicSale;
    }

    struct MintedArtwork {
        uint edition;
        uint id;
    }

    uint currentId = 0;

    mapping (uint => Artwork) idToArtworkData;
    mapping (uint => MintedArtwork) tokenIdToArtwork;
    mapping (uint => address[]) burned;
    mapping (uint => address[]) preminted;
    string public _baseTokenURI;

    constructor() ERC721("Spancs Collections", "SpancsCollections") {}

    function requiredBurned(address wallet,uint id) public view returns(bool) {
        bool allTrue = true;
        if(idToArtworkData[id].burned.length == 0) return true;
        bool[] memory burnedCount = new bool[](idToArtworkData[id].burned.length);
        for(uint i = 0; i< idToArtworkData[id].burned.length; i++) {
            for(uint j = 0; j<burned[idToArtworkData[id].burned[i]].length; j++) {
                if(burned[idToArtworkData[id].burned[i]][j] == wallet) burnedCount[i] = true;
            }
        }
        for(uint i = 0; i< burnedCount.length; i++) {
            if(burnedCount[i] != true) allTrue = false;
        }
        return allTrue;
    }

        function didPremint(address wallet,uint id) public view returns(bool) {
            address[] memory premintedAdresses = preminted[id];
            for(uint i = 0; i< premintedAdresses.length; i++) {
                if(premintedAdresses[i] == wallet) return true;
            }
        }   

    function requiredOwned(address wallet, uint id) public view returns (bool) {
        bool allTrue = true;
        if(idToArtworkData[id].owned.length == 0) return true;
        bool[] memory ownedCount = new bool[](idToArtworkData[id].owned.length);
        uint[] memory ownerWallet = walletOfOwner(wallet);
        for(uint i = 0; i< idToArtworkData[id].owned.length; i++) {
            for(uint j = 0; j<ownerWallet.length; j++) {
                if(idToArtworkData[id].owned[i] == ownerWallet[j]) ownedCount[i] = true;
            }
        }
        for(uint i = 0; i< ownedCount.length; i++) {
            if(ownedCount[i] != true) allTrue = false;
        }
        return allTrue;
    }

        function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function addArtwork(uint _editions, string memory _name, uint _price, uint[] memory _burned, uint[] memory _owned) external onlyOwner {
        Artwork memory artwork = Artwork(_editions, currentId, _name, _price, 0, _burned, _owned, false);
        idToArtworkData[currentId] = artwork;
        currentId++;
    }

    function mintArtwork(uint id) external payable {
        require(idToArtworkData[id].publicSale, "SpancsCollection: Artwork can't be bought yet!");
        require(idToArtworkData[id].minted < idToArtworkData[id].editions, "SpancsCollection: This artwork is sold out!");
        require(requiredBurned(msg.sender, id), "SpancsCollection: You haven't burned the required artworks!");
        require(requiredOwned(msg.sender, id), "SpancsCollection: You don't own the required artworks!");
        require(msg.value >= idToArtworkData[id].price, "SpancsCollection: ETH sent is not enough!");
        uint tokenId = _tokenIdTracker.current();
        _mint(msg.sender, tokenId);
        MintedArtwork memory mintedArtwork = MintedArtwork(idToArtworkData[id].minted, id);
        tokenIdToArtwork[tokenId] = mintedArtwork;
        idToArtworkData[id].minted ++;
        _tokenIdTracker.increment();
    }

    function premintArtwork(uint id, bytes memory signature) external payable {
        require(isWhitelisted(signature, msg.sender), "SpancsCollection: You are not whitelisted for premint!");
        require(!didPremint(msg.sender, id), "SpancsCollection: You have already preminted this artwork!");
        require(idToArtworkData[id].minted < idToArtworkData[id].editions, "SpancsCollection: This artwork is sold out!");
        require(requiredBurned(msg.sender, id), "SpancsCollection: You haven't burned the required artworks!");
        require(requiredOwned(msg.sender, id), "SpancsCollection: You don't own the required artworks!");
        require(msg.value >= idToArtworkData[id].price/2, "SpancsCollection: ETH sent is not enough!");
        uint tokenId = _tokenIdTracker.current();
        _mint(msg.sender, tokenId);
        MintedArtwork memory mintedArtwork = MintedArtwork(idToArtworkData[id].minted, id);
        tokenIdToArtwork[tokenId] = mintedArtwork;
        idToArtworkData[id].minted ++;
        preminted[id].push(msg.sender);
        _tokenIdTracker.increment();
    }

    function giveaway(uint id, address to, uint amount) external onlyOwner {
        for(uint i; i < amount;  i++) {
            uint tokenId = _tokenIdTracker.current();
            _mint(to, tokenId);
            MintedArtwork memory mintedArtwork = MintedArtwork(idToArtworkData[id].minted, id);
            tokenIdToArtwork[tokenId] = mintedArtwork;
            idToArtworkData[id].editions ++;
            _tokenIdTracker.increment();
        }
    }

    function isWhitelisted(bytes memory signature, address sender) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(signature) == owner();
    }

    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function burnArtwork(uint tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "SpancsCollection: You don't own this token!");
        _burn(tokenId);
        burned[tokenIdToArtwork[tokenId].id].push(msg.sender);
    }

    function enableSale(uint id, bool state) external onlyOwner {
        idToArtworkData[id].publicSale = state;
    }

    function tokenURI(uint _tokenId) public view override returns (string memory) {
        string memory baseUriId = string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenIdToArtwork[_tokenId].id)));
        string memory baseUriIdSlash = string(abi.encodePacked(baseUriId,"/"));
        return string(abi.encodePacked(baseUriIdSlash, Strings.toString(tokenIdToArtwork[_tokenId].edition)));
    }

    function getPrice(uint id) public view returns(uint){
        return idToArtworkData[id].price;
    }

    function getArtwork(uint id) public view returns(Artwork memory) {
        return idToArtworkData[id];
    }

    function getAllArtworks() public view returns(Artwork[] memory) {
        Artwork[] memory artworks = new Artwork[](currentId);
        for(uint i = 0; i<artworks.length; i++){
            artworks[i] = (idToArtworkData[i]);
        }
        return artworks;
    }

    function withdrawAll() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "SpancsCollection: No balance to withdraw");
        _widthdraw(artistAddress, balance);
    }

    function _widthdraw(address _address, uint _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "SpancsCollection: Transfer failed.");
    }
}
