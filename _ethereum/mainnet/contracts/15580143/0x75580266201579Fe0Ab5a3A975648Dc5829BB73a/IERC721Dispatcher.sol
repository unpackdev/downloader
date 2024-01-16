// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title IERC721Dispatcher
 * @dev Interface for an ERC721Delegable token dispatcher.
 * @author 0xAnimist (kanon.art)
 */
interface IERC721Dispatcher {

  /**
   * @dev Emitted when a delegate token has been deposited.
   */
  event Deposited(address indexed sourceTokenContract, uint256 indexed sourceTokenId, uint256 tokenId, address depositedBy, bytes[] terms, bytes data);

  /**
   * @dev Emitted when a delegate token has been withdrawn.
   */
  event Withdrawn(address indexed sourceTokenContract, uint256 indexed sourceTokenId, uint256 tokenId, address withdrawnBy, bytes data);

  /**
   * @dev Emitted when an approval request has been granted.
   */
  event ApprovalGranted(address indexed sourceTokenContract, uint256 indexed sourceTokenId, address indexed to, address payee, bytes terms, bytes data);

  /**
   * @dev Emitted when terms are set for a token.
   */
  event TermsSet(address indexed owner, bytes[] terms, uint256 tokenId, bytes data);

  /**
   * @dev Deposits an array of delegate tokens of their corresponding delegable Tokens
   * in exchange for sDQ receipt tokens.
   *
   * Requirements:
   *
   * - must be the owner of the delegate token
   *
   * Emits a {Deposited} event.
   */
  function deposit(address[] memory _ERC721DelegableContract, uint256[] memory _ERC721DelegableTokenId, bytes[][] memory _terms, bytes calldata _data) external returns (uint256[] memory tokenIds);

  /**
   * @dev Withdraws a staked delegate token in exchange for `_tokenId` sDQ token receipt.
   *
   * Emits a {Withdrawn} event.
   */
  function withdraw(uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Sets the terms by which an approval request will be granted.
   *
   * Emits a {TermsSet} event.
   */
  function setTerms(bytes[] memory _terms, uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Gets the terms by which an approval request will be granted.
   */
  function getTerms(uint256 _tokenId) external view returns (bytes[] memory terms);

  /**
   * @dev Gets array of methodIds served by the dispatcher.
   */
  function getServedMethodIds() external view returns (bytes4[] memory methodIds);

  /**
   * @dev Gets timestamp of next availability for `_tokenId` token.
   */
  function getNextAvailable(uint256 _tokenId) external view returns (uint256 availableStartingTime);

  /**
   * @dev Gets source ERC721Delegable token for a given `_tokenId` token.
   */
  function getDepositByTokenId(uint256 _tokenId) external view returns (address contractAddress, uint256 tokenId);

  /**
   * @dev Gets tokenId` token ID for a given source ERC721Delegable token.
   */
  function getTokenIdByDeposit(address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId) external view returns (bool success, uint256 tokenId);

  /**
   * @dev Requests dispatcher call approveByDelegate() on the source ERC721Delegable
   * token corresponding to `_tokenId` token for `_to` address with `_terms` terms.
   */
  function requestApproval(address _payee, address _to, address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId, bytes memory _terms, bytes calldata _data) external payable;

  /**
   * @dev Withdraws fees accrued to all eligible recipients for `_tokenId` token without withdrawing the token itself.
   *
   * Requirements:
   *
   * - token must exist.
   *
   */
  function claimFeesAccrued(uint256 _tokenId) external returns (bool success, address currency);
}
