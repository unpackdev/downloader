pragma solidity ^0.8.0;
/**
* This contract was deployed by Ownerfy Inc. of Ownerfy.com
*
* This contract is not a proxy. 
* This contract is not pausable.
* This contract is not lockable.
* This contract cannot be rug pulled.
* The URIs are not changeable after mint. 
* Only the private key holders of individual NFTs and those they have granted 
* access to may change the ownership rights of NFTs on this contract.
*/

// From base: 
// https://docs.openzeppelin.com/contracts/4.x/erc1155
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";


contract OwnerfyContract3 is Context, AccessControlEnumerable, ERC1155Burnable {

  string public constant name = 'Ownerfy';
  string public constant symbol = 'OWNERFY';
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

  event Update(string _value, uint256 indexed _id);

  // CIDs
    mapping (uint256 => string) public cids;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `AUDITOR_ROL` to the account that
     * deploys the contract.
     */
    constructor(string memory _uri) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(AUDITOR_ROLE, _msgSender());
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
    function mint(address to, uint256 id, uint256 amount, bytes memory data, string calldata _update, string calldata cid) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Ownerfy: must have minter role to mint");

        if (bytes(_update).length > 0) {
          emit Update(_update, id);
        }

        cids[id] = cid;

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data, string[] calldata updates, string[] calldata _cids) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Ownerfy: must have minter role to mint");

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

    function update(string calldata _update, uint256 id) public virtual {
        require(hasRole(AUDITOR_ROLE, _msgSender()), "Ownerfy ERC1155: must have auditor role to update");
        emit Update(_update, id);
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked('https://gateway.pinata.cloud/ipfs/', cids[_id]));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}