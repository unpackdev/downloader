// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
████████╗██████╗ ██╗██████╗ ██████╗ ██╗   ██╗████████╗ ██████╗  ██████╗ ███╗   ██╗███████╗
╚══██╔══╝██╔══██╗██║██╔══██╗██╔══██╗╚██╗ ██╔╝╚══██╔══╝██╔═══██╗██╔═══██╗████╗  ██║██╔════╝
   ██║   ██████╔╝██║██████╔╝██████╔╝ ╚████╔╝    ██║   ██║   ██║██║   ██║██╔██╗ ██║███████╗
   ██║   ██╔══██╗██║██╔═══╝ ██╔═══╝   ╚██╔╝     ██║   ██║   ██║██║   ██║██║╚██╗██║╚════██║
   ██║   ██║  ██║██║██║     ██║        ██║      ██║   ╚██████╔╝╚██████╔╝██║ ╚████║███████║
   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝        ╚═╝      ╚═╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝
   Trippy Toons / 2021 / V.1.0.                                                                                       
*/

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TrippyToons is ERC721Enumerable, Ownable {
  using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public toonGifts = 44;
    uint256 public toonPublic = 4400;
    uint256 public toonMax = toonGifts + toonPublic;
    uint256 public toonPrice = 0.06 ether;
    uint256 public toonPerMint = 20;
    bool public saleLive = false;

    uint256 public giftedAmount;
    uint256 public publicAmountMinted;

    address private _carltonAddress = 0x17e1A2e095A25131B544dB3A3a2c1bA6911aAc73;

    constructor(
    string memory _initBaseURI
  ) ERC721("Trippy Toons", "Toons") {
    setBaseURI(_initBaseURI);
  }


    function mint(uint256 _mintAmount) public payable {
        require(saleLive,"MINTING_CLOSED");
        require(totalSupply() <= toonMax, "OUT_OF_STOCK");
        require(publicAmountMinted + _mintAmount <= toonPublic, "EXCEED_PUBLIC");
        require(_mintAmount <= toonPerMint, "EXCEEDED_TOONS_PER_MINT");
        require(_mintAmount > 0, "ONE_TOON_MINIMUM");
        require(toonPrice * _mintAmount <= msg.value, "INSUFFICIENT_ETH");

        for(uint256 i = 0; i < _mintAmount; i++) {
            publicAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function getSaleLive () public view returns (bool) {
         return saleLive;
    }
    
    function getGiftsTotal () public view returns (uint256) {
         return toonGifts;
    }
    
    function getPublicTotal () public view returns (uint256) {
         return toonPublic;
    }
    
    function getGiftedAmount () public view returns (uint256) {
         return giftedAmount;
    }
    
    function getMintedAmount () public view returns (uint256) {
         return publicAmountMinted;
    }
    
    function getToonMax () public view returns (uint256) {
         return toonMax;
    }
    
    function getToonPrice () public view returns (uint256) {
         return toonPrice;
    }
    
   //internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Can't query non-existent token");
        string memory currentBaseURI = _baseURI();
    	return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    // Only owner commands
    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= toonMax, "OUT_OF_STOCK");
        require(giftedAmount + receivers.length <= toonGifts, "NO_GIFTS_AVAILABLE");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        payable(_carltonAddress).transfer(address(this).balance / 2);
        payable(msg.sender).transfer(address(this).balance);
    }

    function ToggleSale() public onlyOwner {
    saleLive = !saleLive;
    }


    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    
    function lowerTotalSupply(uint256 _newTotalSupply) public onlyOwner {
		require(_newTotalSupply < toonMax, "you can only lower it");
		toonMax = _newTotalSupply;
    }
    
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        toonPerMint = _newmaxMintAmount;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        toonPrice = _newCost;
    }
    
    function setCarltonAddress(address addr) external onlyOwner {
        _carltonAddress = addr;
    }


}