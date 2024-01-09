pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Strings.sol";
import "./BaseMonaTokens.sol";
import "./Utils.sol";
import "./console.sol";

contract MonaHybrids is BaseMonaTokens, Utils {

  event MintHybrid(address indexed to, string uri, uint id);

  string private domain;

  constructor() {
    setDomain("lisamona.xyz");
  }

  function setDomain(string memory _domain) public {
    _requireAdminRole();
    domain = _domain;
    contractURI = string(abi.encodePacked("https://app.", _domain, "/contract-hybrids-metadata.json"));
    setUriPrefix(string(abi.encodePacked("https://s3.", domain, "/hybrids/")));
  }

  function ipnsUriPrefix() public view returns (string memory) {
    return string(abi.encodePacked("ipfs://ipns/", domain, "/"));
  }

  function ipnsUri(uint _id) public view returns (string memory) {
    return string(abi.encodePacked(ipnsUriPrefix(), Strings.toString(_id), ".json"));
  }

  function mintHybrid(address _to, uint _hybridId) public returns (uint) {
    _requireMinterRole();

    // In the case where the hybrid is already owned by _to, just noop to prevent
    // possible situation where we can't mint an artists creation and it's forever
    // stuck in busy state
    if (tokenOwner[_hybridId] == _to) {
      return _hybridId;
    }

    require(!isMinted(_hybridId), "Already minted");

    mint(_to, _hybridId, 1, "");

    emit MintHybrid(_to, ipnsUri(_hybridId), _hybridId);

    return _hybridId;
  }

  function refreshMetadata(uint[] memory ids) public override(BaseMonaTokens) {
    string[] memory uris = new string[](ids.length);
    for (uint i = 0; i < ids.length; i++) {
      uris[i] = ipnsUri(ids[i]);
    }
    emit RefreshMetadata(ids, uris);
  }
}
