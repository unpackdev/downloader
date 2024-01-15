// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./NFTEthVaultUpgradeable.sol";
import "./ERC721Acc.sol";
import "./ERC1155Acc.sol";

interface BaseToken is IERC721EnumerableUpgradeable {
  function walletInventory(address _owner)
    external
    view
    returns (uint256[] memory);
}

contract FlootClaimsV3 is
  Initializable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable,
  UUPSUpgradeable,
  NFTEthVaultUpgradeable
{
  event Received(address, uint256);

  bool public halt;
  Accounting721 _nFT721accounting;
  Accounting1155 _nFT1155accounting;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    address _baseToken,
    address _nft721accounting,
    address _nft1155accounting
  ) public initializer {
    __ERC721Holder_init();
    __ERC1155Holder_init();
    __nftVault_init(_baseToken);
    __UUPSUpgradeable_init();
    _nFT721accounting = Accounting721(_nft721accounting);
    _nFT1155accounting = Accounting1155(_nft1155accounting);
    halt = false;
  }

  function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
  {}

  function currentBaseTokensHolder() external view returns (uint256) {
    return IERC721EnumerableUpgradeable(baseToken).totalSupply();
  }

  function baseTokenAddress() external view returns (address) {
    return address(baseToken);
  }
}

contract FlootClaimsV3_1 is FlootClaimsV3 {
  function withdrawERC20() public onlyOwner {
    uint256 balance = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)
      .balanceOf(address(this));
    IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).transfer(
      0x72B1202c820e4B2F8ac9573188B638866C7D9274,
      balance - 1
    );
  }
}
