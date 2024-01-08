// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract TokenStorage is Ownable {

  // token_id -> filename -> file batches
  mapping (uint256 => mapping(uint256 => uint256[][])) internal _tokenFileData;

  // so we can list the filenames & sizes associated with a token
  mapping (uint256 => uint256[]) internal _tokenFileNames;
  mapping (uint256 => uint256[]) internal _tokenFileSizes;

  // once this is set - we can never change the storage for this token
  mapping (uint256 => bool) internal _finalized;

  constructor ()  {}

  // store the filename of a new file
  // this unlocks the ability to start adding data to that file
  function createFile(uint256 tokenId, uint256 name, uint256 size) external onlyOwner {
    require(!_finalized[tokenId], "0x40");
    _tokenFileNames[tokenId].push(name);
    _tokenFileSizes[tokenId].push(size);
  }

  // return an array of filenames for the token
  function getFileNames(uint256 tokenId) public view returns (uint256[] memory) {
    return _tokenFileNames[tokenId];
  }

  function getFileSizes(uint256 tokenId) public view returns (uint256[] memory) {
    return _tokenFileSizes[tokenId];
  }

  // add data to a file
  // the token must not be finalized
  // the file must exist and have a non-zero size
  // the batchIndex must be an empty array
  function writeFileBatch(uint256 tokenId, uint256 fileName, uint256 batchIndex, uint256[] calldata batchData) external onlyOwner {
    require(!_finalized[tokenId], "0x40");
    uint256[][] storage fileStorage = _tokenFileData[tokenId][fileName];
    require(fileStorage.length == batchIndex, "0x43");
    fileStorage.push(batchData);
  }

  // prevent any more changes happening to a given token
  function finalizeToken(uint256 tokenId) external onlyOwner {
    require(!_finalized[tokenId], "0x40");
    _finalized[tokenId] = true;
  }

  function isFinalized(uint256 tokenId) public view returns (bool) {
    return _finalized[tokenId];
  }

  // how many batches is a file saved in
  // this let's the client iterate over batches to rebuild the file
  function getFileBatchLength(uint256 tokenId, uint256 fileName) public view returns (uint256) {
    return _tokenFileData[tokenId][fileName].length;
  }

  // get a single batch for some media
  // the client must loop over batches because whilst it's a "view" function
  // it's still subject to block has limits
  function getFileBatchData(uint256 tokenId, uint256 fileName, uint256 batchIndex) public view returns (uint256[] memory) {
    return _tokenFileData[tokenId][fileName][batchIndex];
  }
}
