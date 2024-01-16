// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Address.sol";
import "./MerkleProof.sol";

/**
 * @title Token contract for the Nifty Mint Claim
 * @author maikir
 * @author lightninglu10
 *
 */
contract NewHereClaim is ERC1155Supply, Ownable {
  event PermanentURI(string _value, uint256 indexed _id);
  //todo:
  string public constant name = "I'm New Here Mint Claim";
  string public constant symbol = "INHMC";

  mapping(uint256 => bytes32) public merkleRoots;
  mapping(address => bool) public claimed;

  using Address for address;
  uint256 public totalTokens = 0;
  mapping(uint256 => string) public tokenURIS;
  mapping(uint256 => bool) public tokenIsFrozen;
  mapping(address => bool) private admins;

  // Sale toggle
  bool public isClaimActive = false;

  constructor(string[] memory _tokenURIs, bytes32 _initialRoot)
    ERC1155("")
  {
    for (uint256 i = 0; i < _tokenURIs.length; i++) {
      addToken(_tokenURIs[i]);
    }

    merkleRoots[1] = _initialRoot;
  }

  modifier onlyAdmin() {
    require(owner() == msg.sender || admins[msg.sender], "No Access");
    _;
  }

  /**
   * @dev Set merkle trees.
   */
  function setMerkleTree(
      bytes32 _root,
      uint256 _merkleTreeNum
  )
      external
      onlyAdmin
  {
      merkleRoots[_merkleTreeNum] = _root;
  }

  /**
   * @dev Allows or disables ability to mint.
   */
  function flipClaimState() external onlyAdmin {
    isClaimActive = !isClaimActive;
  }

  function setAdmin(address _addr, bool _status) external onlyOwner {
    admins[_addr] = _status;
  }

  function addToken(string memory _uri) public onlyAdmin {
    totalTokens += 1;
    tokenURIS[totalTokens] = _uri;
    tokenIsFrozen[totalTokens] = false;
  }

  function updateTokenData(uint256 id, string memory _uri)
    external
    onlyAdmin
    tokenExists(id)
  {
    require(tokenIsFrozen[id] == false, "This can no longer be updated");
    tokenURIS[id] = _uri;
  }

  function freezeTokenData(uint256 id) external onlyAdmin tokenExists(id) {
    tokenIsFrozen[id] = true;
    emit PermanentURI(tokenURIS[id], id);
  }

  /**
   * @dev Function called to return if an address is allowlisted.
   * @param proof Merkel tree proof.
   * @param _address Address to check.
   * @param _allowlistNum Allowlist number to check.
   */
  function isAllowlisted(
      bytes32[] calldata proof,
      address _address,
      uint256 _allowlistNum
  ) public view returns (bool) {
      bytes32 root = merkleRoots[_allowlistNum];
      if (
          MerkleProof.verify(
              proof,
              root,
              keccak256(abi.encodePacked(_address))
          )
      ) {
          return true;
      }
      return false;
  }

  /**
   * @dev Function called to claim free mint.
   * @param id Token id.
   * @param proof Merkel tree proof.
   * @param _allowlistNum Allowlist number/index.
   */
  function claim(
    uint256 id,
    bytes32[] calldata proof,
    uint256 _allowlistNum
  ) external tokenExists(id) {
    require(isClaimActive, "Sale is not active");
    require(
      isAllowlisted(proof, msg.sender, _allowlistNum),
      "Claimer is not allowlisted with the specified allowlist"
    );
    _mint(msg.sender, id, 1, "");
  }

  function mintBatch(
    address to,
    uint256[] calldata ids,
    uint256[] calldata amount
  ) external onlyAdmin {
    _mintBatch(to, ids, amount, "");
  }


  function mintTo(
    address account,
    uint256 id,
    uint256 qty
  ) external onlyAdmin tokenExists(id) {
    _mint(account, id, qty, "");
  }

  function mintToMany(
    address[] calldata to,
    uint256 id,
    uint256 qty
  ) external onlyAdmin tokenExists(id) {

    for (uint256 i = 0; i < to.length; i++) {
      _mint(to[i], id, qty, "");
    }
  }

  function uri(uint256 id)
    public
    view
    virtual
    override
    tokenExists(id)
    returns (string memory)
  {
    return tokenURIS[id];
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return uri(tokenId);
  }

  modifier tokenExists(uint256 id) {
    require(id > 0 && id <= totalTokens, "Token Unexists");
    _;
  }
}
