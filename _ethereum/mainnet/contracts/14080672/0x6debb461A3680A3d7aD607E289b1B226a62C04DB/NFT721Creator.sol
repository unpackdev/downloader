// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
abstract contract NFT721Creator is ERC721 {
  mapping(uint256 => address payable) private tokenIdToCreator;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);

  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );

  /*
   * bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR = 0x40c1a064;

  /*
   * bytes4(keccak256('getTokenCreatorPaymentAddress(uint256)')) == 0xec5f752e;
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS = 0xec5f752e;

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeNFT721Creator() internal initializer {
    _registerInterface(_INTERFACE_TOKEN_CREATOR);
  }

  /**
   * @notice Allows ERC165 interfaces which were not included originally to be registered.
   * @dev Currently this is the only new interface, but later other mixins can overload this function to do the same.
   */
  function registerInterfaces() public {
    _registerInterface(_INTERFACE_TOKEN_CREATOR_PAYMENT_ADDRESS);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   */
  function tokenCreator(uint256 tokenId) public view returns (address payable) {
    return tokenIdToCreator[tokenId];
  }

  /**
   * @notice Returns the payment address for a given tokenId.
   * @dev If an alternate address was not defined, the creator is returned instead.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = tokenIdToCreator[tokenId];
    }
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   * This is immutable since it's only exposed publicly when minting a new NFT.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    if (tokenCreatorPaymentAddress != address(0)) {
      tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
      emit TokenCreatorPaymentAddressSet(address(0), tokenCreatorPaymentAddress, tokenId);
    }
  }
  
  /**
   * @dev Remove the creator record when burned.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete tokenIdToCreator[tokenId];

    super._burn(tokenId);
  }

  uint256[999] private ______gap;
}