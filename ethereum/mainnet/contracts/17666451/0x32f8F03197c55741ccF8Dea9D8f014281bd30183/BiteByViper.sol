//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./Viper.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./ERC165.sol";

/*

----------------------------------------------------------------------------------------------------
                                 ⣿⣿⡿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⢿⣿⣿
                                 ⣿⡏⠀⠀⠀⠹⡿⠉⠉⠻⣿⡿⠛⢿⣿⣿⡿⠛⢿⣿⠟⠉⠉⢿⠏⠀⠀⠀⢹⣿
                                 ⣿⡇⠀⠀⠀⢠⣿⠀⠀⢀⣿⡇⠀⠀⣹⣏⠀⠀⢸⣿⡀⠀⠀⣿⡄⠀⠀⠀⢸⣿
                                 ⣿⡇⠀⠀⠀⢸⣿⣧⣤⣿⣿⣷⣀⣴⣿⣿⣦⣀⣾⣿⣿⣤⣼⣿⡇⠀⠀⠀⢸⣿
                                 ⣿⣧⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⣼⣿
                                 ⣿⣿⡄⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⢠⣿⣿
                                 ⣿⣿⣷⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⣾⣿⣿
                                 ⣿⣿⣿⣇⠀⢻⣿⣿⡿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⡟⠀⣸⣿⣿⣿
                                 ⣿⣿⣿⣿⡄⢸⣿⡿⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⢿⣿⡇⢠⣿⣿⣿⣿
                                 ⣿⣿⣿⣿⣿⣼⣿⡇⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⢸⣿⣧⣿⣿⣿⣿⣿
                                 ⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⢻⡿⠻⣿⣿⣿⣿⠟⢿⡟⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿
                                 ⣿⣿⣿⣿⣿⣿⣿⣧⣀⣠⣾⡇⠀⠸⣿⣿⠃⠀⠈⣷⣄⣀⣼⣿⣿⣿⣿⣿⣿⣿
                                 ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣾⣿⣿⣷⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿

                              ▀█████████▄   ▄█      ███        ▄████████
                                ███    ███ ███  ▀█████████▄   ███    ███
                                ███    ███ ███▌    ▀███▀▀██   ███    █▀
                              ▄███▄▄▄██▀  ███▌     ███   ▀  ▄███▄▄▄
                              ▀▀███▀▀▀██▄  ███▌     ███     ▀▀███▀▀▀
                                ███    ██▄ ███      ███       ███    █▄
                                ███    ███ ███      ███       ███    ███
                              ▄█████████▀  █▀      ▄████▀     ██████████

                                        ▀█████████▄  ▄██   ▄
                                          ███    ███ ███   ██▄
                                          ███    ███ ███▄▄▄███
                                        ▄███▄▄▄██▀  ▀▀▀▀▀▀███
                                        ▀▀███▀▀▀██▄  ▄██   ███
                                          ███    ██▄ ███   ███
                                          ███    ███ ███   ███
                                        ▄█████████▀   ▀█████▀

                          ▄█    █▄   ▄█     ▄███████▄    ▄████████    ▄████████
                          ███    ███ ███    ███    ███   ███    ███   ███    ███
                          ███    ███ ███▌   ███    ███   ███    █▀    ███    ███
                          ███    ███ ███▌   ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀
                          ███    ███ ███▌ ▀█████████▀  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀
                          ███    ███ ███    ███          ███    █▄  ▀███████████
                          ███    ███ ███    ███          ███    ███   ███    ███
                          ▀██████▀  █▀    ▄████▀        ██████████   ███    ███
                                                                      ███    ███
----------------------------------------------------------------------------------------------------
  
By Billy Rennekamp and Joon Yeon Park
Presented by Folia.app                  
*/

/// @title Bite by Viper
/// @notice https://viper.folia.app
/// @author @okwme
/// @dev Soulbound NFTs that are the result of Viper bites.

contract BiteByViper is Ownable, IERC721, IERC721Metadata, ERC165 {
  address public viperAddress;
  address public metadata;
  uint256 public totalSupply;
  mapping(address => uint256) private _bites;
  mapping(uint256 => address) private _owners;

  constructor(address viperAddress_, address metadata_) {
    viperAddress = viperAddress_;
    metadata = metadata_;
  }

  /// @dev only the owner can update the address of the viper contract
  /// @param viperAddress_ the address of the viper contract
  function updateViperAddress(address viperAddress_) public onlyOwner {
    viperAddress = viperAddress_;
  }

  /// @dev only the owner can update the address of the metadata contract
  /// @param metadata_ the address of the metadata contract
  function updateMetadataAddress(address metadata_) public onlyOwner {
    metadata = metadata_;
  }

  /// @dev Only the viper contract can trigger the bite method
  /// @param from the address of the person who is biting
  /// @param to the address of the person who is being bitten
  /// @param tokenId the tokenId of the viper token that is biting
  /// @param length the length of the viper token that is biting
  function bite(address from, address to, uint256 tokenId, uint256 length) public {
    require(msg.sender == viperAddress, "ONLY VIPER");
    uint256 lastTokenId = getCombinedTokenId(from, tokenId, length - 1);
    require(_owners[lastTokenId] != to, "YOU JUST BIT THEM");
    uint256 newTokenId = getCombinedTokenId(from, tokenId, length);
    _bites[to]++;
    _owners[newTokenId] = to;
    totalSupply++;
    emit Transfer(from, to, newTokenId);
  }

  /// @dev returns the tokenId of the BiteByViper NFT as composed of pieces of encoded Viper information
  /// @param from the address of the person who is biting
  /// @param tokenId the tokenId of the viper token that is biting
  /// @param length the length of the viper token that is biting
  /// @return combinedTokenId the tokenId of the BiteByViper NFT
  function getCombinedTokenId(
    address from,
    uint256 tokenId,
    uint256 length
  ) public pure returns (uint256 combinedTokenId) {
    // combinedTokenId should be a combo of the recipients address and the tokenId from the sender
    // the combinedTokenId can store 256 bits
    // the address is 160 bits long
    // the next 9 bits is for the viper tokenId (max 512)
    // the tokenId should be bitshifted 160 bits then combined using the bitwise 'or' operation with the address of the recipient
    // [0-96 bits] [97-256 bits]
    uint256 bitShiftedTokenId = tokenId << 160;
    uint256 addressAndTokenId = bitShiftedTokenId | uint256(uint160(from));
    // we could get the tokenId back like this:
    // uint256 tokenId = combinedNumber >> 160

    // we only need 9 bits to represent all 486 viper tokens (2^9 = 512)
    // so all in all it looks like this:
    //  [0-86] = length (87), [87-96] = tokenId (9), [97-256] = address (160)
    uint256 bitShiftedLength = length << 169;
    combinedTokenId = bitShiftedLength | addressAndTokenId;
    return combinedTokenId;
  }

  /// @dev returns the length of the viper token that is biting
  /// @param combinedtokenId the tokenId of the BiteByViper NFT
  /// @return length the length of the viper token that is biting
  function extractLength(uint256 combinedtokenId) public pure returns (uint256 length) {
    length = (combinedtokenId >> 169);
  }

  /// @dev returns the tokenId of the viper token that is biting
  /// @param combinedTokenId the tokenId of the BiteByViper NFT
  /// @return tokenId the tokenId of the viper token that is biting
  function extractTokenId(uint256 combinedTokenId) public pure returns (uint256 tokenId) {
    // uint256 blocker is a 9 bit long value
    uint256 blocker = uint256(0x1FF);
    tokenId = (combinedTokenId >> 160) & blocker;
  }

  /// @dev returns the address of the person who has bitten
  /// @param tokenId the tokenId of the BiteByViper NFT
  /// @return ownerOfToken the address of the person who has bitten
  function extractAddress(uint256 tokenId) public pure returns (address ownerOfToken) {
    uint256 blocker = uint256(uint160(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
    ownerOfToken = address(uint160(tokenId & blocker));
  }

  /// @dev overwrites the tokenURI function from ERC721
  /// @param id the id of the NFT
  /// @return _ the URI of the NFT
  function tokenURI(uint256 id) public view override(IERC721Metadata) returns (string memory) {
    return Metadata(metadata).getMetadata(id);
  }

  /// @dev overwrites the name function from ERC721Metadata
  /// @return _ the name of the NFT
  function name() external pure override(IERC721Metadata) returns (string memory) {
    return "BiteByViper";
  }

  /// @dev overwrites the symbol function from ERC721Metadata
  /// @return _ the symbol of the NFT
  function symbol() external pure override(IERC721Metadata) returns (string memory) {
    return "BBVPR";
  }

  /// @dev overwrites the balanceOf function from ERC721
  /// @param owner the address of the owner
  /// @return _ the balance of the owner
  function balanceOf(address owner) external view override(IERC721) returns (uint256) {
    return _bites[owner];
  }

  /// @dev overwrites the ownerOf function from ERC721
  /// @param tokenId the tokenId of the NFT
  /// @return _ the address of the owner
  function ownerOf(uint256 tokenId) external view override(IERC721) returns (address) {
    return _owners[tokenId];
  }

  function getApproved(uint256) external view override(IERC721) returns (address) {}

  function isApprovedForAll(address, address) external view override(IERC721) returns (bool) {}

  function transferFrom(address, address, uint256) public pure override(IERC721) {
    revert("VIPER BITES CAN'T BE CURED");
  }

  function safeTransferFrom(address, address, uint256) external pure override(IERC721) {
    revert("VIPER BITES CAN'T BE CURED");
  }

  function safeTransferFrom(address, address, uint256, bytes calldata) external pure override(IERC721) {
    revert("VIPER BITES CAN'T BE CURED");
  }

  function approve(address, uint256) external pure override(IERC721) {
    revert("VIPER BITES CAN'T BE CURED");
  }

  function setApprovalForAll(address, bool) external pure override(IERC721) {
    revert("VIPER BITES CAN'T BE CURED");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }
}
