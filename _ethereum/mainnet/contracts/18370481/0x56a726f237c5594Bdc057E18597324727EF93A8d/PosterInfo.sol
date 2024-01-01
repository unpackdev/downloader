// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRoleAuthority.sol";

import "./IPosterInfo.sol";

/**
 * @title PosterInfo contract.
 * @notice The contract handles Deca Posters hash.
 * @author j6i, 0x-jj
 */
contract PosterInfo is IPosterInfo {
  /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice The address of the RoleAuthority used to determine whether an address has some admin role.
   */
  IRoleAuthority private immutable _roleAuthority;

  /**
   * @notice Is the poster hash used.
   */
  mapping(bytes32 => bool) public isPosterHashUsed;

  /**
   * @notice Poster tokenId to expiry timestamp.
   */
  mapping(uint256 => uint256) public posterExpiryTimestamp;

  /**
   * @notice Poster tokenId to whether the owner has claimed their free mint.
   */
  mapping(uint256 => bool) public ownerMinted;

  /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

  constructor(IRoleAuthority _roleAuthority_) {
    _roleAuthority = _roleAuthority_;
  }

  /*//////////////////////////////////////////////////////////////
                              EXTERNAL
    //////////////////////////////////////////////////////////////*/

  /**
   * @notice Check whether a poster can be minted.
   * @param tokenId The tokenId of the poster.
   * @return Whether a poster can be minted.
   */
  function isMintActive(uint256 tokenId) external view returns (bool) {
    return block.timestamp < posterExpiryTimestamp[tokenId];
  }

  /**
   * @notice Set the poster info.
   * @param _mintHash The mint hash of the poster.
   * @param _tokenId The tokenId of the poster.
   * @param _ownerMint Whether the owner is minting.
   * @param _mintEndsAt When the mint ends.
   */
  function setPosterInfoWithMintPeriod(
    bytes32 _mintHash,
    uint256 _tokenId,
    bool _ownerMint,
    uint256 _mintEndsAt
  ) external {
    if (!_roleAuthority.isPosterMinter(msg.sender)) revert NotPosterMinter();
    if (_ownerMint) {
      if (ownerMinted[_tokenId]) revert OwnerAlreadyMinted();

      ownerMinted[_tokenId] = true;
    }
    if (posterExpiryTimestamp[_tokenId] == 0) {
      posterExpiryTimestamp[_tokenId] = _mintEndsAt;
      emit FirstPosterMinted(_tokenId, _mintEndsAt);
    }
    isPosterHashUsed[_mintHash] = true;
  }

  /**
   * @notice Set the poster info.
   * @param _mintHash The mint hash of the poster.
   * @param _tokenId The tokenId of the poster.
   * @param _ownerMint Whether the owner is minting.
   */
  function setPosterInfo(bytes32 _mintHash, uint256 _tokenId, bool _ownerMint) external {
    if (!_roleAuthority.isPosterMinter(msg.sender)) revert NotPosterMinter();
    if (_ownerMint) {
      if (ownerMinted[_tokenId]) revert OwnerAlreadyMinted();

      ownerMinted[_tokenId] = true;
    }
    isPosterHashUsed[_mintHash] = true;
  }
}
