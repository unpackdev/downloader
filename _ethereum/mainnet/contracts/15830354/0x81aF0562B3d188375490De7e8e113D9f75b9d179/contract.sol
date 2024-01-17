// SPDX-License-Identifier: Unlicensed
// Developer - ReservedSnow(https://linktr.ee/reservedsnow)

/*
  _________                               .___    _________            ._____.                  
 /   _____/____    ___________   ____   __| _/   /   _____/ ___________|__\_ |__   ____   ______
 \_____  \\__  \ _/ ___\_  __ \_/ __ \ / __ |    \_____  \_/ ___\_  __ \  || __ \_/ __ \ /  ___/
 /        \/ __ \\  \___|  | \/\  ___// /_/ |    /        \  \___|  | \/  || \_\ \  ___/ \___ \ 
/_______  (____  /\___  >__|    \___  >____ |   /_______  /\___  >__|  |__||___  /\___  >____  >
        \/     \/     \/            \/     \/           \/     \/              \/     \/     \/ 

*/


import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";


pragma solidity >=0.8.16 <0.9.0;

contract SacredScribes is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

// ================== Variables Start =======================
  
  bytes32 public merkleRoot;
  string internal uri;
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  uint256 public price = 0.03 ether;
  uint256 public wlprice = 0.02 ether;
  uint256 public supplyLimit = 1666;
  uint256 public wlsupplyLimit = 1666;
  uint256 public maxMintAmountPerTx = 3;
  uint256 public wlmaxMintAmountPerTx = 3;
  uint256 public maxLimitPerWallet = 3;
  uint256 public wlmaxLimitPerWallet = 3;
  bool public whitelistSale = false;
  bool public publicSale = false;
  bool public revealed = true;
  mapping(address => uint256) public wlMintCount;
  mapping(address => uint256) public publicMintCount;
  uint256 public publicMinted;
  uint256 public wlMinted;    

// ================== Variables End =======================  

// ================== Constructor Start =======================

  constructor(
    string memory _uri
  ) ERC721A("Sacred Scribes", "SACRED")  {
    seturi(_uri);
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================

  function WlMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {

    // Verify wl requirements
    require(whitelistSale, 'The WlSale is paused!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');


    // Normal requirements 
    require(_mintAmount > 0 && _mintAmount <= wlmaxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= wlsupplyLimit, 'Max supply exceeded!');
    require(wlMintCount[msg.sender] + _mintAmount <= wlmaxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= wlprice * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);

    // Mapping update 
    wlMintCount[msg.sender] += _mintAmount; 
    wlMinted += _mintAmount;
  }

  function PublicMint(uint256 _mintAmount) public payable {
    
    // Normal requirements 
    require(publicSale, 'The PublicSale is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    require(publicMintCount[msg.sender] + _mintAmount <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
     
    // Mint
     _safeMint(_msgSender(), _mintAmount);

    // Mapping update 
    publicMintCount[msg.sender] += _mintAmount;  
    publicMinted += _mintAmount;   
  }  

  function OwnerMint(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

    function MassAirdrop(address[] calldata receivers) external onlyOwner {
    for (uint256 i; i < receivers.length; ++i) {
      require(totalSupply() + 1 <= supplyLimit, 'Max supply exceeded!');
      _mint(receivers[i], 1);
    }
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
  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }

  function setwlSale(bool _whitelistSale) public onlyOwner {
    whitelistSale = _whitelistSale;
  }

  function toggleBothSales() public onlyOwner {
      publicSale = !publicSale; 
      whitelistSale = !whitelistSale;
  }
// hash set
  function setwlMerkleRootHash(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setwlmaxMintAmountPerTx(uint256 _wlmaxMintAmountPerTx) public onlyOwner {
    wlmaxMintAmountPerTx = _wlmaxMintAmountPerTx;
  }

// pax per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function setwlmaxLimitPerWallet(uint256 _wlmaxLimitPerWallet) public onlyOwner {
    wlmaxLimitPerWallet = _wlmaxLimitPerWallet;
  }  

// price
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setwlPrice(uint256 _wlprice) public onlyOwner {
    wlprice = _wlprice;
  }  

// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }

  function setwlsupplyLimit(uint256 _wlsupplyLimit) public onlyOwner {
    wlsupplyLimit = _wlsupplyLimit;
  }  

// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
      uint _balance = address(this).balance;
        payable(0xf98eb3246d168B3B8084C5bbD7bf162753e7bB54).transfer(_balance * 85 / 100);
        payable(0x119a5a09526Ff53E26fF641D64D0d993CFf107c1).transfer(_balance * 15 / 100);
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

// ================== Read Functions End ======================= 

// Developer - ReservedSnow(https://linktr.ee/reservedsnow
}