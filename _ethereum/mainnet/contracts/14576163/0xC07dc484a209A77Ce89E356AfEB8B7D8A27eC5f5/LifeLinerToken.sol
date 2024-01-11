// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC1155.sol";
import "./ERC2981.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

/**
 * @dev {ERC1155} token
 * Visit lifeliner.org for more information
 *
 */
contract LifeLinerToken is
    Context,
    AccessControl,
    ERC1155Burnable,
    ERC1155Pausable,
    ERC1155Supply,
    ERC2981
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct TokenSettings {
        uint256 tokenId;
        uint256 maxAmount;
        uint256 price;
    }
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    mapping(uint256 => TokenSettings) private _saleRegistry;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(
        string memory uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(uri) {
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(msg.sender, 1000);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
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
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "CharityToken: must have minter role to mint"
        );

        _mint(to, id, amount, data);
    }

    function purchase(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public payable {
        TokenSettings memory saleTokenSettings = _saleRegistry[id];
        require(
            saleTokenSettings.maxAmount > 0,
            "CharityToken: Token is not purchaseable"
        );
        require(
            saleTokenSettings.maxAmount >= totalSupply(id) + amount,
            "CharityToken: No tokens left to purchase"
        );
        require(
            msg.value >= amount * saleTokenSettings.price,
            "CharityToken: User did not send enough Ether for purchase"
        );
        _mint(msg.sender, id, amount, data);
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function withdrawalAll() external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "CharityToken: must have admin role to withdrawal"
        );
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function setBaseURI(string memory _uri) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "CharityToken: must have role admin to change baseuri"
        );
        _setURI(_uri);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "CharityToken: must have minter role to mint"
        );

        _mintBatch(to, ids, amounts, data);
    }

    function registerTokenForSale(
        uint256 id,
        uint256 maxAmount,
        uint256 tokenPrice
    ) public payable {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "CharityToken: must have minter role to register new tokens for sale"
        );
        _saleRegistry[id] = TokenSettings(id, maxAmount, tokenPrice);
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
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "CharityToken: must have pauser role to unpause"
        );
        _unpause();
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
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "CharityToken: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
