// SPDX-License-Identifier: MIT

/**

Ryukai - Tempest Island

Twitter: https://twitter.com/RyukaiTempest
Discord: discord.gg/RyukaiTempest
Website: RyukaiTempest.com

Contract forked from KaijuKingz
 */

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IRYUold {
    function ownerOf(uint256 tokenID) external view returns(address);
} 

contract RyukaiTempestERC721 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    string private baseURI;
    string public baseExtension = ".json";

    uint256 public maxSupply;
    uint256 public maxGenCount;
    uint256 public price = 0.05 ether;

    bool public presaleActive = false;
    bool public saleActive = false;
    bool public revealed = false;
    string public notRevealedUri;

    mapping (address => uint256) public presaleWhitelist;
    mapping (address => uint256) public balanceGenesis;

    constructor(string memory name, string memory symbol, uint256 supply, uint256 genCount, string memory _initNotRevealedUri) ERC721(name, symbol) {
        maxSupply = supply;
        maxGenCount = genCount;
        setNotRevealedURI(_initNotRevealedUri);
    }
    
    IRYUold public RYUold;

    function airdrop(uint256[] calldata ryukaitoken) external onlyOwner {
        for (uint256 i; i < ryukaitoken.length ; i++) {
            address ownerOfRyukai;
            uint256 ryuakiToken = ryukaitoken[i];
            ownerOfRyukai = RYUold.ownerOf(ryuakiToken);
            _safeMint(ownerOfRyukai, ryukaitoken[i]);
            balanceGenesis[ownerOfRyukai]++;
        }
    }

   function mint(uint256 numberOfMints) public payable {
    uint256 supply = totalSupply();
    require(saleActive,                                 "Sale must be active to mint");
    require(numberOfMints > 0 && numberOfMints < 6,     "Invalid purchase amount");
    require(supply.add(numberOfMints) <= maxGenCount,   "Purchase would exceed max supply of Genesis Ryukai");
    require(price.mul(numberOfMints) == msg.value,      "Ether value sent is not correct");
        
    for(uint256 i; i < numberOfMints; i++) {
        _safeMint(msg.sender, supply + i);
        balanceGenesis[msg.sender]++;
        }
    }

    function walletOfOwner(address owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setRYUOld(address IRYUoldAddress) external onlyOwner {
        RYUold = IRYUold(IRYUoldAddress);
    }

      function ShowCollection() public onlyOwner {
      revealed = true;
  }
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

      function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
}