// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./MetaTxContext.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";


contract MAD is ERC1155, AccessControl, Pausable, ERC1155Burnable, MetaTxContext, ERC1155Supply {

    using Strings for uint256;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private _name = "MADworld.io";
    string private _symbol = "MAD";
    string private _tokenURIPrefix = "https://ipfs.madworld.io/metadata/";
    string private _uri = string(abi.encodePacked(_tokenURIPrefix, "{id}.json"));

    constructor(address forwarder_) ERC1155(_uri) MetaTxContext(forwarder_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Only Role
    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "Roles: caller does not have the role");
        _;
    }

    // MetaTx
    function _msgSender() internal view override(Context, MetaTxContext) returns (address payable sender) {
        sender = MetaTxContext._msgSender();
    }

    function _msgData() internal view override(Context, MetaTxContext) returns (bytes memory) {
        return MetaTxContext._msgData();
    }


    // ERC721 Base

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString(), ".json"));
    }

}