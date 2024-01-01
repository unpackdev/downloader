// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

struct Recipient {
  address payable recipient;
  uint16 bps;
}

interface IDecaCollection {
  error InvalidTokenId();
  error OnlyCreator();
  error OnlyMinterOrCreator();
  error NotTokenOwnerOrApproved();
  error ERC20SplitFailed();
  error TotalBpsMustBe10000();
  error EthTransferFailed();

  /**
   * @notice Emitted when ETH is transferred.
   * @param account The address of the account which received the ETH.
   * @param amount The amount of ETH transferred.
   */
  event ETHTransferred(address indexed account, uint256 amount);

  /**
   * @notice Emitted when an ERC20 token is transferred.
   * @param erc20Contract The address of the ERC20 contract.
   * @param account The address of the account which received the ERC20.
   * @param amount The amount of ERC20 transferred.
   */
  event ERC20Transferred(address indexed erc20Contract, address indexed account, uint256 amount);

  /**
   * @notice Emitted when the token URI is set on a token.
   * @param tokenId The id of the token.
   * @param tokenURI The token URI of the token.
   */
  event TokenUriSet(uint256 indexed tokenId, string tokenURI);

  /**
   * @notice Emitted when the treasury address is updated.
   * @param treasury The address of the new treasury.
   */
  event TreasuryUpdated(address indexed treasury);

  /**
   * @notice Emitted when the royalty bps is updated.
   * @param royaltyBps The royalty bps.
   */
  event RoyaltyBpsUpdated(uint256 royaltyBps);

  function initialize(
    address factory_,
    address creator_,
    address roleAuthority_,
    string calldata name_,
    string calldata symbol_,
    Recipient[] calldata recipients
  ) external;

  function creator() external view returns (address);

  function exists(uint256 tokenId) external view returns (bool);

  function mint(address to, uint256 tokenId) external;

  function burn(uint256 tokenId) external;

  function mintTimestamps(uint256 tokenId) external view returns (uint256);

  function setRecipients(Recipient[] calldata recipients) external;

  function setTreasuryAddress(address treasury_) external;

  function setRoyaltyBps(uint256 royaltyBps_) external;

  function getRecipients() external view returns (Recipient[] memory);

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}
