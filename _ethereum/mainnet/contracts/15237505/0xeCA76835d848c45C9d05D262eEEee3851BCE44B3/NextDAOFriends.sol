// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721.sol";
import "./ECDSA.sol";

contract NextDAOFriends is ERC721 {
  using ECDSA for bytes32;

  uint256 public _tokenSupply;
  mapping(uint256 => string) public tokenURIs;
  address public constant _signer = 0x0Fe739d1CDD1abDcC9EfA108bc19BDB1BB50b894;

  constructor() ERC721("NextDAO Friends", "NextDAO Friends") {}

  function _hash(uint256 tokenId, address _address)
    internal
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(tokenId, _address));
  }

  function _verify(bytes32 hash, bytes memory token)
    internal
    view
    returns (bool)
  {
    return (_recover(hash, token) == _signer);
  }

  function _recover(bytes32 hash, bytes memory token)
    internal
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function make(
    uint256 tokenId,
    address recipient,
    string calldata uri,
    bytes calldata signature
  ) external {
    require(
      _verify(_hash(tokenId, msg.sender), signature),
      "Invalid signature"
    );
    _mint(recipient, tokenId);
    _tokenSupply += 1;
    tokenURIs[tokenId] = uri;
  }

  function update(uint256 tokenId, string calldata uri) external {
    require(ownerOf(tokenId) == msg.sender, "Only owner can update");
    tokenURIs[tokenId] = uri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(ownerOf(tokenId) != address(0), "Nonexistent token");
    return tokenURIs[tokenId];
  }

  function totalSupply() external view returns (uint256) {
    return _tokenSupply;
  }
}
