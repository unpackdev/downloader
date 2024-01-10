pragma solidity ^0.8.0;
/**
* City Street Strategies
* Written and deployed by Ownerfy Inc. of Ownerfy.com
*
* This contract supports universal royalties standard EIP2981
* Media hash (sha256) / digital fingerprint is written on-chain in the Update event on mint
* Audits and relevant data are added can be added to the update event
* Metadata URIs are IPFS
* This contract is not a proxy. 
* This contract cannot pause end user transfers.
* This contract cannot be rug pulled.
* Original Author N. Juntilla

* Once an NFT URI is locked it cannot be changed.
*/

// Base libraries
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Context.sol";


contract CityStreetStrategies  is Ownable, ERC1155 {

  string public name;

  uint256 private _royaltyBps = 500;
  address payable private _royaltyRecipient;

  bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
  bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

  event Update(string _value, uint256 indexed _id);
  event LockUri(uint256 indexed _id);
  event UpdateRoyalty(address indexed _address, uint256 _bps);

  // CIDs
  mapping (uint256 => string) public cids;

  // Locked URIs
  mapping (uint256 => bool) public lockedUris;

  constructor(string memory _name, string memory _uri) ERC1155(_uri) payable {
    name = _name;
    _royaltyRecipient = payable(msg.sender);
  }

  /**
    * @dev Creates `amount` new tokens for `to`, of token type `id`.
    *
    * See {ERC1155-_mint}.
    *
    * Requirements:
    *
    * - the caller must have the `MINTER_ROLE`.
    */
  function mint(address to, uint256 id, uint256 amount, bytes memory data, string calldata _update, string calldata cid) public virtual onlyOwner{

      if (bytes(_update).length > 0) {
        emit Update(_update, id);
      }

      cids[id] = cid;
      _mint(to, id, amount, data);
  }

  /**
    * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
    */
  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data, string[] calldata updates, string[] calldata _cids) public virtual onlyOwner{

      _mintBatch(to, ids, amounts, data);

      for (uint i = 0; i < ids.length; i++) {
        if (bytes(_cids[i]).length > 0) {
          cids[ids[i]] = _cids[i];
        }
        if (bytes(updates[i]).length > 0) {
          emit Update(updates[i], ids[i]);
        }
      }
  }

  /**
    * @dev Emit Update Event
    * This adds miscellaneous data into the event log about a token
    */
  function emitUpdateEvent(string calldata _update, uint256 id) public virtual onlyOwner {
      emit Update(_update, id);
  }

  /**
    * @dev Update uri
    */
  function updateUri(string calldata _cid, uint256 _id) public virtual onlyOwner {
      require(lockedUris[_id] != true, "Ownerfy: This uri is locked and cannot be altered");
      cids[_id] = _cid;
      emit URI(uri(_id), _id);
  }

  /**
    * @dev Lock uri
    */
  function lockUri(uint256 _id) public virtual onlyOwner {
      lockedUris[_id] = true;
      emit LockUri(_id);
  }

  function uri(uint256 _id) public view virtual override returns (string memory) {
      return string(abi.encodePacked('https://gateway.pinata.cloud/ipfs/', cids[_id]));
  }

  /**
    * @dev Update royalties
    */
  function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
      _royaltyRecipient = recipient;
      _royaltyBps = bps;
      emit UpdateRoyalty(recipient, bps);
  }

  /**
    * ROYALTY FUNCTIONS
    */
  function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
      if (_royaltyRecipient != address(0x0)) {
          recipients = new address payable[](1);
          recipients[0] = _royaltyRecipient;
          bps = new uint256[](1);
          bps[0] = _royaltyBps;
      }
      return (recipients, bps);
  }

  function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
      if (_royaltyRecipient != address(0x0)) {
          recipients = new address payable[](1);
          recipients[0] = _royaltyRecipient;
      }
      return recipients;
  }

  function getFeeBps(uint256) external view returns (uint[] memory bps) {
      if (_royaltyRecipient != address(0x0)) {
          bps = new uint256[](1);
          bps[0] = _royaltyBps;
      }
      return bps;
  }

  function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
      return (_royaltyRecipient, value*_royaltyBps/10000);
  }

  /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE
               || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

}