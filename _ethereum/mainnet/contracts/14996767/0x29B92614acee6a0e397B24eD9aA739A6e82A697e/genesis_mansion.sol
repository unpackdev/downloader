// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "ERC721AQueryable.sol";
import "IERC721A.sol";
import "Ownable.sol";
import "MerkleProof.sol";
import "ReentrancyGuard.sol";
import "Strings.sol";

contract GenesisBoulevard is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = 'ipfs://QmTDurPuxtaZrepPTdJ3Puam4noEu8iGL1Wa3UaiiVsdyR/';
  string public uriSuffix = '.json';
  
  uint256 public cost = 1700000000000000;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 1;

  bool public paused = true;
  bool public whitelistMintEnabled = true;

  address payments;

  constructor(address _payments) ERC721A("Genesis Boulevard", "GB") {
    payments = _payments;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if (totalSupply() < 777) {
      require(msg.value >= 0 * _mintAmount, 'The first 777 are free!');
    } else {
      require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    }
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
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

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function closeSale() public onlyOwner {
    maxSupply = totalSupply();
  }

  function withdraw() public onlyOwner nonReentrant {
    // This is the Project wallet address which gets 50%
    // =============================================================================
    (bool hs, ) = payable(0xfe91b38B26a7e2Da147418E2F4C95EeF8eDaE51B).call{value: address(this).balance * 50 / 100}('');
    require(hs);
    // =============================================================================

    // This is the payment splitter contract address which get the remaining 50%
    // =============================================================================
    (bool os, ) = payable(payments).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function burn(uint256 tokenId) public virtual {
    _burn(tokenId, true);
  }       

}