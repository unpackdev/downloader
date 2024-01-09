// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract PRNFT is ERC1155Supply, Ownable {

  address public adminSigner;
  bool public metadataLocked;
  uint256 public lastFrozenMetadataTokenId;
  string public frozenMetadataUri;

  constructor(address _adminSigner)
    ERC1155("https://app.partyround.com/api/award-metadata/{id}.json")
  {
    adminSigner = _adminSigner;
  }

  /**
     * @dev Update the uri template

     * Params:
     * _uri: the new uri template
     */
  function setURI(string memory _uri) external onlyOwner {
    require(metadataLocked != true, "metadata uri is locked");
    _setURI(_uri);
  }

  /**
     * @dev Lock in the current token URI template
     */
  function lockURI() external onlyOwner {
    require(metadataLocked != true, "metadata uri is already locked");
    metadataLocked = true;
  }

  /**
     * @dev Update frozen metadata URI and checkpoint

     * Params:
     * _uri: the new frozen metadata uri
     * _lastFrozenMetadataTokenId: the new checkpoint position before which everything should be "frozen" in the ipfs file
     */
  function updateFrozenMetadataCheckpoint(string memory _uri, uint256 _lastFrozenMetadataTokenId) external onlyOwner {
    require(metadataLocked != true, "metadata uri is locked");
    frozenMetadataUri = _uri;
    lastFrozenMetadataTokenId = _lastFrozenMetadataTokenId;
  }

  /**
     * @dev Update the adminSigner (address which signatures are expected to come from)

     * Params:
     * _adminSigner: the new address
     */
  function setAdminSigner(address _adminSigner) external onlyOwner {
    adminSigner = _adminSigner;
  }

  /**
     * @dev Overrides the base logic to support our frozen metadata strategy

     * Params:
     * _id: the token id
     */
  function uri(uint256 _id) view override public returns (string memory) {
    if (_id <= lastFrozenMetadataTokenId) {
      return frozenMetadataUri;
    }
    return super.uri(_id);
  }

  /**
     * @dev Given the signature and apparent inputs, returns the signer address

     * Params:
     * _addr: the address apparently encoded in the signature
     * _id: the token id apparently encoded in the signature
     * _sig: the signature
     */
  function _recoverSigner(address _addr, uint256 _tokenId, bytes memory _sig) private pure returns (address) {
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 dataHash = keccak256(abi.encode(_addr, _tokenId));
    bytes32 fullHash = keccak256(abi.encodePacked(prefix, dataHash));
    return ECDSA.recover(fullHash, _sig);
  }

  /**
     * @dev The mint function

     * Params:
     * _tokenId: the token id apparently encoded in the signature
     * _sig: the signature
     */
  function mint(uint256 _tokenId, bytes memory _sig) external {
    require(_tokenId != 0, "0 not allowed");
    require(!exists(_tokenId), "already minted");
    require(_recoverSigner(msg.sender, _tokenId, _sig) == adminSigner, "invalid signature");
    _mint(msg.sender, _tokenId, 1, "");
  }

  /**
     * @dev The dev mint function (mints a batch to individual users)

     * Params:
     * _addresses: the addresses to send the tokens to
     * _tokenIds: the token ids to be minted
     * _amounts: the supply of each token to mint
     */
  function devMint(address[] memory _addresses, uint256[] memory _tokenIds, uint256[] memory _amounts) external {
    require(msg.sender == adminSigner, "not adminSigner");
    for (uint i = 0; i < _tokenIds.length; i++) {
      require(_tokenIds[i] != 0, "0 not allowed");
      require(!exists(_tokenIds[i]), "already minted");
      _mint(_addresses[i], _tokenIds[i], _amounts[i], "");
    }
  }

}
