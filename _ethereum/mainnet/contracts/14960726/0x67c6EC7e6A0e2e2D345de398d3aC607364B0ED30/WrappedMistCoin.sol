// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "DropBox.sol";


interface DropBoxInt {
    function deposit(uint256 value) external;
}

contract WrappedMistCoin is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event DropBoxCreated(address indexed owner);
    event Wrapped(uint256 indexed value, address indexed owner);
    event Unwrapped(uint256 indexed tokenId, address indexed owner);

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // special drop box address for each MistCoin holder who wants to wrap
    mapping(address => address) public dropBoxes;

    // each token corresponds to a bill with a certain denomination
    mapping(uint256 => uint256) public denoms;

    MistCoinInt mistContract = MistCoinInt(0xf4eCEd2f682CE333f96f2D8966C613DeD8fC95DD);
    
    constructor() ERC721("WrappedMistCoin", "WMC") {}

    function createDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists.");

        DropBox dropContract = new DropBox(address(this));
        dropBoxes[msg.sender] = address(dropContract);
        
        emit DropBoxCreated(msg.sender);
    }

    function wrap(uint256 value) public {
        require(dropBoxes[msg.sender] != address(0), "You must create a drop box first."); 
        
        address dropBox = dropBoxes[msg.sender];

        require(value == 1 || value == 10 || value == 100 || value == 1000 || 
                value == 10000 || value == 100000 || value == 1000000 || value == 10000000, "Invalid denomination.");
        require(mistContract.balanceOf(dropBox) >= value, "Not enough MistCoin in drop box.");

        DropBoxInt(dropBox).deposit(value);
        denoms[_tokenIdCounter.current()] = value;
        _mintToken(msg.sender, value);
        
        emit Wrapped(value, msg.sender);
    }

    function unwrap(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist.");
        require(msg.sender == ownerOf(tokenId), "You are not the owner.");

        mistContract.transfer(msg.sender, denoms[tokenId]);
        _burn(tokenId);

        emit Unwrapped(tokenId, msg.sender);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://mc.ethyearone.com/";
    }

    function _mintToken(address to, uint256 value) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, value.toString());
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}