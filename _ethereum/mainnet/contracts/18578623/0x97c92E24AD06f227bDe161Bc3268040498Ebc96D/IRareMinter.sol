// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author SuperRare Labs Inc.
/// @title IRareMinter
/// @notice Interface for the RareMinter
interface IRareMinter {
  //////////////////////////////////////////////////////////////////////////
  //                      Structs
  //////////////////////////////////////////////////////////////////////////
  /// @notice Direct sale config
  struct DirectSaleConfig {
    address seller;
    address currencyAddress;
    uint256 price;
    uint256 startTime;
    uint256 maxMints;
    address payable[] splitRecipients;
    uint8[] splitRatios;
  }

  /// @notice Allow list config
  struct AllowListConfig {
    bytes32 root;
    uint256 endTimestamp;
  }

  //////////////////////////////////////////////////////////////////////////
  //                      Events
  //////////////////////////////////////////////////////////////////////////
  /// @notice Event emitted when a contract is prepared for direct sale
  event PrepareMintDirectSale(
    address indexed _contractAddress,
    address indexed _currency,
    address indexed _seller,
    uint256 _price,
    uint256 _startTime,
    uint256 _maxMints,
    address payable[] splitRecipients,
    uint8[] splitRatios
  );

  /// @notice Event emitted when a contract is prepared for direct sale
  event MintDirectSale(
    address indexed _contractAddress,
    address indexed _seller,
    address indexed _buyer,
    uint256 _tokenIdStart,
    uint256 _tokenIdEnd,
    address _currency,
    uint256 _price
  );

  /// @notice Event emitted when a contract is set to an allow list config
  event SetContractAllowListConfig(bytes32 indexed _root, uint256 _endTimestamp, address indexed _contractAddress);

  /// @notice Event emitted when a contract is set to a mint limit
  event ContractMintLimitSet(address indexed contractAddress, uint256 limit);

  /// @notice Event emitted when a contract is set to a tx limit
  event ContractTxLimitSet(address indexed contractAddress, uint256 limit);

  //////////////////////////////////////////////////////////////////////////
  //                        External Read Functions
  //////////////////////////////////////////////////////////////////////////

  /// @notice Gets the direct sale config for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @return DirectSaleConfig The direct sale config
  function getDirectSaleConfig(address _contractAddress) external view returns (DirectSaleConfig memory);

  /// @notice Gets the allow list config for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @return AllowListConfig The allow list config
  function getContractAllowListConfig(address _contractAddress) external view returns (AllowListConfig memory);

  /// @notice Gets the mint limit for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @return uint256 The mint limit
  function getContractMintLimit(address _contractAddress) external view returns (uint256);

  /// @notice Gets the number of mints per address for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _address address The address of the account to get the mints for
  function getContractMintsPerAddress(address _contractAddress, address _address) external view returns (uint256);

  /// @notice Gets the tx limit for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  function getContractTxLimit(address _contractAddress) external view returns (uint256);

  /// @notice Gets the number of txs per address for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _address address The address of the account to get the txs for
  function getContractTxsPerAddress(address _contractAddress, address _address) external view returns (uint256);

  //////////////////////////////////////////////////////////////////////////
  //                        External Write Functions
  //////////////////////////////////////////////////////////////////////////

  /// @notice Prepares a minting contract for direct sales
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _currencyAddress address The address of the currency to accept
  /// @param _maxMints uint256 The max number of tokens to mint per transaction
  /// @param _price uint256 The price to mint each token
  /// @param _splitRecipients address payable[] The addresses to split the sale with
  /// @param _splitRatios uint8[] The ratios to split the sale with
  function prepareMintDirectSale(
    address _contractAddress,
    address _currencyAddress,
    uint256 _price,
    uint256 _startTime,
    uint256 _maxMints,
    address payable[] calldata _splitRecipients,
    uint8[] calldata _splitRatios
  ) external;

  /// @notice Mints a token to the buyer
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _currencyAddress address The address of the currency
  /// @param _price uint256 The price to mint
  /// @param _numMints uint8 The number of tokens to be minted
  /// @param _proof bytes32[] The merkle proof for the allowlist if applicable, otherwise empty array
  function mintDirectSale(
    address _contractAddress,
    address _currencyAddress,
    uint256 _price,
    uint8 _numMints,
    bytes32[] calldata _proof
  ) external payable;

  /// @notice Sets the allow list config for a contract
  /// @param _root bytes32 The root of the merkle tree
  /// @param _endTimestamp uint256 The timestamp when the allow list ends
  /// @param _contractAddress address The address of the ERC721 contract
  function setContractAllowListConfig(bytes32 _root, uint256 _endTimestamp, address _contractAddress) external;

  /// @notice Sets the mint limit for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _limit uint256 The limit to set
  function setContractMintLimit(address _contractAddress, uint256 _limit) external;

  /// @notice Sets the tx limit for a contract
  /// @param _contractAddress address The address of the ERC721 contract
  /// @param _limit uint256 The limit to set
  function setContractTxLimit(address _contractAddress, uint256 _limit) external;
}
