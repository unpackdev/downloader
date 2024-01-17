// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow (https://linktr.ee/reservedsnow)

/*
First mint per wallet is free rest are 0.0034 ether each till 3333 minted
then all mints cost 0.0034 ether each
*/

/*

__________           ._____________      __   .__     _____                __                       
\______   \ ____   __| _/\____    /__ __|  | _|__|   /  _  \___  _______ _/  |______ _______  ______
 |       _// __ \ / __ |   /     /|  |  \  |/ /  |  /  /_\  \  \/ /\__  \\   __\__  \\_  __ \/  ___/
 |    |   \  ___// /_/ |  /     /_|  |  /    <|  | /    |    \   /  / __ \|  |  / __ \|  | \/\___ \ 
 |____|_  /\___  >____ | /_______ \____/|__|_ \__| \____|__  /\_/  (____  /__| (____  /__|  /____  >
        \/     \/     \/         \/          \/            \/           \/          \/           \/ 
        
*/


import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";


pragma solidity >=0.8.13 <0.9.0;

contract RedZukiAvatars is ERC721A, Ownable, ReentrancyGuard, ERC2981 {

  using Strings for uint256;

// ================== Variables Start =======================

  string internal uri;
  string public uriSuffix = ".json";
  string internal hiddenMetadataUri = "ipfs://bafybeifctqs4xmweyv3cbnyukhjpydbigzdmgil7iwdzpvhiu2s6z3atvi/unreveal.json";
  uint256 public price = 0.0034 ether;
  uint256 public supplyLimit = 10000;
  uint256 public freeSupplyTill = 3333;
  uint256 public maxLimitPertx = 10;
  uint256 public freemaxLimitPerWallet = 1;
  bool public publicSale = false;
  bool public revealed = false;
  mapping(address => uint256) public freepublicMintCount;
  mapping(address => uint256) public publicMintCount;
  string public contractURI = "";
  uint96 royaltyFraction = 500;

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("RedZuki Avatars", "RZA"){
    seturi(_uri);
    setRoyaltyInfo(address(this), royaltyFraction);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    
    if(totalSupply() <= freeSupplyTill) {
    // free mint verify
    uint256 freelimit = freemaxLimitPerWallet - freepublicMintCount[msg.sender];
    if(freelimit > 0) {
      if(_mintAmount> freelimit){
       require(msg.value >= price * (_mintAmount - freelimit), 'Insufficient funds!');
      }         
      require(msg.value >= 0 * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= maxLimitPertx, 'Max limit per tx exceeded!');
      freepublicMintCount[msg.sender] += _mintAmount - (_mintAmount - freelimit);
      publicMintCount[msg.sender] += _mintAmount;
    }
    else{
      require(msg.value >= price * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= maxLimitPertx, 'Max limit per tx exceeded!');
      publicMintCount[msg.sender] += _mintAmount;
    } 
    }
    else{
      require(msg.value >= price * _mintAmount, 'Insufficient funds!');
      require(_mintAmount <= maxLimitPertx, 'Max limit per tx exceeded!');
      publicMintCount[msg.sender] += _mintAmount;
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

// reveal
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

// sales toggle
  function setpublicSale() public onlyOwner {
    publicSale = !publicSale;
  }

// pax per wallet
  function setmaxLimitPerWalletandTxLimit(uint256 _pubtx , uint256 _pubfree) public onlyOwner {
  maxLimitPertx = _pubtx;
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

// royalties set  

  function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
  }  

  function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
  }

  function setRoyaltyTokens(uint _tokenId, address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setTokenRoyalty(_tokenId ,_receiver, _royaltyFeesInBips);
    } 


// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
        uint _balance = address(this).balance;
        payable(0x989C606e8b39E2ecEBdd275204dddbB4081c7aaF).transfer(_balance * 80 / 100); 
        payable(0xd4578a6692ED53A6A507254f83984B2Ca393b513).transfer(_balance * 20 / 100);
         (bool os, ) = payable(owner()).call{value: address(this).balance}("");
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
    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  event ethReceived(address, uint);
    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }


  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }   

  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override(ERC721A) {
        ERC721A._beforeTokenTransfers(from, to, tokenId,quantity);
        payable(owner()).transfer( msg.value * royaltyFraction / 10000); // mint included
  }  

// This Contract Has been developed / made by ReservedSnow (https://linktr.ee/reservedsnow)  

// ================== Read Functions End =======================  

}