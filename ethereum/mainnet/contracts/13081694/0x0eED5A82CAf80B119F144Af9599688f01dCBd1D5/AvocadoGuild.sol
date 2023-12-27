// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./MultiURI.sol";
import "./BaseERC1155.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract AvocadoGuild is Ownable, Pausable, MultiURI, BaseERC1155 {
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory _name, string memory _symbol)
        Ownable()
        BaseERC1155()
    {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenURI(tokenId);
    }

    /**
     * @dev Sets the paused failsafe. Can only be called by owner
     * @param _setPaused - paused state
     */
    function setPaused(bool _setPaused) public onlyOwner {
        return (_setPaused) ? _pause() : _unpause();
    }

    /**
     * @dev Creates a brand new token of a given id, base uri and uri
     * @param _tokenId - token id to create new token
     * @param _uri - uri for meta data
     * @param _baseUri -prefix for the uri for this token
     */
    function createToken(
        uint256 _tokenId,
        string memory _uri,
        string memory _baseUri
    ) public onlyOwner {
        require(bytes(_tokenURI(_tokenId)).length == 0, "token exists");
        _setTokenURI(_tokenId, _uri);
        _setTokenBaseURI(_tokenId, _baseUri);
    }

    /**
     * @dev Sets token URI for a given tokenId
     * @param tokenId -
     */
    function setTokenURI(uint256 tokenId, string memory _uri) public onlyOwner {
        _setTokenURI(tokenId, _uri);
    }

    /**
     * @dev Sets token Base URI for a given tokenId
     * @param tokenId - paused state
     */
    function setTokenBaseURI(uint256 tokenId, string memory _uri)
        public
        onlyOwner
    {
        _setTokenBaseURI(tokenId, _uri);
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param account          Address of the future owner of the token
     * @param id          Token ID to mint
     * @param amount    Amount of tokens to mint
     * @param data        Data to pass if receiver is contract
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    /**
     * @dev Mints some amount of tokens to an address
     * - `ids` and `amounts` must have the same length.
     * @param to          Address of the future owner of the token
     * @param ids          Token IDs to mint
     * @param amounts    Amount of tokens for each token ID to mint
     * @param data        Data to pass if receiver is contract
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Burns amount of tokens of an address
     * @param owner          Owner to burn token from. this is usually the message sender
     * @param id          Token IDs to burn
     * @param value    Amount of tokens to burn
     */
    function burn(
        address owner,
        uint256 id,
        uint256 value
    ) public {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender) == true,
            "Need operator approval for 3rd party burns."
        );
        _burn(owner, id, value);
    }

    /**
     * @dev Burns amount of tokens in batches of an address
     * @param owner          Owner to burn token from. this is usually the message sender
     * @param ids          Token IDs to burn
     * @param amounts    Amount of tokens for each token ID to burn
     */
    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        require(
            owner == msg.sender || isApprovedForAll(owner, msg.sender) == true,
            "Need operator approval for 3rd party burns."
        );
        _burnBatch(owner, ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override whenNotPaused {}
}
