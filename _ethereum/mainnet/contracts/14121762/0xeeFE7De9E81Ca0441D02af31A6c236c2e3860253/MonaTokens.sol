pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Strings.sol";
import "./BaseMonaTokens.sol";
import "./Utils.sol";
import "./console.sol";

contract MonaTokens is BaseMonaTokens, Utils {

  event MintArtist(address indexed to, string uri, uint id);
  event MintArt(address indexed to, string uri, uint id);

  constructor() {
    setDomain("lisamona.xyz");
    setUriPrefix("ipfs://QmZ4HCYbp9ciVEKGK6bPU18duU54VSsCT5sj7iz3LRDayW/");
  }

  function setDomain(string memory _domain) public {
    _requireAdminRole();
    contractURI = string(abi.encodePacked("https://app.", _domain, "/contract-metadata.json"));
  }

  function mintArtist(address _to, uint _artistId) public returns (uint256) {
    _requireMinterRole();
    require(!isMinted(_artistId), "Artist already minted");

    mint(_to, _artistId, 1, "");

    emit MintArtist(_to, uri(_artistId), _artistId);

    return _artistId;
  }

  function mintArt(address _to, uint _artId) public returns (uint256) {
    _requireMinterRole();
    require(!isMinted(_artId), "Art already minted");

    mint(_to, _artId, 1, "");

    emit MintArt(_to, uri(_artId), _artId);

    return _artId;
  }
}
