// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Clones.sol";
import "./OwnableUpgradeable.sol";

import "./DynamicNft.sol";
import "./IDynamicNftFactory.sol";

contract DynamicNftFactory is OwnableUpgradeable, IDynamicNftFactory{
  using Clones for address;

  address private implementationContract;

  event DynamicNFTCreated(address clone);

  function initialize(
    address implementationContract_
  ) public initializer {
    __Ownable_init();
    implementationContract = implementationContract_;
  }

  function createDynamicNFT(
    string memory nftName,
    string memory nftSymbol
  ) public override returns (address clone_){
    require(bytes(nftName).length > 0, 'DynamicNftFactory: Name should not be empty');
    require(bytes(nftSymbol).length > 0, 'DynamicNftFactory: Symbol should not be empty');

    clone_ = Clones.clone(implementationContract);
    _initializeClone(
      clone_,
      nftName,
      nftSymbol
    );
  }

  function getImplementationContract() public view onlyOwner override returns (address){
    return implementationContract;
  }

  function setImplementationContract( 
    address implementationContract_ 
  ) external onlyOwner override {
      implementationContract = implementationContract_;
  }

  function _initializeClone(
    address clone_,
    string memory nftName,
    string memory nftSymbol
  ) private {
    DynamicNft(clone_).initialize(
      nftName,
      nftSymbol
    );

    emit DynamicNFTCreated(clone_);
  }
}