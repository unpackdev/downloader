// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./IMintableERC1155.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./IERC165.sol";

contract RootMintableERC1155 is
    ERC1155,
    AccessControl,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC1155
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    string public name;
    string public symbol;
    // Used as the URI for all token types by relying on ID substition, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    constructor(
        string memory uri_,
        address _predicate_address,
        string memory name_,
        string memory symbol_
    ) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _predicate_address);
        _setURI(uri_);
        _initializeEIP712(uri_);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    /**
    * @notice A distinct Uniform Resource Identifier (URI) for a given token.
    * @dev URIs are defined in RFC 3986.
    *      URIs are assumed to be deterministically generated based on token ID
    *      Token IDs are assumed to be represented in their hex format in URIs
    * @return URI string
    */
    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(_id), ".json"));
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal override virtual {
        _uri = newuri;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier only(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            "no role"
        );
        _;
    }

    function _msgSender()
        internal
        override
        view
        returns (address)
    {
        return ContextMixin.msgSender();
    }
}
