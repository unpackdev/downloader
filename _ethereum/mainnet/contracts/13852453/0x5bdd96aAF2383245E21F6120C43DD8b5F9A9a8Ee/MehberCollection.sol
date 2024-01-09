// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./IMehberCollection.sol";
import "./ERC2981.sol";

/// @title MehberCollection
/// @notice An ERC1155 NFT collection
contract MehberCollection is IMehberCollection, Ownable, ERC1155, ERC2981 {
  mapping(address => bool) public approvedMinters;
  mapping(uint256 => bool) public tokenActive;
  mapping(uint256 => uint256) public tokenSupplyLimit;
  mapping(uint256 => uint256) public tokenTotalSupply;
  mapping(uint256 => string) private tokenUri;

  modifier onlyApprovedMinter() {
    require(
      approvedMinters[msg.sender] || msg.sender == owner(),
      "UNAUTHORIZED_MINTER"
    );
    _;
  }

  modifier tokenMustBeActive(uint256 tokenId) {
    require(tokenActive[tokenId], "TOKEN_NOT_ACTIVE");
    _;
  }

  constructor() ERC1155("") {
    _setRoyalties(msg.sender, 500); // 5% royalties by default
  }

  function name() public pure returns(string memory) {
    return "Mehber Collection";
  }

  function symbol() public pure returns(string memory) {
    return "MEHBER";
  }

  /// @notice Allows the contract owner to update royalty info
  /// @param recipient recipient of the royalties
  /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
  function setRoyalties(address recipient, uint256 value) external onlyOwner {
    require(recipient != address(0), "ZERO_ADDRESS");
    _setRoyalties(recipient, value);
  }

  /// @notice Allows the contract owner to approve an address to execute the mint functions
  /// @param minter The address to approve
  function approveMinter(address minter) external onlyOwner {
    approvedMinters[minter] = true;
  }

  /// @notice Allows the contract owner to revoke approval for an address to execute the mint functions
  /// @param minter The address to revoke
  function revokeMinter(address minter) external onlyOwner {
    approvedMinters[minter] = false;
  }

  /// @notice Allows the contract owner to activate a token and set the supply and uri
  /// @dev This is simply a convenient way to set all three parameters in a single transaction
  /// @param tokenId The token to activate
  /// @param supplyLimit The supply limit for the specified token
  /// @param newTokenUri The metadata uri for the specified token
  function initialiseToken(
    uint256 tokenId,
    uint256 supplyLimit,
    string calldata newTokenUri
  ) external onlyOwner {
    tokenActive[tokenId] = true;
    tokenSupplyLimit[tokenId] = supplyLimit;
    tokenUri[tokenId] = newTokenUri;
  }

  /// @notice Allows the contract owner to turn minting on or off for the specified token
  /// @param tokenId The token to activate/deactivate
  function toggleTokenActive(uint256 tokenId) public onlyOwner {
    tokenActive[tokenId] = !tokenActive[tokenId];
  }

  /// @notice Allows the contract owner to update the metadata uri for a specified token
  /// @param tokenId The token to update
  /// @param newTokenUri The metadata uri
  function updateTokenUri(uint256 tokenId, string memory newTokenUri)
    public
    onlyOwner
  {
    tokenUri[tokenId] = newTokenUri;
  }

  /// @notice Allows the contract owner to update the supply limit for a specified token
  /// @param tokenId The token to update
  /// @param newSupplyLimit The new supply limit
  function updateTokenSupplyLimit(uint256 tokenId, uint256 newSupplyLimit)
    public
    onlyOwner
  {
    tokenSupplyLimit[tokenId] = newSupplyLimit;
  }

  /// @inheritdoc	IMehberCollection
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external onlyApprovedMinter tokenMustBeActive(tokenId) {
    require(
      (tokenTotalSupply[tokenId] + amount) <= tokenSupplyLimit[tokenId],
      "OUT_OF_SUPPLY"
    );

    tokenTotalSupply[tokenId] += amount;
    _mint(to, tokenId, amount, "");
  }

  /// @inheritdoc	IMehberCollection
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external onlyApprovedMinter {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(tokenActive[tokenIds[i]], "TOKEN_NOT_ACTIVE");
      require(
        (tokenTotalSupply[tokenIds[i]] + amounts[i]) <=
          tokenSupplyLimit[tokenIds[i]],
        "OUT_OF_SUPPLY"
      );
      tokenTotalSupply[tokenIds[i]] += amounts[i];
    }

    _mintBatch(to, tokenIds, amounts, "");
  }

  /// @inheritdoc	IMehberCollection
  function mintToMany(
    address[] calldata recipients,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external onlyApprovedMinter tokenMustBeActive(tokenId) {
    require(recipients.length == amounts.length, "INPUT_MISMATCH");
    require(recipients.length > 0, "EMPTY_INPUT");

    uint256 supplyLimit = tokenSupplyLimit[tokenId];

    for (uint256 i = 0; i < recipients.length; i++) {
      require(
        (tokenTotalSupply[tokenId] + amounts[i]) <= supplyLimit,
        "OUT_OF_SUPPLY"
      );

      tokenTotalSupply[tokenId] += amounts[i];
      _mint(recipients[i], tokenId, amounts[i], "");
    }
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    return tokenUri[tokenId];
  }

  function totalSupply(uint256 tokenId) public view returns (uint256) {
    return tokenTotalSupply[tokenId];
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
