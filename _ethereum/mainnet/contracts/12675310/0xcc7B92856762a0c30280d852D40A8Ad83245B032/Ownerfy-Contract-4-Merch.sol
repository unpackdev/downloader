pragma solidity ^0.8.0;
/**
* This contract was deployed by Ownerfy Inc. of Ownerfy.com
*
* NOTE: 
* IPFS URLs are emitted upon minting. The URI function exists as a centralized fallback
* for systems that are not aware of the URI mint event. According to the EIP-1155 standard
* this mint event should take precedence https://eips.ethereum.org/EIPS/eip-1155
* This contract is not a proxy. 
* This contract is not pausable.
* This contract is not lockable.
* This contract cannot be rug pulled.
* The URIs are not changeable after mint. 
* Only the private key holders of individual NFTs and those they have granted 
* access to may change the ownership rights of NFTs on this contract.
*/

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

contract OwnerfyContract4 is Context, AccessControlEnumerable, ERC1155 {

  string public constant name = 'Ownerfy';
  string public constant symbol = 'OWNERFY';
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

  event Update(string _value, uint256 indexed _id);

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `AUDITOR_ROLE` to the account that
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
     * - Update event added for blockchain information - Ownerfy
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data, string calldata _uri, string calldata _update) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Ownerfy: must have minter role to mint");
        emit URI(_uri, id);
        if (bytes(_update).length > 0) {
          emit Update(_update, id);
        }

        _mint(to, id, amount, data);
    }

    /**
     * @dev Creates `amount` new tokens for `creator`, of token type `id`
     * Then sends tokens to the first receiever address
     * Creator needs to have approvalAll set for minter to be able
     * To send on their behalf
     *
     * - Update event added for blockchain information - Ownerfy
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function lazyMint(address creator, address to, uint256 id, uint256 amount, bytes memory data, string calldata _uri, string calldata _update) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Ownerfy: must have minter role to mint");
        emit URI(_uri, id);
        if (bytes(_update).length > 0) {
          emit Update(_update, id);
        }

        _mint(creator, id, amount, data);
        safeTransferFrom(creator, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     *
     * - Update event added for blockchain information - Ownerfy
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data, string[] calldata _uris, string[] calldata updates) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "Ownerfy: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
          emit URI(_uris[i], ids[i]);
          if (bytes(updates[i]).length > 0) {
            emit Update(updates[i], ids[i]);
          }
        }
    }

    /**
     * @dev Adds new blockchain information regarding a token
     */
    function update(string calldata _update, uint256 id) public virtual {
        require(hasRole(AUDITOR_ROLE, _msgSender()), "Ownerfy ERC1155: must have auditor role to update");
        emit Update(_update, id);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}