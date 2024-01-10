// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ContextUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";

import "./ICryptoPunks.sol";
import "./IWrappedPunks.sol";
import "./IBNFT.sol";
import "./IBNFTRegistry.sol";

contract BoundPunkGateway is ContextUpgradeable, ReentrancyGuardUpgradeable, ERC721HolderUpgradeable {
  ICryptoPunks public punks;
  IWrappedPunks public wrappedPunks;
  address public proxy;
  IBNFTRegistry public bnftRegistry;
  IBNFT public bnftWPunks;

  function initialize(
    address _punks,
    address _wrappedPunks,
    address _bnftRegistry
  ) public initializer {
    __Context_init();
    __ReentrancyGuard_init();

    punks = ICryptoPunks(_punks);
    wrappedPunks = IWrappedPunks(_wrappedPunks);
    wrappedPunks.registerProxy();
    proxy = wrappedPunks.proxyInfo(address(this));

    bnftRegistry = IBNFTRegistry(_bnftRegistry);

    (address bnftProxy, ) = bnftRegistry.getBNFTAddresses(address(wrappedPunks));
    require(bnftProxy != address(0), "WPG: bnftWPunks not exist");
    bnftWPunks = IBNFT(bnftProxy);

    wrappedPunks.setApprovalForAll(bnftProxy, true);
  }

  function depositPunk(uint256 punkIndex) public nonReentrant {
    // check caller is orginal CryptoPunks owner
    address punkOwner = punks.punkIndexToAddress(punkIndex);
    require(punkOwner == _msgSender(), "WPG: caller is not owner in Punks");

    // CryptoPunks owner using offerPunkForSaleToAddress to this gateway
    punks.buyPunk(punkIndex);
    punks.transferPunk(proxy, punkIndex);

    // mint WPunks
    wrappedPunks.mint(punkIndex);

    // mint boundWPunks
    bnftWPunks.mint(punkOwner, punkIndex);

    // check boundWPunks owner is caller
    address bnftOwner = IERC721Upgradeable(address(bnftWPunks)).ownerOf(punkIndex);
    require(punkOwner == bnftOwner, "WPG: caller is not owner in bnftWPunks");
  }

  function withdrawPunk(uint256 punkIndex) public nonReentrant {
    // check caller is boundWPUNKS owner
    address bnftOwner = IERC721Upgradeable(address(bnftWPunks)).ownerOf(punkIndex);
    require(bnftOwner == _msgSender(), "WPG: caller is not owner in bnftWPunks");

    // burn boundWPunks
    bnftWPunks.burn(punkIndex);

    // burn WPunks got CryptoPunks
    wrappedPunks.burn(punkIndex);

    // transfer CryptoPunks to caller
    punks.transferPunk(bnftOwner, punkIndex);
    address punkOwner = punks.punkIndexToAddress(punkIndex);
    require(punkOwner == _msgSender(), "WPG: caller is not owner in Punks");
  }
}
