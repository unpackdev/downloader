// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IAlunaverse.sol";

/// @title Alunaverse Minter
/// @notice Minter contract for Alunaverse NFT collection, supports ECDSA Signature based whitelist minting, and public access minting.
contract AlunaverseMinter is Ownable {
  using ECDSA for bytes32;

  /// @dev The Alunaverse ERC1155 contract
  IAlunaverse public Alunaverse;

  /// @dev Mapping between tokenId and mint price
  mapping(uint256 => uint256) public tokenMintPrice;

  /// @dev Mapping between tokenId and whether public minting is enabled, if false the only whitelisted minting is permitted
  mapping(uint256 => bool) public tokenPublicSaleEnabled;

  /// @dev Keeps track of how many of each token a wallet has minted, used for enforing wallet limits for whitelist minting
  mapping(address => mapping(uint256 => uint256)) public whitelistMinted;

  /// @dev The public address of the authorized signer used to create the whitelist mint signature
  address public whitelistSigner;

  address payable public withdrawalAddress;

  /// @dev used for decoding the whitelist mint signature
  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private WHITELIST_TYPEHASH =
    keccak256("whitelistMint(address buyer,uint256 tokenId,uint256 limit)");

  constructor(address alunaverseAddress) {
    Alunaverse = IAlunaverse(alunaverseAddress);

    withdrawalAddress = payable(msg.sender);

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("AlunaverseMinter")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  /// @notice Allows the contract owner to update the mint price for the specified token
  /// @param tokenId The token to update
  /// @param mintPrice The new mint price
  function updateTokenMintPrice(uint256 tokenId, uint256 mintPrice)
    public
    onlyOwner
  {
    tokenMintPrice[tokenId] = mintPrice;
  }

  /// @notice Allows the contract owner to toggle whether public minting is permitted for the specified token
  /// @param tokenId The token to update
  function toggleTokenPublicSale(uint256 tokenId) public onlyOwner {
    tokenPublicSaleEnabled[tokenId] = !tokenPublicSaleEnabled[tokenId];
  }

  /// @notice Allows the contract owner to set a new whitelist signer
  /// @dev The corresponding private key of the whitelist signer should be used to generate the signature for whitelisted addresses
  /// @param newWhitelistSigner Address of the new whitelist signer
  function updateWhitelistSigner(address newWhitelistSigner) public onlyOwner {
    whitelistSigner = newWhitelistSigner;
  }

  /// @notice Allows the contract owner to set the address where withdrawals should go
  /// @param newAddress The new withdrawal address
  function updateWithdrawalAddress(address payable newAddress)
    external
    onlyOwner
  {
    withdrawalAddress = newAddress;
  }

  /// @notice External function for whitelisted addresses to mint
  /// @param signature The signature produced by the whitelist signer to validate that the msg.sender is on the approved whitelist
  /// @param tokenId The token to mint
  /// @param numberOfTokens The number of tokens to mint
  /// @param approvedLimit The total approved number of tokens that the msg.sender is allowed to mint, this number is also validated by the signature
  function whitelistMint(
    bytes memory signature,
    uint256 tokenId,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    require(whitelistSigner != address(0), "NO_WHITELIST_SIGNER");
    require(
      msg.value == tokenMintPrice[tokenId] * numberOfTokens,
      "INCORRECT_PAYMENT"
    );
    require(
      (whitelistMinted[msg.sender][tokenId] + numberOfTokens) <= approvedLimit,
      "WALLET_LIMIT_EXCEEDED"
    );
    whitelistMinted[msg.sender][tokenId] =
      whitelistMinted[msg.sender][tokenId] +
      numberOfTokens;

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(
          abi.encode(WHITELIST_TYPEHASH, msg.sender, tokenId, approvedLimit)
        )
      )
    );

    address signer = digest.recover(signature);

    require(
      signer != address(0) && signer == whitelistSigner,
      "INVALID_SIGNATURE"
    );

    Alunaverse.mint(msg.sender, tokenId, numberOfTokens);
  }

  /// @notice External function for anyone to mint, as long as tokenPublicSaleEnabled = true
  /// @param tokenId The token to mint
  /// @param numberOfTokens The number of tokens to mint
  function publicMint(uint256 tokenId, uint256 numberOfTokens)
    external
    payable
  {
    require(tokenPublicSaleEnabled[tokenId], "PUBLIC_SALE_DISABLED");
    require(
      msg.value == tokenMintPrice[tokenId] * numberOfTokens,
      "INCORRECT_PAYMENT"
    );

    Alunaverse.mint(msg.sender, tokenId, numberOfTokens);
  }

  /// @notice Allows the contract owner to withdraw the current balance stored in this contract into withdrawalAddress
  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "ZERO_BALANCE");

    (bool success, ) = withdrawalAddress.call{ value: address(this).balance }(
      ""
    );
    require(success, "WITHDRAWAL_FAILED");
  }
}
