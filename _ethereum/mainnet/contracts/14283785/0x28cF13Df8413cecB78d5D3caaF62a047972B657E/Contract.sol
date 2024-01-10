// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract BEERSAROUNDTHEWORLD is ERC721A, Ownable,ReentrancyGuard {
    using Strings for uint256;


    uint256 public maxSupply = 30;
    string public _baseTokenURI;
    string public _baseTokenEXT;
    bool public _paused = false;



    constructor(string memory _initBaseURI,string memory _initBaseExt) ERC721A("BEERSAROUNDTHEWORLD", "BEERS") {
       changeURLParams(_initBaseURI,_initBaseExt);
      
    }

    function mint(uint256 _mintAmount) public payable onlyOwner() {
        require(!_paused, ": Contract Execution paused.");
        require(_mintAmount > 0, ": Amount should be greater than 0.");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply , ": No more NFTs to mint, decrease the quantity or check out OpenSea.");
        _safeMint(msg.sender, _mintAmount);
    }
    


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tooglePause() public onlyOwner() {
        _paused = !_paused;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),_baseTokenEXT)) : "";
        
    }

    
    function changeURLParams(string memory _nURL, string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }


    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    

    
}