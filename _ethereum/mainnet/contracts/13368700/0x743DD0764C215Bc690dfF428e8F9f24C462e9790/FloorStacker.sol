// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./ERC721Burnable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";

/*
STACK                               
    */


contract FloorStacker is ERC721URIStorage, Ownable, IERC721Receiver {
    using Strings for uint256;
    event MintStack (address indexed sender, uint256 startWith);

    //uints 
    
    uint256 public totalCount = 3000;
    uint256 public maxBatch = 10;
    uint256 public totalFloors;
    address public floorsAddress;
    string public baseURI;

    //bool
    bool private started;

    //constructor args 
    constructor(string memory name_, string memory symbol_, address _floorsAddress, string memory baseURI_) ERC721(name_, symbol_) {
        floorsAddress = _floorsAddress;
        baseURI = baseURI_;
    }
    function totalSupply() public view virtual returns (uint256) {
        return totalFloors;
    }
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }
    function changeBatchSize(uint256 _newBatch) public onlyOwner {
        maxBatch = _newBatch;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '.json';
    }
    function setTokenURI(uint256 _tokenIds, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenIds, _tokenURI);
    }
    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function stack(uint256[] calldata _tokenIds) public {
        require(started, "not started");
        require(IERC721(floorsAddress).isApprovedForAll(_msgSender(), address(this)), "unstackedToadz not approved for spending");
        require(_tokenIds.length == 3, "you need 3 floors to stack");
        require(totalFloors + 1 <= totalCount, "not enough land!");
        for (uint256 i; i < _tokenIds.length; i++) {
          IERC721(floorsAddress).safeTransferFrom(_msgSender(), address(this), _tokenIds[i]);
        }
        emit MintStack(_msgSender(), totalFloors+1); //emit a MintStackEvent
        _mint(_msgSender(), 1 + totalFloors++);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}