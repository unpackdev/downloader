// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

//  ██╗░░██╗░█████╗░██████╗░░█████╗░██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗███████╗
//  ██║░██╔╝██╔══██╗██╔══██╗██╔══██╗██╔══██╗██║░░░██║████╗░██║██║░██╔╝╚════██║
//  █████═╝░██║░░██║██║░░██║███████║██████╔╝██║░░░██║██╔██╗██║█████═╝░░░███╔═╝
//  ██╔═██╗░██║░░██║██║░░██║██╔══██║██╔═══╝░██║░░░██║██║╚████║██╔═██╗░██╔══╝░░
//  ██║░╚██╗╚█████╔╝██████╔╝██║░░██║██║░░░░░╚██████╔╝██║░╚███║██║░╚██╗███████╗
//  ╚═╝░░╚═╝░╚════╝░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚══════╝

contract KodaPunkz is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public _baseTokenURI;

  uint256 public cost = 0.019 ether;
  uint256 public apeCost = 4.49 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxMintAmountPerTx = 5;

  bool public paused;
  bool public revealed;

  ERC20 apeToken = ERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381); 

  constructor(string memory baseURI) ERC721A("KodaPunkz", "KODAPUNKZ") {
    _baseTokenURI = baseURI;
    _safeMint(msg.sender, 1);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(!paused, "The contract is paused!");
    _;
  }

  /// @notice Mint with APE Coin. Sender needs to have had approved the tokens from the ape contract in the first place.
  function mintWithApeCoin(uint256 _mintAmount) external nonReentrant mintCompliance(_mintAmount) {
      apeToken.transferFrom(msg.sender, address(this), _mintAmount * apeCost);

      _safeMint(msg.sender, _mintAmount);
  }

  /// @notice Mint with eth.
  function mint(uint256 _mintAmount) external payable nonReentrant mintCompliance(_mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _safeMint(msg.sender, _mintAmount);
  }

  /// @notice Airdrop for a single address.
  function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

    /// @notice Airdrops to multiple wallets.
  function batchMintForAddress(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
      uint32 i;
      unchecked {
        for (i=0; i < addresses.length; ++i) {
          _safeMint(addresses[i], quantities[i]);
        }
      }
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /// @notice Reveals the metadata. Cannot be undone!
  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  /// @notice Withdraw APE Coins from contract.
  function withdrawApeTokens() external onlyOwner {
    apeToken.transfer(msg.sender, apeToken.balanceOf(address(this)));
  }

  /// @notice Withdraw eth from contract.
  function withdraw() external onlyOwner nonReentrant {
    payable(owner()).transfer(address(this).balance);
  }

  // METADATA HANDLING //

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "URI does not exist!");

      if (revealed) {
          return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
      } else {
          return _baseURI();
      }
  }
}