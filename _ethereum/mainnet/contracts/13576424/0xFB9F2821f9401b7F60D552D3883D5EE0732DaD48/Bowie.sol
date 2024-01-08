// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ITokenStorage.sol";
import "./TokenUriBase.sol";

contract Bowie is TokenUriBase {

  // the token id in the storage contract
  uint256 public constant STORAGE_CONTRACT_TOKEN_ID = 6277101735386680764176071790128604879584176795969512275969;

  // the filename in the storage contract
  uint256 public constant STORAGE_IMAGE_FILENAME = 27329944878097617768954940092176689836235260765755403534686908519;

  // the size of the image in the storage contract
  uint256 public constant STORAGE_IMAGE_SIZE = 77532;

  // this changes between rinkeby and mainnet so it's a constructor param
  address internal _storageContractAddress;

  constructor (
    string memory name_,
    string memory symbol_,
    address openseaProxyRegistryAddress_,
    address payable royaltyAddress_,
    uint256 royaltyBps_,
    address storageContractAddress_
  ) TokenUriBase(name_, symbol_, openseaProxyRegistryAddress_, royaltyAddress_, royaltyBps_) {
    require(storageContractAddress_ != address(0), "Bowie: storage cannot be zero address");
    require(ITokenStorage(storageContractAddress_).getFileNames(STORAGE_CONTRACT_TOKEN_ID).length > 0, "Bowie: storage must have filename");
    require(ITokenStorage(storageContractAddress_).getFileBatchLength(STORAGE_CONTRACT_TOKEN_ID, STORAGE_IMAGE_FILENAME) > 0, "Bowie: storage must have batches");
    require(ITokenStorage(storageContractAddress_).isFinalized(STORAGE_CONTRACT_TOKEN_ID), "Bowie: storage must be finalized");
    _storageContractAddress = storageContractAddress_;
  }

  function imageSize() public pure returns (uint256) {
    return STORAGE_IMAGE_SIZE;
  }

  function imageBatches() public view returns (uint256) {
    return ITokenStorage(_storageContractAddress).getFileBatchLength(STORAGE_CONTRACT_TOKEN_ID, STORAGE_IMAGE_FILENAME); 
  }

  function imageData(uint256 batchIndex) public view returns (uint256[] memory) {
    return ITokenStorage(_storageContractAddress).getFileBatchData(STORAGE_CONTRACT_TOKEN_ID, STORAGE_IMAGE_FILENAME, batchIndex); 
  }

  function isGenuine() public view returns (bool) {
    return Ownable(_storageContractAddress).owner() == owner();
  }
}
