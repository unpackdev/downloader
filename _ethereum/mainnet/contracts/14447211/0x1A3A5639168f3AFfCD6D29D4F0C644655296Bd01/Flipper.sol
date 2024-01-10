// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC1155.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC1155Pausable.sol";
import "./IERC2981.sol";

contract OpenseaOwnableDelegateProxy {}

contract OpenseaProxyRegistry {
  mapping(address => OpenseaOwnableDelegateProxy) public proxies;
}

/**
 * @title Flipper 2022
 * Flipper - 2022 Access Pass
 * Owning this token will give you access to flipper.zone on 2022.
 */
contract Flipper is ERC1155Pausable, IERC2981, Ownable {
  string public constant name = "Flipper Zone Access Pass 2022";
  string public constant symbol = "FLIPPER22";
  uint256 public constant ACCESS_PASS_TOKEN_ID = 0;
  uint256 private immutable alphaAccessMembershipTokenId;
  uint256 private immutable alphaOGAccessMembershipTokenId;
  uint256 internal _mintCounter;
  IERC20 private immutable Bank;
  IERC20 private immutable BankUniswapV2Pair;
  IERC20 private immutable BankBalancerPool;
  IERC1155 private immutable OpenseaSharedStorefront;
  OpenseaProxyRegistry private immutable openseaProxyRegistry;
  bool public public_sale_active = false;
  bool public bankless_presale_active = false;
  bool public general_presale_active = false;
  string public contractURI;
  address private immutable royaltyFeeRecipient;

  constructor(
    string memory _tokenURI,
    string memory _contractURI,
    address _bankAddress,
    address _bankUniswapV2PairAddress,
    address _bankBalancerPoolAddress,
    address _openseaSharedStorefrontAddress,
    address _openseaProxyRegistryAddress,
    address _royaltyFeeRecipient,
    uint256 _alphaAccessMembershipTokenId,
    uint256 _alphaOGAccessMembershipTokenId
  ) ERC1155(_tokenURI) {
    contractURI = _contractURI;
    Bank = IERC20(_bankAddress);
    BankUniswapV2Pair = IERC20(_bankUniswapV2PairAddress);
    BankBalancerPool = IERC20(_bankBalancerPoolAddress);
    OpenseaSharedStorefront = IERC1155(_openseaSharedStorefrontAddress);
    alphaAccessMembershipTokenId = _alphaAccessMembershipTokenId;
    alphaOGAccessMembershipTokenId = _alphaOGAccessMembershipTokenId;
    openseaProxyRegistry = OpenseaProxyRegistry(_openseaProxyRegistryAddress);
    royaltyFeeRecipient = _royaltyFeeRecipient;
  }

  struct WhitelistStatus {
    bool isExplicitlyWhitelisted;
    bool isWhitelistedByBankBalance;
    bool isWhitelistedByAlphaAccessMembership;
  }

  struct MintStatus {
    uint256 totalSupply;
    uint256 currentPrice;
    bool isBanklessPresaleActive;
    bool isGeneralPresaleActive;
    bool isPublicSaleActive;
    bool isPaused;
  }

  modifier eoaOnly() {
    require(msg.sender == tx.origin, "Can only be called by EOAs");
    _;
  }

  function setTokenURI(string memory _tokenURI) public onlyOwner {
    _setURI(_tokenURI);
  }

  function setContractURI(string memory _contractURI) public onlyOwner {
    contractURI = _contractURI;
  }

  function mint() external payable whenNotPaused eoaOnly {
    require(canMint(msg.sender), "Sale is not active or wallet is not whitelisted");
    require(_mintCounter < 500, "All 500 passes were already minted");
    if (bankless_presale_active && !public_sale_active && !general_presale_active) {
      require(_mintCounter < 300, "All 300 Bankless presale passes were already minted");
    }
    require(msg.value == currentPrice(), "Amount of ether sent does not match current price");
    unchecked {
      _mintCounter += 1;
    }
    _mint(msg.sender, ACCESS_PASS_TOKEN_ID, 1, "");
  }

  function totalSupply() public view returns (uint256) {
    return _mintCounter;
  }

  function canMint(address _toCheck) public view returns (bool) {
    if (public_sale_active) {
      return true;
    }

    if (bankless_presale_active && isWhitelistedByBankBalance(_toCheck)) {
      return true;
    }

    if (
      general_presale_active && (isWhitelistedByAlphaAccessMembership(_toCheck) || isExplicitlyWhitelisted(_toCheck))
    ) {
      return true;
    }

    return false;
  }

  /// @notice Only the discord geveaway winners were explicitly whitelisted
  function isExplicitlyWhitelisted(address _toCheck) public pure returns (bool) {
    if (_toCheck == 0x026c2760ba6852cc188F7Be6D62ee1d663Ec9bdb) {
      return true;
    }
    if (_toCheck == 0x1A589c87d396254aE9fc07A5defB920B1039bd36) {
      return true;
    }
    if (_toCheck == 0xe766b33876CdBb918F06f5f4380deEE435EA8596) {
      return true;
    }
    if (_toCheck == 0x3B666dbC539d25DFF4ec62357a3C13258528DfBe) {
      return true;
    }
    if (_toCheck == 0x051D85190dBacd14D705426C86Ca440B004deEb4) {
      return true;
    }
    if (_toCheck == 0xC6F08690C67D20AA2D9E952e57478fE6606c85fe) {
      return true;
    }
    if (_toCheck == 0x46B866329b762a2e1791D1cb4E0407D3E2B98983) {
      return true;
    }
    if (_toCheck == 0x0D289031af6b6299bC6B9174F3A1583079fd6e56) {
      return true;
    }
    if (_toCheck == 0x8DcD8b9E43fbCFC807BA0a52D48937862454c03d) {
      return true;
    }
    if (_toCheck == 0x575A979789520C5B6E70feC4De4a355f8F6956C5) {
      return true;
    }
    if (_toCheck == 0x870f7aF906DdEf083cf257c0D252825773b06bD9) {
      return true;
    }
    if (_toCheck == 0xece358648A41801577f70C80e4cd8654f9726066) {
      return true;
    }
    if (_toCheck == 0xd8d128ad7d2c3Ac50A009AA453781D466D76adc3) {
      return true;
    }
    if (_toCheck == 0xa24b43113CD757223517e53A6Fe8A0B5462873eA) {
      return true;
    }
    if (_toCheck == 0x1bca9771DcD5709B405804d6d0c314b49370C1A3) {
      return true;
    }
    if (_toCheck == 0x5B5d89Fa961B503EcdB1C7dBC30F88C566f3865A) {
      return true;
    }
    if (_toCheck == 0x4f4861a604c1b6DbDcd693a82F8e3A581f2B62E7) {
      return true;
    }
    if (_toCheck == 0x7AF4f4d7B0028851C6Deebe95cf296B1A4C491e9) {
      return true;
    }
    if (_toCheck == 0x4cD38718522ef9f7d1ebFd1A7b642a436241C458) {
      return true;
    }
    if (_toCheck == 0x3E69ea72edc970f99676d8150698681CA7673bb2) {
      return true;
    }
    if (_toCheck == 0xbd721a0a38F3898Cfdf66c76B27fBa160b5da204) {
      return true;
    }
    if (_toCheck == 0xe0A8A4D427Eef7Bb1BA257323e2Fcf42D5C558Cf) {
      return true;
    }
    if (_toCheck == 0x9474b2d7278414cb33F624f69800Db96Ab51Eb8D) {
      return true;
    }
    if (_toCheck == 0xC9eB1555B2810D5731c4Ef3eAf089894f81226Cb) {
      return true;
    }
    if (_toCheck == 0x7373CF1e3527274bBdA97095F2D50cf2c6778c5a) {
      return true;
    }
    if (_toCheck == 0x9B9B0811BB1277bc7881dA97085203b7DDfee85E) {
      return true;
    }
    if (_toCheck == 0x6C3F672D8beEFC1d052D43326adee4C40580dFc5) {
      return true;
    }
    if (_toCheck == 0x76d9957E9F91E330F66ac4C0ed23A470dc04336F) {
      return true;
    }
    if (_toCheck == 0x91a9B4DA163a1F248C92DBd262aD3e95e042C87E) {
      return true;
    }
    if (_toCheck == 0x91BEF3247BEEf67F068d757e97d527caE3798Ee6) {
      return true;
    }
    if (_toCheck == 0x20bf082A4040649Ab641Fd3B470aD00a3cE1a935) {
      return true;
    }
    if (_toCheck == 0xbEd4ce28E0FF95204A9cc0A4FF10Ff201F656A2E) {
      return true;
    }
    if (_toCheck == 0x171C1CF42C8e11589381f5E4846FFE4E2c7f6D95) {
      return true;
    }
    if (_toCheck == 0xf5eabB96508760a10d72c6beB995B8297B48DED4) {
      return true;
    }
    if (_toCheck == 0x2d50aE0ad5b79c861B8caD5982bDcDF66376aC4b) {
      return true;
    }
    if (_toCheck == 0xfF5244420A64CD43B50AB9aA9f240a618f3d3eCa) {
      return true;
    }
    if (_toCheck == 0xBE6F5437C3C73FA238628Fb5dA61A1A07ea0E8f5) {
      return true;
    }
    if (_toCheck == 0xE7e0657036d77a87Dd9ab39b509e1500bdDf7B1A) {
      return true;
    }
    if (_toCheck == 0xaf2536Ca649f40FE69737BB37Faf20dfA1616dDc) {
      return true;
    }
    if (_toCheck == 0x4c08AcbAc5bd7269D0236f40F82CA14C55f82fD7) {
      return true;
    }
    if (_toCheck == 0xbEd4ce28E0FF95204A9cc0A4FF10Ff201F656A2E) {
      return true;
    }
    if (_toCheck == 0x44b246Aa370c6eb3df78943Ccb586c99067960A0) {
      return true;
    }
    if (_toCheck == 0x7d13B39Ec86E1669f69Ea49dCe1299eCDa589F22) {
      return true;
    }
    if (_toCheck == 0xf5eabB96508760a10d72c6beB995B8297B48DED4) {
      return true;
    }
    if (_toCheck == 0x17186C6062D49e8377e480e55560167A18baE3CB) {
      return true;
    }
    if (_toCheck == 0x88DE3dfB4b5D2990d014c525A43CbD38864c9d50) {
      return true;
    }
    if (_toCheck == 0x4D45C560439C3E3eDF0c8abC93eC9E041F1101f3) {
      return true;
    }
    return false;
  }

  function isWhitelistedByBankBalance(address _toCheck) public view returns (bool) {
    if (Bank.balanceOf(_toCheck) >= 35_000e18) {
      return true;
    }

    if (BankUniswapV2Pair.balanceOf(_toCheck) >= 250e18) {
      return true;
    }

    if (BankBalancerPool.balanceOf(_toCheck) >= 4_200e18) {
      return true;
    }

    return false;
  }

  function isWhitelistedByAlphaAccessMembership(address _toCheck) public view returns (bool) {
    if (OpenseaSharedStorefront.balanceOf(_toCheck, alphaAccessMembershipTokenId) > 0) {
      return true;
    }

    if (OpenseaSharedStorefront.balanceOf(_toCheck, alphaOGAccessMembershipTokenId) > 0) {
      return true;
    }

    return false;
  }

  function currentPrice() public view returns (uint256) {
    return 0.1 ether * (1 + (_mintCounter / 100));
  }

  function activatePublicSale() public onlyOwner {
    public_sale_active = true;
  }

  function deactivatePublicSale() public onlyOwner {
    public_sale_active = false;
  }

  function activateBanklessPresale() public onlyOwner {
    bankless_presale_active = true;
  }

  function deactivateBanklessPresale() public onlyOwner {
    bankless_presale_active = false;
  }

  function activateGeneralPresale() public onlyOwner {
    general_presale_active = true;
  }

  function deactivateGeneralPresale() public onlyOwner {
    general_presale_active = false;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "Balance is 0");
    payable(msg.sender).transfer(balance);
  }

  function pause() public onlyOwner whenNotPaused {
    _pause();
  }

  function unpause() public onlyOwner whenPaused {
    _unpause();
  }

  // Implements ERC-2981
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    return (royaltyFeeRecipient, (_salePrice * 10) / 100);
  }

  // Register support for ERC-2981
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
    if (address(openseaProxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

  function mintStatus() public view returns (MintStatus memory) {
    return
      MintStatus({
        totalSupply: totalSupply(),
        currentPrice: currentPrice(),
        isBanklessPresaleActive: bankless_presale_active,
        isGeneralPresaleActive: general_presale_active,
        isPublicSaleActive: public_sale_active,
        isPaused: paused()
      });
  }

  function whitelistStatus(address _toCheck) public view returns (WhitelistStatus memory) {
    return
      WhitelistStatus({
        isExplicitlyWhitelisted: isExplicitlyWhitelisted(_toCheck),
        isWhitelistedByBankBalance: isWhitelistedByBankBalance(_toCheck),
        isWhitelistedByAlphaAccessMembership: isWhitelistedByAlphaAccessMembership(_toCheck)
      });
  }
}
