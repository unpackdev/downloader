//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.6;
import "./IERC721.sol";
import "./Ownable.sol";

abstract contract BadCacheI is IERC721, Ownable {
  function setTokenUri(uint256 _tokenId, string memory _tokenURI) public virtual;

  function mint(address _owner, uint256 _tokenId) public virtual;

  function exists(uint256 _tokenId) public view virtual returns (bool);

  function getMaxId() public view virtual returns (uint256);

  function setMaxId(uint256 _newMaxId) public virtual;
}
