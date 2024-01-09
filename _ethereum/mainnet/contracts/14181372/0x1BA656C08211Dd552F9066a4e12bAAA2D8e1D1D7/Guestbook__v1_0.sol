// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";

contract Guestbook__v1_0 is ERC1155, Ownable {
  using ECDSA for bytes32;
  using Strings for uint256;

  // IYK-controlled address to  sign mint messages for txn relayers
  address signVerifier;
  string baseURI;

  // Keep track of minting to an address so a signature cannot be used twice
  mapping(address => uint256) mintNonces;

  // ERC1155 constructor URI functions are overriden
  constructor() ERC1155('unused') {
    signVerifier = 0xF13B8a3f9a44dA0d910C2532CD95c96CA9b5E92a;
    baseURI = 'https://iyk.app/api/metadata/1155/';
  }

  function getSignVerifier() external view returns (address) {
    return signVerifier;
  }

  function setSignVerifier(address verifier) external onlyOwner {
    signVerifier = verifier;
  }

  function setBaseURI(string memory _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function getMintNonce(address account) external view returns (uint256) {
    return mintNonces[account];
  }

  // Signing hash for gating access to txn relayer mint function
  function getMintSigningHash(
    uint256 blockExpiry,
    address account,
    uint256 id
  ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(blockExpiry, account, id, address(this), mintNonces[account]));
  }

  // Minting function with signature for txn relayers
  function mintWithSig(
    address account,
    uint256 id,
    bytes memory data,
    bytes memory sig,
    uint256 blockExpiry
  ) external {
    bytes32 message = getMintSigningHash(blockExpiry, account, id).toEthSignedMessageHash();
    require(ECDSA.recover(message, sig) == signVerifier, 'Permission to call this function failed');
    require(block.number < blockExpiry, 'Sig expired');

    mintNonces[account]++;

    _mint(account, id, 1, data);
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external onlyOwner {
    _mint(account, id, amount, data);
  }

  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function uri(uint256 id) public view override returns (string memory) {
    // From ERC721
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : '';
  }
}
