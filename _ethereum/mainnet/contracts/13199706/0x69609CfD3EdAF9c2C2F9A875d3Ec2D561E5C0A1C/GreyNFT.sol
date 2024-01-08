  // SPDX-License-Identifier: MIT
pragma solidity >= 0.6.0;

import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./ERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./MinterRole.sol";

contract GreyNFT is IERC1155MetadataURI, ERC1155, ERC1155Holder, MinterRole, Ownable {

  uint256 totalCount = 0;
  mapping(uint256 => string) public tokenURIList;
  uint256 MAX_BATCH_MINT_COUNT = 200;
  event MaxBatchMintCountUpdated(uint256 _maxTxAmount);

  constructor() public ERC1155('https://ipfs.io/ipfs/{id}') {
  }

  function uri(uint256 id) external view override returns (string memory) {
    require(id < totalCount, "Invalid id");
    return string(abi.encodePacked("https://ipfs.io/ipfs/", tokenURIList[id]));
  }

  function count() external view returns (uint256) {
    return totalCount;
  }

  function mintWithTokenURI (
    address to,
    uint256 amount,
    string calldata tokenURI,
    bytes calldata data
  ) external onlyMinter() returns (bool) {
    require(amount > 0 && amount <= MAX_BATCH_MINT_COUNT, "Count exceeds the limit");
    _mint(to, totalCount, amount, data);
    tokenURIList[totalCount] = tokenURI;
    totalCount = totalCount + 1;
    return true;
  }

  function maxBatchMintCount() public view returns (uint256) {
    return MAX_BATCH_MINT_COUNT;
  }

  function setMaxBatchMintCount(uint256 _maxBatchMintCount) external onlyOwner() {
    MAX_BATCH_MINT_COUNT = _maxBatchMintCount;
    emit MaxBatchMintCountUpdated(_maxBatchMintCount);
  }
}