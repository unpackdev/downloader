// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC1155.sol";
import "./ERC1155Royalty.sol";
import "./TokenIdentifiers.sol";
import "./ERC1155SignatureMint.sol";
import "./ERC1155URIStorage.sol";

contract LoveNFTShared is ERC1155, Ownable, ERC1155Royalty, ERC1155URIStorage, ERC1155SignatureMint {
  using TokenIdentifiers for uint256;
  using Strings for uint256;

  string public constant symbol = 'LPM_NFT';
  string public constant name = 'LoveNFT Collections';
  uint96 public constant MAXIMUM_ROYALTY_FEE = 2000; // 20%
  // Mapping of minted tokens
  mapping(uint256 tokenId => bool isMinted) private _minted;
  // Total amount of tokens minted
  uint256 private _totalSupply;
  address private immutable _operator;

  constructor(address operator) ERC1155('https://lpm.is/api/token/{id}') ERC1155SignatureMint('LoveNFTShared', '1') {
    require(operator != address(0), 'Invalid address');
    _operator = operator;
  }

  function redeem(address account, MintRequest calldata _req, bytes calldata signature) external {
    require(msg.sender == _operator, 'Only operator can redeem');
    address signer = _req.tokenId.tokenCreator();
    _processRequest(signer, _req, signature);
    _mintWithURI(account, _req.tokenId, _req.uri);
    if (_req.royaltyRecipient != address(0)) {
      require(_req.royaltyFraction <= MAXIMUM_ROYALTY_FEE, 'invalid royalty fee');
      _setTokenRoyalty(_req.tokenId, _req.royaltyRecipient, _req.royaltyFraction);
    }
  }

  function uri(uint256 tokenId) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
    return super.uri(tokenId);
  }

  function setTokenRoyalty(uint256 id, address receiver, uint96 feeNumerator) external {
    require(msg.sender == id.tokenCreator(), 'Only creator can set royalty');
    require(feeNumerator <= MAXIMUM_ROYALTY_FEE, 'invalid royalty fee');
    (, uint256 currentFeeFraction) = royaltyInfo(id, uint256(_feeDenominator()));
    require(uint256(feeNumerator) <= currentFeeFraction, 'new fee too high');
    _setTokenRoyalty(id, receiver, feeNumerator);
  }

  function exists(uint256 tokenId) public view returns (bool) {
    return _minted[tokenId];
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function decodeTokenId(uint256 tokenId) public pure returns (address creator, uint256 index, uint256 collection) {
    return tokenId.decodeTokenId();
  }

  function encodeTokenId(address creator, uint256 index, uint256 collection) public pure returns (uint256) {
    return TokenIdentifiers.createTokenId(creator, index, collection);
  }

  function _mintWithURI(address to, uint256 id, string memory tokenURI) internal {
    _mint(to, id, 1, '');
    _setTokenURI(id, tokenURI);
  }

  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override(ERC1155) {
    require(!_minted[id], 'Token already minted');
    _minted[id] = true;
    ++_totalSupply;
    super._mint(to, id, amount, data);
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155) {
    uint256 length = ids.length;
    for (uint256 i = 0; i < length; ++i) {
      require(!_minted[ids[i]], 'Token already minted');
      _minted[ids[i]] = true;
    }
    super._mintBatch(to, ids, amounts, data);
    _totalSupply += length;
  }

  function _burn(address account, uint256 id, uint256 amount) internal override(ERC1155, ERC1155Royalty) {
    super._burn(account, id, amount);
    _totalSupply--;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Royalty) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
