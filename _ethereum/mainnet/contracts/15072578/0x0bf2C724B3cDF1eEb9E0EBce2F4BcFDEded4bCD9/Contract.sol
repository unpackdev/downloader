// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ECDSA.sol";

/// @title ASM Scene & Sounds claim contract
/// @author NonFungibleLabs
/// @notice Contract allows whitelisted wallets to claim an ASM scenes & sounds NFT
/// @dev privateClaim is the primary claim function, which can be called by whitelisted wallets
contract ASMSceneClaim is Ownable, ERC1155Holder, ReentrancyGuard {
  using ECDSA for bytes32;

  address public contractAddress; // scenes & sounds contract
  address public signer;
  uint256 public tokenId;
  uint256 public saleNonce = 0;
  mapping(uint256 => mapping(address => bool)) public claimed;
  mapping(bytes => bool) public usedToken;

  enum State {
    Closed,
    PrivateClaim
  }

  State public state;

  constructor(
    address _signer,
    uint256 _tokenId,
    address _contractAddress
  ) {
    signer = _signer;
    tokenId = _tokenId;
    contractAddress = _contractAddress;
  }

  /// @notice Sale nonce allows contract to be re-used for future claims of other ERC1155 tokens
  function setSaleNonce(uint256 _saleNonce) external onlyOwner {
    saleNonce = _saleNonce;
  }

  /// @dev Contract address is the ERC1155 contract address from which the token claims/transfers occur
  function setContractAddress(address _contractAddress) public onlyOwner {
    contractAddress = _contractAddress;
  }

  /// @dev Admin control of contract claim state
  function setClaimToClosed() public onlyOwner {
    state = State.Closed;
  }

  /// @dev Admin control of contract claim state
  function setClaimToPrivate() public onlyOwner {
    state = State.PrivateClaim;
  }

  /// @dev Admin control of signer address which verifies whitelist
  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function setTokenId(uint256 _tokenId) public onlyOwner {
    tokenId = _tokenId;
  }

  /* @dev: Hash function for ECDSA
   * @param: salt and the address to hash it for
   * @returns: keccak256 hash based on salt, contractaddress and the msg.sender
   */
  function _hash(string calldata salt, address _address)
    public
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(salt, address(this), _address));
  }

  /* @dev: Verify whether this hash was signed by the right signer
   * @param: Keccak256 hash, and the given token
   * @returns: Returns whether the signer was correct, boolean
   */
  function _verify(bytes32 hash, bytes memory token)
    public
    view
    returns (bool)
  {
    return (_recover(hash, token) == signer);
  }

  /* @dev: Recovers the hash for the token
   * @param: hash and token
   * @returns: A recovered hash
   */
  function _recover(bytes32 hash, bytes memory token)
    public
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(token);
  }

  function privateClaim(string calldata salt, bytes calldata token)
    external
    nonReentrant
  {
    require(state == State.PrivateClaim, "claim is not active");
    require(!claimed[saleNonce][msg.sender], "user has already claimed");
    require(msg.sender == tx.origin, "contracts cant mint");
    require(!usedToken[token], "already used");
    require(_verify(_hash(salt, msg.sender), token), "invalid token");

    usedToken[token] = true;
    claimed[saleNonce][msg.sender] = true;

    IERC1155(contractAddress).safeTransferFrom(
      address(this),
      msg.sender,
      tokenId,
      1,
      "0x0"
    );
  }

  /// @dev Emergency withdrawal of ERC1155 tokens from the contract, only callable by admin
  /// @param _to The address to transfer the token(s) to
  /// @param _ids The array of token IDs to transfer
  /// @param _amounts The array of amounts to transfer for the respective token IDs
  /// @param _contractAddress The address of the ERC1155 contract to transfer from
  function emergencyWithdrawTokens(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    address _contractAddress
  ) public onlyOwner {
    IERC1155(_contractAddress).safeBatchTransferFrom(
      address(this),
      _to,
      _ids,
      _amounts,
      "0x0"
    );
  }
}
