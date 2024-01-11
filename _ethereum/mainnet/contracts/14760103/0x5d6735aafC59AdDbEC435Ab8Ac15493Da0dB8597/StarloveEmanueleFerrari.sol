// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

//      ________  ___________   __        _______       ___        ______  ___      ___  _______  
//     /"       )("     _   ") /""\      /"      \     |"  |      /    " \|"  \    /"  |/"     "| 
//    (:   \___/  )__/  \\__/ /    \    |:        |    ||  |     // ____  \\   \  //  /(: ______) 
//     \___  \       \\_ /   /' /\  \   |_____/   )    |:  |    /  /    ) :)\\  \/. ./  \/    |   
//      __/  \\      |.  |  //  __'  \   //      /      \  |___(: (____/ //  \.    //   // ___)_  
//     /" \   :)     \:  | /   /  \\  \ |:  __   \     ( \_|:  \\        /    \\   /   (:      "| 
//    (_______/       \__|(___/    \___)|__|  \___)     \_______)\"_____/      \__/     \_______)
//    

contract StarloveEmanueleFerrari is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public alreadyMinted;
  mapping(address => bool) public premiumTier;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;

  bool public paused = true;
  bool public whitelistMintEnabled = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setUriPrefix(_metadataUri);

    premiumTier[0x85abbC31fDD045c38D08C500AA0a58d40AB26Cd2] = true;
    premiumTier[0x753f8DAB2Ce1E6Ec33e2967Bcdd4974F60025319] = true;
    premiumTier[0xD88cb953bbC8e4db0A0203ee54EB9b21cB3BbA06] = true;
    premiumTier[0xc1a880D8e488c16541E76EDA6e6aE9a1495F2DBF] = true;
    premiumTier[0x6012757F61D04B95c601D80e4eBA30ecb7f14B60] = true;
    premiumTier[0x7714FF6B6b2198D3fFc58D1277755D54a9208644] = true;
    premiumTier[0xeb43b5597E3bDe0b0C03eE6731bA7c0247E1581E] = true;
    premiumTier[0xB0bDD53b627d7e61cFC5C13EF110e47e210fAc6f] = true;
    premiumTier[0x7Fa0f7A3828580E1A22aaA89d11D1c48a8C575Ed] = true;
    premiumTier[0xbdca6f226D326B6Af8Fac56DB283bafC8572Bce7] = true;
    premiumTier[0xaf2Ed164a141edFB34667dAc4D25a2fd9C090663] = true;
    premiumTier[0x7B15c8a6c2368528eFCd3C41e5da679b74449472] = true;
    premiumTier[0xf7BA647C5E2566037d1aB9EC9e78a3acB1586f0F] = true;
    premiumTier[0xcAEDffC7e9Bf213292244caf28ceF7A1eAF6A11d] = true;
    premiumTier[0x857B73b6Af902e7221Fbc3DAaF395888fB1911c9] = true;
    premiumTier[0xE9279f0FF35c5FcC07ccBf98a472991EA125Fa32] = true;
    premiumTier[0xDF8465e364C5Ba32bDB44D83B302Bd163622A263] = true;
    premiumTier[0x0a274354BFe6D0eE3DF151A204BAfc3a19FC050c] = true;
    premiumTier[0x21f80Ee92Bd4780fAb8204DF8680061124c0Acdb] = true;
    premiumTier[0x5eE1d9F8eF343eD9bfcA83b7213C9b384FAfc4C7] = true;
    premiumTier[0x187D6e8741Af35C45198EbeC83905eB23e742B15] = true;
    premiumTier[0xcD8b72710595c69019c109Aef5b1B92eea7F995F] = true;
    premiumTier[0xe1C9b7038A03Dc898Cd161827709A3C241af991E] = true;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!alreadyMinted[_msgSender()], 'Address already minted!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    if (premiumTier[_msgSender()]) {
        require(_mintAmount > 0 && _mintAmount <= 2, 'Invalid mint amount!');
        premiumTier[_msgSender()] =  false;
        if(_mintAmount > 1) {
          alreadyMinted[_msgSender()] = true;
        }
    } else {
      require(_mintAmount > 0 && _mintAmount <= 1, 'Invalid mint amount!');
      alreadyMinted[_msgSender()] = true;
    }
    
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintPublic(uint256 _mintAmount) public payable mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(_mintAmount > 0 && _mintAmount <= 2, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(!alreadyMinted[_msgSender()], 'Address already minted!');
    alreadyMinted[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}

// developed by Kanye East