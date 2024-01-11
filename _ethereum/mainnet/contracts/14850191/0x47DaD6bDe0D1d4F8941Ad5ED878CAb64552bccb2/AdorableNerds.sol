// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9<0.9.0;

import "./ERC721AReservable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract AdorableNerds is ERC721AReservable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //######################
    // Whitelist Variables
    //######################
    bytes32 public merkleRootWhitelist;
    mapping(address => uint256) public whitelistClaimed;
    bool public whitelistMintEnabled = false;


    //######################
    // General Variables
    //######################      
    string public uriPrefix = '';
    string public uriSuffix = '';
    string public hiddenMetadataUri;
    
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerAdr;
    
    bool public paused = true;
    bool public revealed = false;

    uint256 public totalReserved;

    constructor(
      string memory _tokenName,
      string memory _tokenSymbol,
      uint256 _reservedAmount,      
      uint256 _cost,
      uint256 _maxSupply,
      uint256 _maxMintAmountPerTx,
      uint256 _maxMintAmountPerAdr,
      string memory _hiddenMetadataUri
    ) ERC721AReservable(_tokenName, _tokenSymbol, _reservedAmount) {
      setCost(_cost);
      maxSupply = _maxSupply;
      totalReserved = _totalReserved;
      setMaxMintAmountPerTx(_maxMintAmountPerTx);
      setMaxMintAmountPerAdr(_maxMintAmountPerAdr);
      setHiddenMetadataUri(_hiddenMetadataUri);
    }

    // Modifiers
    modifier mintCompliance(uint256 _mintAmount) {
      require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
      require(totalSupply() + _mintAmount <= maxSupply - _totalReserved, 'Max supply exceeded!');
      _;
    }

    modifier mintMaxPerAddressCompliance(address _owner) {
      require(balanceOf(_owner) < maxMintAmountPerAdr, 'Max mint amount per wallet exceeded!');
      _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
      _;
    }

    modifier mintReservedCompliance(uint256 _mintAmount) {
      require(_mintAmount > 0, 'Invalid mint amount!');
      require((_currentReservedIndex + _mintAmount) < _totalReserved, 'Max reserved supply exceeded!');
      _;
    }

    //######################
    // Whitelist Functions
    //######################
    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) mintMaxPerAddressCompliance(_msgSender()) nonReentrant {
      // Verify whitelist requirements
      require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
      require(whitelistClaimed[_msgSender()] + _mintAmount < maxMintAmountPerAdr, 'Exceed max amount to whitelist mint');
      
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
      require(MerkleProof.verify(_merkleProof, merkleRootWhitelist, leaf), 'Invalid proof!');
      
      whitelistClaimed[_msgSender()] += _mintAmount;
      _safeMint(_msgSender(), _mintAmount);
    }

    //######################
    // Mint Functions
    //######################
    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) mintMaxPerAddressCompliance(_msgSender()) nonReentrant {
      require(!paused, 'The contract is paused!');
      _safeMint(_msgSender(), _mintAmount);
    }
    
    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
      _safeMint(_receiver, _mintAmount);
    }

    function mintReserved(uint256 _mintAmount) public  mintReservedCompliance(_mintAmount) onlyOwner {
      _safeMintReserved(_msgSender(), _mintAmount);
    }

    function mintReservedForAddress(uint256 _mintAmount, address _receiver) public mintReservedCompliance(_mintAmount) onlyOwner {
      _safeMintReserved(_receiver, _mintAmount);
    }

    //######################
    // Setters  
    //######################
    function setMerkleRootWhitelist(bytes32 _merkleRoot) public onlyOwner {
      merkleRootWhitelist = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
      whitelistMintEnabled = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
      revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
      cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
      maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerAdr(uint256 _maxMintAmountPerAdr) public onlyOwner {
      maxMintAmountPerAdr = _maxMintAmountPerAdr;
    }  

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
      hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
      uriSuffix = _uriSuffix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
      uriPrefix = _uriPrefix;
    }  

    function setPaused(bool _state) public onlyOwner {
      paused = _state;
    }

    function _startReservedTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    //######################
    // Getters  
    //######################  
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
      uint256 ownerTokenCount = ERC721AReservable.balanceOf(_owner);
      uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
      uint256 currentTokenId = _startReservedTokenId();
      uint256 ownedTokenIndex = 0;
    
      address latestOwnerAddress;

      while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
        TokenOwnership memory ownership = _ownerships[currentTokenId];

        if (!ownership.burned) {
          if (ownership.addr != address(0)) {
            latestOwnerAddress = ownership.addr;
          }

          if (latestOwnerAddress == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;

            ownedTokenIndex++;
          }
        }
        currentTokenId++;
      }
      return ownedTokenIds;
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
      return uriPrefix;
    }

    //#######################
    // Withdraw
    // Never forget this one!  
    //#######################  
    function withdraw() public onlyOwner nonReentrant {
      (bool os, ) = payable(owner()).call{value: address(this).balance}('');
      require(os);
    }
  }
