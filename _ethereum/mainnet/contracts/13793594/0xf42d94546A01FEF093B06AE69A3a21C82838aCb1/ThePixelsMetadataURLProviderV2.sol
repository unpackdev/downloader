// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";

import "./IThePixelsMetadataProvider.sol";

// [X] Phase 1: Move each generated assets to IPFS.
// [_] Phase 2: Store metadata chain with using given DNA.
// [_] Phase 3: Store renderer script with using.
contract ThePixelsMetadataURLProviderV2 is IThePixelsMetadataProvider, Ownable {
  using Strings for uint256;

  struct BaseURL {
    string url;
    string urlForExtensions;
    string description;
  }

  BaseURL[] public baseURLs;

  function addBaseURL(
    string memory _url,
    string memory _urlForExtensions,
    string memory _description
  ) external onlyOwner {
    baseURLs.push(BaseURL(_url, _urlForExtensions, _description));
  }

  function getMetadata(
    uint256 tokenId,
    uint256 dna,
    uint256 dnaExtension
  ) public view override returns (string memory) {

    string memory baseURL;
    if (dnaExtension > 0) {
      baseURL = getLastBaseURLForExtensions();
    }else{
      baseURL = getLastBaseURL();
    }

    string memory url = string(abi.encodePacked(
      baseURL,
      "/",
      dna.toString(),
      getExtensionURLParameter(dnaExtension))
    );
    return url;
  }

  function getExtensionURLParameter(
    uint256 dnaExtension
  ) internal pure returns (string memory) {
    if (dnaExtension == 0) {
      return "";
    }else{
      return string(abi.encodePacked("_", dnaExtension.toString()));
    }
  }

  function getLastBaseURL() public view returns (string memory) {
    if (baseURLs.length > 0) {
      return baseURLs[baseURLs.length - 1].url;
    }
    return "";
  }

  function getLastBaseURLForExtensions() public view returns (string memory) {
    if (baseURLs.length > 0) {
      return baseURLs[baseURLs.length - 1].urlForExtensions;
    }
    return "";
  }
}
