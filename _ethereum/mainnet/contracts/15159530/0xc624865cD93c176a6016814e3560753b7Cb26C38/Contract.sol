// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow

/*
______    _                _ _        ______                     _           
|  ___|  (_)              | | |       |  ___|                   (_)          
| |_ _ __ _  ___ _ __   __| | |_   _  | |_ _ __ ___   __ _  __ _ _  ___  ___ 
|  _| '__| |/ _ \ '_ \ / _` | | | | | |  _| '__/ _ \ / _` |/ _` | |/ _ \/ __|
| | | |  | |  __/ | | | (_| | | |_| | | | | | | (_) | (_| | (_| | |  __/\__ \
\_| |_|  |_|\___|_| |_|\__,_|_|\__, | \_| |_|  \___/ \__, |\__, |_|\___||___/
                                __/ |                 __/ | __/ |            
                               |___/                 |___/ |___/             
*/

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";


pragma solidity >=0.8.9 <0.9.0;

contract FriendlyFroggies is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================

  string public uri;
  string public uriSuffix = ".json";
  uint256 public price = 0.001 ether;
  uint256 public supplyLimit = 3333;
  uint256 public paidmaxLimitPerWallet = 2;
  uint256 public freemaxLimitPerWallet = 1;
  bool public publicSale = false;
  mapping(address => uint256) public freepublicMintCount;
  mapping(address => uint256) public paidpublicMintCount;  

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("Friendly Froggies", "FREN FROGIES")  {
    seturi(_uri);
     _safeMint(msg.sender, 20);
    _safeMint(0xd4578a6692ED53A6A507254f83984B2Ca393b513, 10);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');

    // free mint verify
    uint256 freelimit = freemaxLimitPerWallet - freepublicMintCount[msg.sender];
    uint256 paidlimit = paidmaxLimitPerWallet - paidpublicMintCount[msg.sender];
    if(freepublicMintCount[msg.sender] < freemaxLimitPerWallet) {
      require(msg.value >= 0 * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= freelimit, 'Max free mint per wallet exceeded!');
      freepublicMintCount[msg.sender] += _mintAmount;
    }
    else{
      require(msg.value >= price * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= paidlimit, 'Max mint per wallet exceeded!');
      paidpublicMintCount[msg.sender] += _mintAmount;
    } 

     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }  

  function Airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

// ================== Mint Functions End =======================  

// ================== Set Functions Start =======================

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

// sales toggle
  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

// pax per wallet
  function setmaxLimitPerWallet(uint256 _pub , uint256 _pubfree) public onlyOwner {
  paidmaxLimitPerWallet = _pub;
  freemaxLimitPerWallet = _pubfree;
  }

// price
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
   
  }

// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function donate() external payable {
    // thank you
    }

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================
  function froggiesYouOwn(address owner) external view returns (uint256[] memory) {
    unchecked {
        uint256[] memory a = new uint256[](balanceOf(owner)); 
        uint256 end = _nextTokenId();
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        for (uint256 i; i < end; i++) {
            TokenOwnership memory ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                a[tokenIdsIdx++] = i;
            }
        }
        return a;    
    }
}

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  function petFroggie(uint256 _tokenId) external view returns (string memory) {
    require(_exists(_tokenId), 'The Froggie you tried to pet has not been born yet');
    return string(abi.encodePacked("You petted Froggie - ", _tokenId.toString(), ". It likes it and brings you a spider as a gift :)"));
  }

// This Contract Has been developed / made by ReservedSnow (https://linktr.ee/reservedsnow)  

// ================== Read Functions End =======================  

}
