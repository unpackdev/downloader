// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";

/// @title Forever Punks Vol.1
/// @author Layerr
/// @author Gui "Qruz" Rodrigues
/// @notice REDLION Contract aimed to mint an ERC721 token to each allowed Punk, all tokens will be linked to a pysical book delivered to the minter of the token
/// @custom:security-contact hello@redlion.news

contract ForeverPunks is
  ERC721,
  ERC721URIStorage,
  Pausable,
  Ownable
{
  /*///////////////////////////////////////////////////////////////
                                VARIABLES
  ///////////////////////////////////////////////////////////////*/

  /// @notice Maximum contract supply
  uint128 public MAX_SUPPLY = 50;


  uint128 public totalSupply = 0;

  /// @notice The address used to sign the allow list parameters
  address public SIGNER = 0x2A112c1Bfb7612a58A8ccEd7210a34b36946Db78;

  mapping(uint => string) public bookText;

  uint256 public PRICE = 0.6 ether;
  

  using Strings for uint256;
  using ECDSA for bytes32;

  /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  ///////////////////////////////////////////////////////////////*/

  constructor() ERC721('Forever Punks', 'FP') {
    _transferOwnership(tx.origin);
  }

  /*///////////////////////////////////////////////////////////////
                              UTILITY
  ///////////////////////////////////////////////////////////////*/

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function validSignature(
    bytes memory signature,
    bytes32 msgHash
  ) public view returns (bool) {
    return msgHash.toEthSignedMessageHash().recover(signature) == SIGNER;
  }

  /*///////////////////////////////////////////////////////////////
                              MINTING
  ///////////////////////////////////////////////////////////////*/

  /// @notice Minting function
  /// @dev The params must be signed with the SIGNER address in order to be valid
  /// @param tokenId the token ID to be minted, this should be the same as the Punk ID the address owns
  /// @param text the unique immutable text stored on chain representative of the Punk signature
  /// @param signature the signature hash of the combined parameters (address, tokenId, text)
  function mint(
    uint256 tokenId,
    string memory text,
    string memory uri,
    bytes memory signature
  ) public payable whenNotPaused {
    require(MAX_SUPPLY > totalSupply, 'MAX_SUPPLY_REACHED');
    require(msg.value == PRICE, 'WRONG_MINTING_PRICE');
    require(!_exists(tokenId), 'ALREADY_MINTED');
    totalSupply ++;
    // Validate signature
    bytes32 inputHash = keccak256(
      abi.encodePacked(msg.sender, tokenId, text, uri)
    );
    require(validSignature(signature, inputHash), 'BAD_SIGNATURE');

    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, uri);
    bookText[tokenId] = text;

  }

  /*///////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
  ///////////////////////////////////////////////////////////////*/

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /// @notice Lock minting function by limiting the max supply to the current supply
  function lockMinting() public onlyOwner {
    MAX_SUPPLY = totalSupply;
  }

  function setMaxSupply(uint128 _newMaxSupply) public onlyOwner {
    require(_newMaxSupply > totalSupply, "INVALID_SUPPLY");
    MAX_SUPPLY = _newMaxSupply;
  }

  /*///////////////////////////////////////////////////////////////
                              SETTERS
  ///////////////////////////////////////////////////////////////*/

  /// @notice Sets the minting price
  /// @dev Only the contract owner is allowed to use this function
  /// @param _price the new price in wei
  function setPrice(uint256 _price) public onlyOwner {
    PRICE = _price;
  }

  /// @notice Sets the new signer address
  /// @dev this function is used when the current signer address has been compromised or access lost
  /// @param _address the new signer address
  function setSigner(address _address) public onlyOwner {
    SIGNER = _address;
  }

  /// @notice Change the current token uri
  /// @dev This is only used when a wrong token metadata was initally set
  /// @param _tokenId the target tokenId
  /// @param _tokenURI the new token uri
  function modifyTokenURI(
    uint256 _tokenId,
    string memory _tokenURI
  ) public onlyOwner {
    _setTokenURI(_tokenId, _tokenURI);
  }

  /*///////////////////////////////////////////////////////////////
                                MISC
  ///////////////////////////////////////////////////////////////*/

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
