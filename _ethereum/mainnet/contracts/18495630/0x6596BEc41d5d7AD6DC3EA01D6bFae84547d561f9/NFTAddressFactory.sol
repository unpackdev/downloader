// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Errors.sol";
import "./IFactory.sol";
import "./Registrar.sol";
import "./SafeCreate3.sol";

/// @title NFTAddressFactory
/// @notice Main Factory used to mint and deploy NFT addresses.
contract NFTAddressFactory is IFactory {
  Registrar private _registrar;

  mapping(address nftAddress => uint256 salt) private salts;

  /// @param registrar Address of the Registrar
  constructor(Registrar registrar) {
    _registrar = registrar;
  }

  /// @notice Deploys a smart contract to an NFT address
  /// @param nftAddress NFT address
  /// @param creationCode Smart contract bytecode (i.e. bytecode containing the constructor and
  /// initialization data)
  function deploy(address nftAddress, bytes memory creationCode) external {
    require(msg.sender == address(_registrar), Errors.NOT_REGISTRAR);

    address mintedBy = _registrar.getMintedBy(uint256(uint160(nftAddress)));
    address deployedAddress = SafeCreate3.deploy(
      bytes32(salts[nftAddress]),
      mintedBy,
      creationCode,
      0
    );

    require(deployedAddress == nftAddress, Errors.INVALID_ADDRESS_CREATED);
  }

  /// @notice Returns the NFT address created by `mintedBy` with `salt`
  /// @param mintedBy Account that minted the NFT address
  /// @param salt Salt used to generate the NFT address
  function getAddress(address mintedBy, uint256 salt) public view returns (address payable) {
    return payable(SafeCreate3.getDeployed(bytes32(salt), mintedBy));
  }

  /// @notice Mints a new NFT address, created by `mintedBy` with `salt`
  /// @param mintedBy Account that is minting the NFT address
  /// @param salt Salt used to generate the NFT address
  function mint(address mintedBy, uint256 salt) external returns (address payable) {
    require(msg.sender == address(_registrar), Errors.NOT_REGISTRAR);

    address payable addr = getAddress(mintedBy, salt);
    salts[addr] = salt;
    return addr;
  }
}
