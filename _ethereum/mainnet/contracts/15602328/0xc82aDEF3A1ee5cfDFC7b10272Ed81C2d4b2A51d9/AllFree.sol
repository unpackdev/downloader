// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";



contract ChubbyPenguins is ERC721A,Ownable,ReentrancyGuard {
    using Strings for uint256;

    
    uint256 public maxSupply = 2555;
    uint256 public maxMint = 5;

    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri = "ipfs://QmdV8SebEnVhFzo52MPN5ySvMgwyh2bszSW1Ce9JCX3pmo/";

    bool public revealed = false;
    bool public paused = true;

    mapping(address => uint256) public _totalMinted;

    constructor() ERC721A("Chubby Penguins","CP") {}

    function mint(uint256 _mintAmount) public nonReentrant {
        require(!paused,"");
        require(_mintAmount <= maxMint,"");
        require(_mintAmount+_totalMinted[msg.sender] <= maxMint,"" );
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply ,"");
        _safeMint(msg.sender,_mintAmount);
        _totalMinted[msg.sender]+=_mintAmount;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),_baseTokenEXT)) : "";
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }


    function toogleReveal() public onlyOwner{
        revealed = !revealed;
    }

    function tooglePause() public onlyOwner{
        paused = !paused;
    }

    function changeURLParams(string memory _nURL,string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success,"Transfer failed.");
    }

}