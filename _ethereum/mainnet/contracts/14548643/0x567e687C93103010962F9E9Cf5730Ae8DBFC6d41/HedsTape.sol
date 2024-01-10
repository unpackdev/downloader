// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

error InsufficientFunds();
error ExceedsMaxSupply();
error BeforeSaleStart();
error FailedTransfer();

/// @title ERC721 contract for https://heds.io/ HedsTape
/// @author https://github.com/kadenzipfel
contract HedsTape is ERC721A, Ownable {
  struct SaleConfig {
    uint64 price;
    uint32 maxSupply;
    uint32 startTime;
  }

  /// @notice NFT sale data
  /// @dev Sale data packed into single storage slot
  SaleConfig public saleConfig;

  // TODO: pre-fill with uri
  string private baseUri = 'ipfs://QmcQ5JySJAZC1sj69HGChncXx2omact5wFYEoxCoYv6scx';

  constructor() ERC721A("hedsTAPE 3", "HT3") {
    saleConfig.price = 0.1 ether;
    saleConfig.maxSupply = 500;
    saleConfig.startTime = 1649530800;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /// @notice Mint a HedsTape token
  /// @param _amount Number of tokens to mint
  function mintHead(uint _amount) external payable {
    SaleConfig memory config = saleConfig;
    uint _price = uint(config.price);
    uint _maxSupply = uint(config.maxSupply);
    uint _startTime = uint(config.startTime);

    if (_amount * _price != msg.value) revert InsufficientFunds();
    if (_currentIndex + _amount > _maxSupply + 1) revert ExceedsMaxSupply();
    if (block.timestamp < _startTime) revert BeforeSaleStart();

    _safeMint(msg.sender, _amount);
  }
 
  /// @notice Update baseUri - must be contract owner
  function setBaseUri(string calldata _baseUri) external onlyOwner {
    baseUri = _baseUri;
  }

  /// @notice Return tokenURI for a given token
  /// @dev Same tokenURI returned for all tokenId's
  function tokenURI(uint _tokenId) public view override returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
    return baseUri;
  }

  /// @notice Update sale start time - must be contract owner
  function updateStartTime(uint32 _startTime) external onlyOwner {
    saleConfig.startTime = _startTime;
  }

  /// @notice Withdraw contract balance - must be contract owner
  function withdraw() public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    if (!success) revert FailedTransfer();
  }
}
