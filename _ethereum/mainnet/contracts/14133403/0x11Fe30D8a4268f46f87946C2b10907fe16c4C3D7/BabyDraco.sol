// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./ERC721A.sol";

contract BabyDraco is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    
    string public baseURI;
    address public essence;
    address public dracoverse;

    uint256 public maxDraco = 6666;
    uint256 public price = 450 ether;

    uint256 public constant MAX_MINT = 5;
    uint256 public constant MIN_HOLD = 2;
    string public constant BASE_EXTENSION = ".json";
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor() ERC721A("Dracoverse", "BDRACO", MAX_MINT) { 
    }

    function mint(uint256 _numberOfMints) public {
        uint256 total = price * _numberOfMints;
        require(tx.origin == msg.sender, "?");
        require(IERC721(dracoverse).balanceOf(msg.sender) >= MIN_HOLD,          "Need to hold min draco");
        require(_numberOfMints > 0 && _numberOfMints <= MAX_MINT,               "Invalid purchase amount");
        require(totalSupply() + _numberOfMints <= maxDraco,                     "Purchase would exceed max supply of tokens");
        require(total <= IERC20(essence).balanceOf(msg.sender),                 "Not enough balance");
        IERC20(essence).transferFrom(msg.sender, BURN_ADDRESS, total);
        _safeMint(msg.sender, _numberOfMints, "");
    }

    function setEssence(address _essence) public onlyOwner {
        essence = _essence;
    }

    function setDracoAddress(address _dracoverse) public onlyOwner {
        dracoverse = _dracoverse;
    }
    
    function setMaxDraco(uint256 _count) public onlyOwner {
        maxDraco = _count;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
         require(
            _exists(_id),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }
}