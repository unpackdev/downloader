// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./IERC721.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

struct MintConfig {
  uint8 txLimit;
  uint32 holderMintStartTime;
  uint32 publicMintStartTime;
  uint88 holdersMintPrice;
  uint88 publicMintPrice;
}

contract degENCRYPTAS is Ownable, ERC721A, ERC2981, PaymentSplitter {
  using ECDSA for bytes32;
  // EVENTS *****************************************************

  event ConfigUpdated(bytes32 config, bytes value);
  event ConfigLocked(bytes32 config);
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  // ERRORS *****************************************************

  error InvalidConfig(bytes32 config);
  error ConfigIsLocked(bytes32 config);
  error Unauthorized();
  error NonExistentToken(uint256 tokenId);
  error NoMintSigner();
  error InvalidSignature();
  error InsufficientPayment();
  error MintLimitExceeded();
  error HolderOnly();
  error MintNotActive();
  error OutOfSupply();
  error ZeroBalance();
  error WithdrawalFailed();

  // Storage *****************************************************

  /// @notice Maximum tokenId that can be minted
  uint256 public constant MAX_SUPPLY = 4969;

  /// @dev The Encryptas ERC721 contract
  IERC721 public Encryptas;

  /// @dev The 101Babes contract
  IERC721 public Babes;

  /// @dev config data for this mint contract
  MintConfig public mintConfig;

  /// @dev The public address of the authorized signer used to create the holder mint signature
  address public mintSigner;

  /// @notice BaseURI for token metadata
  string public baseURI = "https://nft-metadata.eleventhstudio.xyz/collection/degencryptas/";

  /// @notice Contract metadata URI
  string public contractURI = "ipfs://bafkreiazvb3y3w4vg3wvup7v5elf5urkz3zwzg27zy3cgvsmhsswjw5u64";

  // Private ****************************

  // Tracks which config items are locked permanently and unable to be updated
  mapping(bytes32 => bool) private configLocked;

  /// @dev used for decoding the holder mint signature
  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("holderMint(address buyer)");

  address[] private mintPayees = [
    0x19461698453e26b98ceE5B984e1a86e13C0f68Be,
    0x2E00f1f1C643Bb444be4fE0aaE2393476ae53B84,
    0xa99c2431065A1909Afbff77329b206d94dfCDB27
  ];

  uint256[] private mintShares = [485, 485, 30];

  // Constructor *****************************************************

  constructor(
    address babesAddress,
    address encryptasAddress
  ) ERC721A("degENCRYPTAS", "degEN") PaymentSplitter(mintPayees, mintShares) {
    _setDefaultRoyalty(0xc07C3473D6DA7D2612F696012A15948C09C3966d, 500); // 5% royalties

    Babes = IERC721(babesAddress);
    Encryptas = IERC721(encryptasAddress);

    mintConfig = MintConfig({
      txLimit: 100,
      holderMintStartTime: 1698415200, // Friday, 27 October 2023 14:00:00 GMT+0000
      publicMintStartTime: 1698501600, // Saturday, 28 October 2023 14:00:00 GMT+0000
      holdersMintPrice: 0.0169 ether,
      publicMintPrice: 0.0269 ether
    });

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("degENCRYPTAS")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // Owner Methods *****************************************************

  function updateConfig(bytes32 config, bytes calldata value) external onlyOwner {
    if (configLocked[config]) revert ConfigIsLocked(config);

    if (config == "baseURI") {
      baseURI = abi.decode(value, (string));
      emit BatchMetadataUpdate(1, type(uint256).max);
    } else if (config == "contractURI") contractURI = abi.decode(value, (string));
    else if (config == "h_price") mintConfig.holdersMintPrice = abi.decode(value, (uint88));
    else if (config == "p_price") mintConfig.publicMintPrice = abi.decode(value, (uint88));
    else if (config == "h_start") mintConfig.holderMintStartTime = abi.decode(value, (uint32));
    else if (config == "p_start") mintConfig.publicMintStartTime = abi.decode(value, (uint32));
    else if (config == "limit") mintConfig.txLimit = abi.decode(value, (uint8));
    else if (config == "signer") mintSigner = abi.decode(value, (address));
    else if (config == "royalty") {
      (address recipient, uint96 numerator) = abi.decode(value, (address, uint96));
      _setDefaultRoyalty(recipient, numerator);
    } else revert InvalidConfig(config);

    emit ConfigUpdated(config, value);
  }

  function lockConfig(bytes32 config) external onlyOwner {
    configLocked[config] = true;

    emit ConfigLocked(config);
  }

  /// @notice Allows the contract owner to withdraw the current balance stored in this contract into withdrawalAddress
  function withdraw() external onlyOwner {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < mintPayees.length; i++) {
      release(payable(payee(i)));
    }
  }

  // Public Methods *****************************************************

  /// @notice Function for holders of 101Babes or Encryptas to mint
  /// @dev Original 101Babes holders verified through offchain process via mintSigner
  /// @param signature The signature produced by the mintSigner to validate that the recipient is a 101Babes holder
  /// @param to The address to mint to
  /// @param amount The number of tokens to mint
  function holderMint(bytes memory signature, address to, uint256 amount) external payable {
    if (Encryptas.balanceOf(to) == 0 && Babes.balanceOf(to) == 0) {
      if (signature.length == 0) revert HolderOnly();

      if (mintSigner == address(0)) revert NoMintSigner();

      bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(TYPEHASH, to))));
      address signer = digest.recover(signature);

      if (signer != mintSigner) revert InvalidSignature();
    }

    if (msg.value < (mintConfig.holdersMintPrice * amount)) revert InsufficientPayment();
    if (block.timestamp < mintConfig.holderMintStartTime || block.timestamp > mintConfig.publicMintStartTime)
      revert MintNotActive();

    mint(to, amount);
  }

  /// @notice Function for anyone to mint
  /// @param to The address to mint to
  /// @param amount The number of tokens to mint
  function publicMint(address to, uint256 amount) external payable {
    if (msg.value < (mintConfig.publicMintPrice * amount)) revert InsufficientPayment();
    if (block.timestamp < mintConfig.publicMintStartTime) revert MintNotActive();

    mint(to, amount);
  }

  // Private Methods *****************************************************

  function mint(address to, uint256 amount) private {
    MintConfig memory _config = mintConfig;

    if ((totalSupply() + amount) > MAX_SUPPLY) revert OutOfSupply();

    if (amount > _config.txLimit) revert MintLimitExceeded();

    _mint(to, amount);
  }

  // Override Methods *****************************************************

  /// @notice Returns the metadata URI for a given token
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) revert NonExistentToken(tokenId);

    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC2981, ERC721A) returns (bool) {
    return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }
}
