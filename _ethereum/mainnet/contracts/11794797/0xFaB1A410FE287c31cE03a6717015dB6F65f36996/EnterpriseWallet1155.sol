pragma solidity ^0.6.2;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC165.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./Initializable.sol";
import "./OpenseaMetdata.sol";

/**
 * @dev {ERC1155} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract EnterpriseWallet1155 is Initializable, Context, AccessControl, ERC1155Burnable, ERC1155Pausable, OpenseaMetdata {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;
    bytes4 private constant _INTERFACE_ID_CONTRACT_METADATA_URI = 0x7a62b340;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory tokenMetadataUri, string memory contractUri, address minter) public ERC1155(tokenMetadataUri) OpenseaMetdata(contractUri) {
        _setDefaults(tokenMetadataUri, contractURI, minter, _msgSender(), _msgSender());
    }

    function _setDefaults(string memory tokenMetadataUri, string memory contractUri, address admin, address pauser, address minter) initializer public  {
        _registerInterface(_INTERFACE_ID_ERC165);
        _registerInterface(_INTERFACE_ID_ERC1155);
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
        _registerInterface(_INTERFACE_ID_CONTRACT_METADATA_URI);

        if (admin == address(0)) {
            _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        } else {
            _setupRole(DEFAULT_ADMIN_ROLE, admin);
        }
        if (pauser == address(0)) {
            _setupRole(PAUSER_ROLE, _msgSender());
        } else {
            _setupRole(PAUSER_ROLE, pauser);
        }
        if (minter == address(0)) {
            _setupRole(MINTER_ROLE, _msgSender());
        } else {
            _setupRole(MINTER_ROLE, minter);
        }

        _setURI(tokenMetadataUri);
        _setContractURI(contractUri);
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
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        _mintBatch(to, ids, amounts, data);
    }

    function sell(address[] memory to, uint256[] memory ids, uint256[] memory amounts) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to sell");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to[i]] = amounts[i].add(_balances[ids[i]][to[i]]);
            emit TransferSingle(_msgSender(), address(0), to[i], ids[i], amounts[i]);
        }
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override(ERC1155, ERC1155Pausable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function setContractURI(string memory newContractURI) internal virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "EnterpriseWallet721: must have admin role to change contract URI");
        _setContractURI(newContractURI);
    }
}
