//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "./base64.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Viper.sol";

/// @title Viper Metadata
/// @notice https://viper.folia.app
/// @author @okwme
/// @dev The updateable and replaceable metadata contract for Viper and BiteByViper

contract Metadata is Ownable {
  constructor() {}

  string public baseURI = "https://viper.folia.app/v1/metadata/";

  /// @dev sets the baseURI can only be called by the owner
  /// @param baseURI_ the new baseURI
  function setbaseURI(string memory baseURI_) public onlyOwner {
    baseURI = baseURI_;
  }

  /// @dev generates the metadata
  /// @param tokenId the tokenId
  /// @return _ the metadata
  function getMetadata(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }
}
