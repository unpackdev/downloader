// SPDX-License-Identifier: None
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./DragonForge.sol";

struct SaleConfig {
  uint32 preSaleStartTime;
  uint32 publicSaleStartTime;
  uint32 mintLimit;
  uint64 presaleMintPrice;
  uint64 publicMintPrice;
}

error InvalidTime();
error SaleNotActive();
error SignerNotSet();
error InvalidSignature();
error IncorrectPayment();
error MintLimitExceeded();

contract DragonForgeMinter is Ownable, PaymentSplitter {
  using SafeCast for uint256;
  using ECDSA for bytes32;

  DragonForge DragonForgeNFT;

  SaleConfig public saleConfig;
  address public allowListSigner;

  mapping(address => uint256) public totalMinted;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private TYPEHASH = keccak256("presale(address buyer,uint256 limit)");

  address[] private _payees = [
    0xb87F75A1165DaBbedBE4c2784C1130897c790C4f,
    0x1BA6A65Ac7bc72EFCDFa8935fAFd826150013765,
    0xc0dD320CeF1f15bf60FA87dD9F80b2686E7B434F,
    0xef77Cf894ED766B233e2009658e55f49D6C3440d,
    0xc2B224996e1318641Fa6990364B94Af42A298771,
    0x13E5FBB2F32a01A15d57F5E93A75145fD6CdA982,
    0x4e1C09bC01934C11ADb6bB04D93451264FfcfAD5 
  ];

  uint256[] private _shares = [600, 170, 100, 55, 25, 25, 25];

  constructor(address payable dragonForgeAddress)
    PaymentSplitter(_payees, _shares)
  {
    DragonForgeNFT = DragonForge(dragonForgeAddress);

    saleConfig = SaleConfig({
      preSaleStartTime: 1652565600, // Sat May 14 2022 22:00:00 GMT+0000
      publicSaleStartTime: 1652652000, // Sun May 15 2022 22:00:00 GMT+0000
      mintLimit: 50,
      presaleMintPrice: 0.08 ether,
      publicMintPrice: 0.095 ether
    });

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("DragonForge")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  function configureSales(
    uint32 preSaleStartTime,
    uint32 publicSaleStartTime,
    uint32 mintLimit,
    uint64 presaleMintPrice,
    uint64 publicMintPrice
  ) external onlyOwner {
    if (preSaleStartTime == 0) revert InvalidTime();
    if (preSaleStartTime >= publicSaleStartTime) revert InvalidTime();

    saleConfig = SaleConfig({
      preSaleStartTime: preSaleStartTime,
      publicSaleStartTime: publicSaleStartTime,
      mintLimit: mintLimit,
      presaleMintPrice: presaleMintPrice,
      publicMintPrice: publicMintPrice
    });
  }

  function setAllowListSigner(address newSigner) external onlyOwner {
    allowListSigner = newSigner;
  }

  function buyPresale(
    bytes memory signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    if (
      block.timestamp < _saleConfig.preSaleStartTime ||
      block.timestamp > _saleConfig.publicSaleStartTime
    ) revert SaleNotActive();

    if (allowListSigner == address(0)) revert SignerNotSet();

    if (msg.value < (_saleConfig.presaleMintPrice * numberOfTokens))
      revert IncorrectPayment();

    if ((totalMinted[msg.sender] + numberOfTokens) > approvedLimit)
      revert MintLimitExceeded();

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(TYPEHASH, msg.sender, approvedLimit))
      )
    );

    address signer = digest.recover(signature);

    if (signer == address(0) || signer != allowListSigner)
      revert InvalidSignature();

    totalMinted[msg.sender] = totalMinted[msg.sender] + numberOfTokens;

    DragonForgeNFT.mint(msg.sender, numberOfTokens);
  }

  function buy(uint256 numberOfTokens) external payable {
    SaleConfig memory _saleConfig = saleConfig;

    if (block.timestamp < _saleConfig.publicSaleStartTime)
      revert SaleNotActive();

    if ((totalMinted[msg.sender] + numberOfTokens) > _saleConfig.mintLimit)
      revert MintLimitExceeded();

    if (msg.value < (_saleConfig.publicMintPrice * numberOfTokens))
      revert IncorrectPayment();

    totalMinted[msg.sender] = totalMinted[msg.sender] + numberOfTokens;

    DragonForgeNFT.mint(msg.sender, numberOfTokens);
  }

  function withdrawAll() external {
    if (address(this).balance == 0) revert ZeroBalance();

    for (uint256 i = 0; i < _payees.length; i++) {
      release(payable(payee(i)));
    }
  }
}
