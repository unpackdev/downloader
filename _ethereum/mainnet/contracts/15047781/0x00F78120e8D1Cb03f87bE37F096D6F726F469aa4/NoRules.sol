//                         ____________
//                       .~      ,   . ~.
//                      /                \
//                     /      /~\/~\   ,  \
//                    |   .   \    /   '   |
//                    |         \/         |
//           XX       |  /~~\        /~~\  |       XX
//         XX  X      | |  o  \    /  o  | |      X  XX
//       XX     X     |  \____/    \____/  |     X     XX
//  XXXXX     XX      \         /\        ,/      XX     XXXXX
// X        XX%;;@      \      /  \     ,/      @%%;XX        X
// X       X  @%%;;@     |           '  |     @%%;;@  X       X
// X      X     @%%;;@   |. ` ; ; ; ;  ,|   @%%;;@     X      X
//  X    X        @%%;;@                  @%%;;@        X    X
//   X   X          @%%;;@              @%%;;@          X   X
//    X  X            @%%;;@          @%%;;@            X  X
//     XX X             @%%;;@      @%%;;@             X XX
//       XXX              @%%;;@  @%%;;@              XXX
//                          @%%;;%%;;@
//                            @%%;;@
//                          @%%;;@..@@
//                           @@@  @@@
//                           NO RULES

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";

contract NoRules is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard {
  using Strings for uint256;
 
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public nonRevealedUri;
  
  uint256 public price = 0;
  uint256 public maxSupply = 6000;
  uint256 public maxPerTx = 3;
  uint256 public maxPerWallet = 3;

  bool public paused = true;
  bool public revealed = false;

  mapping(address => uint) public mintedByOwner;
  mapping(address => uint) public burntByOwner;

  constructor(
    string memory _nonRevealedUri
  ) ERC721A("NO RULES", "NR") {
    setNonRevealedUri(_nonRevealedUri);
  }

// --------- COMPLIANCE ---------
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxPerTx && _mintAmount + mintedByOwner[_msgSender()] <= maxPerWallet,  'invalid amount');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= price * _mintAmount, 'not enough funds');
    _;
  }

// --------- MINT ---------
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'mint is paused');

    mintedByOwner[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  // --------- BURN ---------
  function burnTokens(uint _qty) public {
    IERC721AQueryable token = IERC721AQueryable(address(this));
    uint[] memory ownedTokens = token.tokensOfOwner(_msgSender());
    require(_qty <= ownedTokens.length, 'You own fewer tokens than you are trying to burn');

    for (uint256 i = 0; i < _qty; i++) {
        burn(ownedTokens[i]);
        burntByOwner[_msgSender()]++;
    }
  }

 
// --------- INFO---------
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return nonRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : '';
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


// --------- OWNER ---------
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setprice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setMaxPerTx(uint256 _maxPerTx) public onlyOwner {
    maxPerTx = _maxPerTx;
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');

    _safeMint(_receiver, _mintAmount);
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setNonRevealedUri(string memory _nonRevealedUri) public onlyOwner {
    nonRevealedUri = _nonRevealedUri;
  }

  function setBurntByAddress(uint _burnAmount, address _address) public onlyOwner {
      burntByOwner[_address] = _burnAmount;
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

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success);
  }
}