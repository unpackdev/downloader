// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow

/*
___.           __________                                            .____________                     
\_ |__ ___.__. \______   \ ____   ______ ______________  __ ____   __| _/   _____/ ____   ______  _  __
 | __ <   |  |  |       _// __ \ /  ___// __ \_  __ \  \/ // __ \ / __ |\_____  \ /    \ /  _ \ \/ \/ /
 | \_\ \___  |  |    |   \  ___/ \___ \\  ___/|  | \/\   /\  ___// /_/ |/        \   |  (  <_> )     / 
 |___  / ____|  |____|_  /\___  >____  >\___  >__|    \_/  \___  >____ /_______  /___|  /\____/ \/\_/  
     \/\/              \/     \/     \/     \/                 \/     \/       \/     \/               
*/

/**
    !Disclaimer!
    please review this code on your own before using any of
    the following code for production.
    ReservedSnow will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
    If you find any problems please let the dev know in order to improve
    the contract and fix vulnerabilities if there is one.
    YOU ARE NOT ALLOWED TO SELL IT
*/

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";


pragma solidity >=0.8.9 <0.9.0;

contract ReservedSnowErc721a is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================
  
  bytes32 public merkleRoot;
  string public uri;
  string public uriSuffix = ".json";
  uint256 public price = 0.03 ether;
  uint256 public wlprice = 0.02 ether;
  uint256 public supplyLimit = 5555;
  uint256 public maxLimitPerWallet = 2;
  uint256 public wlmaxLimitPerWallet = 2;
  uint256 public freemaxLimitPerWallet = 2;
  uint256 public freewlmaxLimitPerWallet = 2; 
  bool public whitelistSale = false;
  bool public publicSale = false;
  mapping(address => uint256) public freewlMintCount;
  mapping(address => uint256) public paidwlMintCount;
  mapping(address => uint256) public freepublicMintCount;
  mapping(address => uint256) public paidpublicMintCount;  

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("The Kuwaitis", "KW")  {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================


  function WlMint(uint256 _mintAmount , bytes32[] calldata _merkleProof) public payable {
    // Verify wl requirements
    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    // free mint verify
    uint256 freelimit = freewlmaxLimitPerWallet - freewlMintCount[msg.sender];
    uint256 paidlimit = wlmaxLimitPerWallet - paidwlMintCount[msg.sender];
    if(freewlMintCount[msg.sender] < freewlmaxLimitPerWallet) {
      require(msg.value >= 0 * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= freelimit, 'Max free mint per wallet exceeded!');
      freewlMintCount[msg.sender] += _mintAmount;
    }
    else{
      require(msg.value >= wlprice * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= paidlimit, 'Max mint per wallet exceeded!');
      paidwlMintCount[msg.sender] += _mintAmount;
    }

    // Normal requirements 
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');

    // free mint verify
    uint256 freelimit = freemaxLimitPerWallet - freepublicMintCount[msg.sender];
    uint256 paidlimit = maxLimitPerWallet - paidpublicMintCount[msg.sender];
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

  function setwlSale(bool _whitelistSale) public onlyOwner {
    whitelistSale = _whitelistSale;
  }


// hash set
  function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }


// pax per wallet
  function setmaxLimitPerWallet(uint256 _pub , uint256 _pubfree, uint256 _wlfree , uint256 _wl) public onlyOwner {
  maxLimitPerWallet = _pub;
  wlmaxLimitPerWallet = _wl;
  freemaxLimitPerWallet = _pubfree;
  freewlmaxLimitPerWallet = _wlfree;
  }

// price
  function setPrice(uint256 _price, uint256 _wlprice) public onlyOwner {
    price = _price;
    wlprice = _wlprice;    
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

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================
  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
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

// This Contract Has been developed / made by ReservedSnow (https://linktr.ee/reservedsnow)  

// ================== Read Functions End =======================  

}