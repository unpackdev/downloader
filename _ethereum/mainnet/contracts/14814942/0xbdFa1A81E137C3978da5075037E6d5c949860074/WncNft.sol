// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract WncNft is ERC721Enumerable,ERC721Burnable,ERC721Pausable,ReentrancyGuard,Ownable{

    using Strings for uint256;
    using Counters for Counters.Counter;

    event SetTokenBaseURI(address indexed operator,string oldTokenBaseURI,string newTokenBaseURI);
    event SetMintFee(address indexed operator,uint256 oldMintFee,uint256 newMintFee);
    event Pause(address indexed operator,bool pause);

    Counters.Counter private _tokenIdTracker;

    uint256 public _mintFee;
    string public _tokenBaseURI;
    uint256 public _blindBoxOpenTime;

    uint256 public constant MAX_NFT_COUNT = 99;

    constructor(
        string memory baseURI,
        uint256 mintFee,
        uint256 blindBoxOpenTime
    ) ERC721("WeNewClub", "WNC") {
        require(bytes(baseURI).length > 0,"baseURI can't be empty");
        _tokenBaseURI = baseURI;
        _mintFee = mintFee;
        _blindBoxOpenTime = blindBoxOpenTime;
    }

    function tokenBaseURI() public view returns (string memory) {
        return _tokenBaseURI;
    }

    function mintNft() public payable nonReentrant whenNotPaused{
        require(totalSupply() < MAX_NFT_COUNT);
        require(msg.value >= _mintFee, "The ether value sent is not correct");
        payable(owner()).transfer(msg.value);

        _tokenIdTracker.increment();
        _safeMint(_msgSender(), _tokenIdTracker.current());
    }

    function setTokenBaseURI(string memory newTokenBaseURI) public onlyOwner{
        string memory oldTokenBaseURI = _tokenBaseURI;
        _tokenBaseURI = newTokenBaseURI;

        emit SetTokenBaseURI(_msgSender(),oldTokenBaseURI,newTokenBaseURI);
    }

    function setMintFee(uint256 newMintFee) public onlyOwner{
        uint256 oldMintFee = _mintFee;
        _mintFee = newMintFee;

        emit SetMintFee(_msgSender(),oldMintFee,newMintFee);
    }

    function pause() public onlyOwner{
        _pause();
        emit Pause(_msgSender(),paused());
    }

    function unpause() public onlyOwner{
        _unpause();
        emit Pause(_msgSender(),paused());
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return block.timestamp >= _blindBoxOpenTime ?
            string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : string(abi.encodePacked(_tokenBaseURI, "0"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }
}
