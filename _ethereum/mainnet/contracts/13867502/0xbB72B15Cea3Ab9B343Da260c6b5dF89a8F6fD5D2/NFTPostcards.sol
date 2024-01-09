// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";

contract NFTPostcards is ERC1155, Ownable {
  uint256 public lastTokenId;

  string public name;
  string public symbol;

  struct TokenInfo {
    string URI;
    uint256 mintPrice;
    uint256 mintStartTime;
    uint256 mintEndTime;
    uint256 maxSupply;
    uint256 reservedMaxSupply;
    uint256 totalSupply;
    uint256 reservedRemaining;
  }

  // tokenId => tokenInfo
  mapping(uint256 => TokenInfo) public tokenInfo;

  error IdDoesNotExist();
  error MaxSupplyExceeded();
  error MintingNotStarted();
  error MintingEnded();
  error EnoughETHNotSent();

  constructor(string memory _name, string memory _symbol) ERC1155("") {
    name = _name;
    symbol = _symbol;
  }

  function mint(uint256 id, uint256 qty) external payable {
    // cache to memory
    TokenInfo memory token = tokenInfo[id];

    // check if NFT exists
    if (id > lastTokenId) {
      revert IdDoesNotExist();
    }

    uint256 newTotalSupply = token.totalSupply + qty;

    // mint reserved
    if (msg.sender == owner()) {
      // check if within Max Reserved Supply
      if (qty > token.reservedRemaining) {
        revert MaxSupplyExceeded();
      }

      // update vars in storage
      tokenInfo[id].reservedRemaining = token.reservedRemaining - qty;
    } else {
      // check if within Minting timeframe
      if (block.timestamp < token.mintStartTime) {
        revert MintingNotStarted();
      } else if (block.timestamp > token.mintEndTime) {
        revert MintingEnded();
      }

      // check if within Max Supply
      if (newTotalSupply > token.maxSupply - token.reservedMaxSupply) {
        revert MaxSupplyExceeded();
      }

      // check if enough ETH sent
      uint256 expectedETH = token.mintPrice * qty;
      if (msg.value < expectedETH) {
        revert EnoughETHNotSent();
      }
    }

    // update vars in storage
    tokenInfo[id].totalSupply = newTotalSupply;

    _mint(msg.sender, id, qty, "");
  }

  function uri(uint256 id) public view override returns (string memory) {
    return tokenInfo[id].URI;
  }

  function addToken(TokenInfo memory _tokenInfo) external onlyOwner {
    lastTokenId++;

    _tokenInfo.totalSupply = 0;
    _tokenInfo.reservedRemaining = _tokenInfo.reservedMaxSupply;
    tokenInfo[lastTokenId] = _tokenInfo;
  }

  function updateMintParams(
    uint256 id,
    uint256 _mintPrice,
    uint256 _mintStartTime,
    uint256 _mintEndTime
  ) external onlyOwner {
    tokenInfo[id].mintPrice = _mintPrice;
    tokenInfo[id].mintStartTime = _mintStartTime;
    tokenInfo[id].mintEndTime = _mintEndTime;
  }

  function updateMaxSupply(
    uint256 id,
    uint256 _maxSupply,
    uint256 _reservedMaxSupply
  ) external onlyOwner {
    // cache to memory
    TokenInfo memory token = tokenInfo[id];

    require(_maxSupply >= token.totalSupply);
    tokenInfo[id].maxSupply = _maxSupply;

    uint256 reservedMinted = token.reservedMaxSupply - token.reservedRemaining;
    require(_reservedMaxSupply >= reservedMinted);
    tokenInfo[id].reservedRemaining = _reservedMaxSupply - reservedMinted;
  }

  function updateURI(uint256 id, string memory newURI) external onlyOwner {
    tokenInfo[id].URI = newURI;
  }

  function claim() external {
    (bool success, ) = owner().call{ value: address(this).balance }("");
    require(success);
  }
}
