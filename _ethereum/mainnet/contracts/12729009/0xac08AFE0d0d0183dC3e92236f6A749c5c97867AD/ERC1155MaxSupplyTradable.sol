// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauser.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

/**
 * @title ERC1155MaxSupplyTradable
 * ERC1155MaxSupplyTradable - ERC1155 contract that whitelists an operator address, has create and mint functionality, and supports useful standards from OpenZeppelin,
  like _exists(), name(), symbol(), and totalSupply()
 */
contract ERC1155MaxSupplyTradable is ERC1155PresetMinterPauser, Ownable {
    using Strings for string;
    using SafeMath for uint256;

    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) customUri;
    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    /**
     * @dev Require _msgSender() to have role minter
     */
    modifier minterOnly() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC1155MaxSupplyTradable: must have minter role"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155PresetMinterPauser(_uri) {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev Returns the max quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    function uri(uint256 _id) public view override returns (string memory) {
        // We have to convert string to bytes to check for existence
        bytes memory customUriBytes = bytes(customUri[_id]);
        if (customUriBytes.length > 0) {
            return customUri[_id];
        } else {
            return super.uri(_id);
        }
    }

    /**
     * @dev Returns the total quantity for a token ID
     * @param _id uint256 ID of the token to query
     * @return amount of token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     * @param _newURI New URI for all tokens
     */
    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    /**
     * @dev Will update the base URI for the token
     * @param _tokenId The token to update. _msgSender() must be its creator.
     * @param _newURI New URI for the token.
     */
    function setCustomURI(uint256 _tokenId, string memory _newURI)
        public
        minterOnly
    {
        customUri[_tokenId] = _newURI;
        emit URI(_newURI, _tokenId);
    }

    /**
     * @dev Creates a new token type and assigns _initialSupply to an address
     * @param _maxSupply max supply allowed
     * @return tokenId The newly created token ID
     */
    function create(uint256 _id, uint256 _maxSupply)
        external
        virtual
        minterOnly
        returns (uint256 tokenId)
    {
        require(_maxSupply > 0, "Max supply cannot be 0");
        require(tokenMaxSupply[_id] == 0, "Item with this id already exist");

        tokenMaxSupply[_id] = _maxSupply;
        return _id;
    }

    /**
     * @dev Mints some amount of tokens to an address
     * @param _to          Address of the future owner of the token
     * @param _id          Token ID to mint
     * @param _quantity    Amount of tokens to mint
     * @param _data        Data to pass if receiver is contract
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public virtual override minterOnly {
        require(
            tokenSupply[_id].add(_quantity) <= tokenMaxSupply[_id],
            "Max supply reached"
        );
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    /**
     * @dev Mint tokens for each id in _ids
     * @param _to          The address to mint tokens to
     * @param _ids         Array of ids to mint
     * @param _quantities  Array of amounts of tokens to mint per id
     * @param _data        Data to pass if receiver is contract
     */
    function batchMint(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data
    ) public virtual minterOnly {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 quantity = _quantities[i];

            require(
                tokenSupply[_id].add(quantity) <= tokenMaxSupply[_id],
                "Max supply reached"
            );

            tokenSupply[_id] = tokenSupply[_id].add(quantity);
        }
        _mintBatch(_to, _ids, _quantities, _data);
    }

    /**
     * @dev Burn some amount of tokens for an address
     * @param _account     The account to burn token for
     * @param _id          Token ID to burn
     * @param _quantity    Amount of tokens to burn
     */
    function burn(
        address _account,
        uint256 _id,
        uint256 _quantity
    ) public override {
        require(
            _account == _msgSender() ||
                isApprovedForAll(_account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        tokenSupply[_id] = tokenSupply[_id].sub(_quantity);
        _burn(_account, _id, _quantity);
    }

    /**
     * @dev Burn tokens for each id in _ids
     * @param _account     The account to burn tokens for
     * @param _ids         Array of ids to burn
     * @param _quantities  Array of amounts of tokens to burn per id
     */
    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public override {
        require(
            _account == _msgSender() ||
                isApprovedForAll(_account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 quantity = _quantities[i];
            tokenSupply[_id] = tokenSupply[_id].sub(quantity);
        }
        _burnBatch(_account, _ids, _quantities);
    }
}
