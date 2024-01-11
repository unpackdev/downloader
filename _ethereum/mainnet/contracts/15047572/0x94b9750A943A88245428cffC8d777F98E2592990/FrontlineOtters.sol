// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./ERC2981.sol";
import "./ERC721A.sol";
import "./Treasury.sol";

struct SaleConfig {
  uint32 preSaleStartTime;
  uint32 publicSaleStartTime;
  uint32 supplyLimit;
  uint96 presaleMintPrice;
  uint96 publicMintPrice;
}

contract FrontlineOtters is Ownable, ERC721A, ERC2981 {
  using SafeCast for uint256;
  using ECDSA for bytes32;

  SaleConfig public saleConfig;
  string public baseURI = "ipfs://QmTZviL8HiEgQkHLFKFCQMFEDizy9VYddvQXjowSmFhNYL/";

  address public whitelistSigner;

  // whitelist and free mints for each phase
  mapping(uint256 => mapping(address => uint256)) private whitelistMinted;
  mapping(uint256 => mapping(address => uint256)) private freeMinted;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("presale(address buyer,uint256 phase,uint256 limit,bool free)");

  Treasury public TeamTreasury;

  address[] private teamPayees = [
    0x34633Cc8274c04ffba637B17B5CCd3DfBfF8B538,
    0xCf2DC66A439869847990Ed75C5233310509ff606,
    0x7023f69a40e1A192Eb3f031e6a8f3Ab5c2336583
  ];

  uint256[] private teamShares = [40, 30, 30];

  address private devWallet = 0x7c792b98dA14Af2Ddc29Dd362B978A3610b2F3F0;

  constructor() ERC721A("Frontline Otters", "FLO") {
    saleConfig = SaleConfig({
      preSaleStartTime: 1656547200, // Thu Jun 30 2022 00:00:00 GMT+0000
      publicSaleStartTime: 1657152000, // Thu Jul 07 2022 00:00:00 GMT+0000
      supplyLimit: 2060,
      presaleMintPrice: 0.06 ether,
      publicMintPrice: 0.08 ether
    });

    TeamTreasury = new Treasury(teamPayees, teamShares);

    _setDefaultRoyalty(address(TeamTreasury), 700); // 7% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes("FrontlineOtters")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }

  function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
    whitelistSigner = newWhitelistSigner;
  }

  function setRoyalties(address recipient, uint96 value) external onlyOwner {
    require(recipient != address(0), "zero address");
    _setDefaultRoyalty(recipient, value);
  }

  function configureSales(
    uint256 preSaleStartTime,
    uint256 publicSaleStartTime,
    uint256 supplyLimit,
    uint256 presaleMintPrice,
    uint256 publicMintPrice
  ) external onlyOwner {
    uint32 _preSaleStartTime = preSaleStartTime.toUint32();
    uint32 _publicSaleStartTime = publicSaleStartTime.toUint32();
    uint32 _supplyLimit = supplyLimit.toUint32();
    uint96 _presaleMintPrice = presaleMintPrice.toUint96();
    uint96 _publicMintPrice = publicMintPrice.toUint96();

    require(0 < _preSaleStartTime, "Invalid time");
    require(_preSaleStartTime < _publicSaleStartTime, "Invalid time");

    saleConfig = SaleConfig({
      preSaleStartTime: _preSaleStartTime,
      publicSaleStartTime: _publicSaleStartTime,
      supplyLimit: _supplyLimit,
      presaleMintPrice: _presaleMintPrice,
      publicMintPrice: _publicMintPrice
    });
  }

  function claimFree(
    bytes calldata signature,
    uint256 phase,
    uint256 amount,
    uint256 approvedLimit
  ) external {
    require(block.timestamp >= saleConfig.preSaleStartTime, "Claim not active");
    require((freeMinted[phase][msg.sender] + amount) <= approvedLimit, "Wallet limit exceeded");

    freeMinted[phase][msg.sender] += amount;
    validateSignatureAndMint(signature, phase, amount, approvedLimit, true);
  }

  function buyPresale(
    bytes memory signature,
    uint256 phase,
    uint256 amount,
    uint256 approvedLimit
  ) external payable {
    require(
      block.timestamp >= saleConfig.preSaleStartTime && block.timestamp < saleConfig.publicSaleStartTime,
      "Presale is not active"
    );
    require(msg.value == (saleConfig.presaleMintPrice * amount), "Incorrect payment");
    require((whitelistMinted[phase][msg.sender] + amount) <= approvedLimit, "Wallet limit exceeded");

    whitelistMinted[phase][msg.sender] += amount;
    validateSignatureAndMint(signature, phase, amount, approvedLimit, false);
  }

  function validateSignatureAndMint(
    bytes memory signature,
    uint256 phase,
    uint256 amount,
    uint256 approvedLimit,
    bool free
  ) private {
    require(whitelistSigner != address(0), "Whitelist signer not yet set");

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(TYPEHASH, msg.sender, phase, approvedLimit, free))
      )
    );

    address signer = digest.recover(signature);

    require(signer != address(0) && signer == whitelistSigner, "Invalid signature");

    mint(msg.sender, amount);
  }

  function buy(uint256 amount) external payable {
    require(block.timestamp >= saleConfig.publicSaleStartTime, "Sale is not active");
    require(msg.value == (saleConfig.publicMintPrice * amount), "Incorrect payment");

    mint(msg.sender, amount);
  }

  function mint(address to, uint256 amount) private {
    require((totalSupply() + amount) <= saleConfig.supplyLimit, "Out of supply");

    _safeMint(to, amount);
  }

  function reserve(address to, uint256 amount) external onlyOwner {
    mint(to, amount);
  }

  function withdraw() external {
    require(address(this).balance > 0, "No balance to withdraw");

    (bool success, ) = devWallet.call{ value: (address(this).balance * 4) / 100 }("");
    require(success, "Withdrawal failed");

    (success, ) = address(TeamTreasury).call{ value: address(this).balance }("");
    require(success, "Withdrawal failed");

    TeamTreasury.withdrawAll();
  }

  function presaleMinted(address wallet, uint256 phase) external view returns (uint256) {
    return whitelistMinted[phase][wallet];
  }

  function freeClaimed(address wallet, uint256 phase) external view returns (uint256) {
    return freeMinted[phase][wallet];
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
