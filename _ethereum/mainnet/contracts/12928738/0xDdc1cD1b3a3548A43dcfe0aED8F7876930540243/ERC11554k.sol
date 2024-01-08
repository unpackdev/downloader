// OpenZeppelin ERC1155PresetMinterPauser.sol
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/presets/ERC1155PresetMinterPauser.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC1155.sol";
import "./ERC1155Pausable.sol";
import "./IFeesManager.sol";

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
contract ERC11554k is Context, AccessControl, ERC1155Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SEIZER_ROLE = keccak256("SEIZER_ROLE");

    // First owners of items.
    mapping(uint256 => address) internal _originators;
    // Fees manager contract address.
    address public feesManager;
    // Drop pool contract address.
    address public dropPool;
    // Redeem pool address.
    address public redeemPool;
    // Seize pool address.
    address public seizePool;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory uri) ERC1155(uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(SEIZER_ROLE, _msgSender());
    }

    /**
     * @dev Sets `feesManager` to `newFeesManager`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setFeesManager(address newFeesManager) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC11554k: must have admin role to set fees manager");
        feesManager = newFeesManager;
    }

    /**
     * @dev Sets `redeemPool` to `newRedeemPool`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setRedeemPool(address newRedeemPool) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC11554k: must have admin role to set redeem pool");
        redeemPool = newRedeemPool;
    }

    /**
     * @dev Sets `dropPool` to `newDropPool`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setDropPool(address newDropPool) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC11554k: must have admin role to set drop pool");
        revokeRole(MINTER_ROLE, dropPool);
        grantRole(MINTER_ROLE, newDropPool);
        dropPool = newDropPool;
    }

    /**
     * @dev Transfers all roles from `admin` to `newAdmin`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function transferAllRoles(address newAdmin) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC11554k: must have admin role to transfer all roles");
        grantRole(MINTER_ROLE, newAdmin);
        grantRole(PAUSER_ROLE, newAdmin);
        grantRole(SEIZER_ROLE, newAdmin);
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        if (hasRole(MINTER_ROLE, _msgSender())) {
            revokeRole(MINTER_ROLE, _msgSender());
        }
        if (hasRole(PAUSER_ROLE, _msgSender())) {
            revokeRole(PAUSER_ROLE, _msgSender());
        }
        if (hasRole(SEIZER_ROLE, _msgSender())) {
            revokeRole(SEIZER_ROLE, _msgSender());
        }
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Sets `seizePool` to `newSeizePool`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setSeizePool(address newSeizePool) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC11554k: must have admin role to set seize pool");
        revokeRole(SEIZER_ROLE, seizePool);
        grantRole(SEIZER_ROLE, newSeizePool);
        seizePool = newSeizePool;
    }

    /**
     * @dev Seize 'amount' items with 'id' by transferring ownership to admin, 
     * if seizure allowed, based on current storage fees debt.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function seize(uint256 id, address owner) external {
        require(hasRole(SEIZER_ROLE, _msgSender()), "ERC11554k: must have minter role to seize an item");
        require(feesManager != address(0), "ERC11554k: fees manager must be set");
        require(seizePool != address(0), "ERC1155k: seize pool must be set");
        require(IFeesManager(feesManager).isSeizureAllowed(id, owner), "ERC11554k: must allow seizure based on storage fees debt");     

        safeTransferFrom(owner, seizePool, id, balanceOf(owner, id), "0x");
    }

    /**
     * @dev Redeem item with 'id' by its owner.
     * Must pay all storage fees debt up to a redeem moment.
     */
    function redeem(uint256 id) external {
        if (feesManager != address(0)) {
            IFeesManager(feesManager).payStorage(id, _msgSender());
        }
        safeTransferFrom(_msgSender(), redeemPool, id, balanceOf(_msgSender(), id), "0x");
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

        _originators[id] = to;
        _mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");

        for (uint256 i = 0; i < ids.length; ++i) {
            _originators[ids[i]] = to;
        }
        _mintBatch(to, ids, amounts, data);
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

    /**
     * @dev Returns orignator address of item with 'id'.
     */
    function originatorOf(uint256 id) public returns (address) {
        return _originators[id];
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setURI(string memory newuri) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC11554k: must have admin role to set URI");
        _setURI(newuri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}
