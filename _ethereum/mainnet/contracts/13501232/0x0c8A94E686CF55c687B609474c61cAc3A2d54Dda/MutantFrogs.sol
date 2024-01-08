// SPDX-License-Identifier: MIT

//      ███╗░░░███╗██╗░░░██╗████████╗░█████╗░███╗░░██╗████████╗  ███████╗██████╗░░█████╗░░██████╗░░██████╗      ||
//      ████╗░████║██║░░░██║╚══██╔══╝██╔══██╗████╗░██║╚══██╔══╝  ██╔════╝██╔══██╗██╔══██╗██╔════╝░██╔════╝      ||
//      ██╔████╔██║██║░░░██║░░░██║░░░███████║██╔██╗██║░░░██║░░░  █████╗░░██████╔╝██║░░██║██║░░██╗░╚█████╗░      ||
//      ██║╚██╔╝██║██║░░░██║░░░██║░░░██╔══██║██║╚████║░░░██║░░░  ██╔══╝░░██╔══██╗██║░░██║██║░░╚██╗░╚═══██╗      ||
//      ██║░╚═╝░██║╚██████╔╝░░░██║░░░██║░░██║██║░╚███║░░░██║░░░  ██║░░░░░██║░░██║╚█████╔╝╚██████╔╝██████╔╝      ||
//      ╚═╝░░░░░╚═╝░╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝░░░╚═╝░░░  ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░╚═════╝░╚═════╝░      ||


pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

contract MutantFrogs is ERC721Enumerable, Ownable {
    using Strings for uint256;
    event MintFrog(address indexed sender, uint256 startWith, uint256 times);

    uint256 public totalFrogs;
    uint256 public totalCount = 9999;
    
    uint256 public maxBatch = 10;
    uint256 public price = 50000000000000000; //0.05 ether

    string public baseURI;
    string public unRevealedURI;

    bool private started = false;
    bool private revealed = false;

    constructor(string memory name_, string memory symbol_, string memory baseURI_, string memory unRevealedURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        unRevealedURI = unRevealedURI_;
    }

    //basic functions. 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setUnRevealedURI(string memory _newURI) external onlyOwner {
        unRevealedURI = _newURI;
    }

    //erc721 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
       
        if(!revealed){
          return unRevealedURI;
        }
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function start() external onlyOwner {
        started = true;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory){
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function mint(uint256 numberOfTokens) external payable {
        require(started, "not started");
        require(numberOfTokens >0 && numberOfTokens <= maxBatch, "must mint fewer in each batch");
        require(totalFrogs + numberOfTokens <= totalCount, "max supply reached!");
        require(msg.value >= numberOfTokens * price, "value error, please check price.");
        
        payable(owner()).transfer(msg.value);
        emit MintFrog(_msgSender(), totalFrogs+1, numberOfTokens);
        for(uint256 i=0; i< numberOfTokens; i++){
            _mint(_msgSender(), 1 + totalFrogs++);
        }
    }
    
    function reserve(uint256 n) external onlyOwner {
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, 1 + totalFrogs++);
        }
    }
}
