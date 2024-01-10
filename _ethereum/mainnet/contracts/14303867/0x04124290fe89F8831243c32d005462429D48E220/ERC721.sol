// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./OpenSeaGasFreeListing.sol";

/// @notice Fork of Rari-Capital Solmate that reverts on `balanceOf` if passed zero address
/// https://github.com/Rari-Capital/solmate/blob/main/src/token/ERC721.sol
/// @author samking.eth
abstract contract ERC721 {
    /**************************************************************************
     * STORAGE
     *************************************************************************/

    string public name;
    string public symbol;

    mapping(uint256 => address) public _ownerOf;
    mapping(address => uint256) public _balances;

    mapping(uint256 => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals;
    bool public openSeaGasFreeListingEnabled;

    /**************************************************************************
     * ERRORS
     *************************************************************************/

    error NotAuthorized();
    error BalanceQueryForZeroAddress();

    error AlreadyMinted();
    error NonExistent();

    error InvalidRecipient();
    error UnsafeRecipient();

    /**************************************************************************
     * EVENTS
     *************************************************************************/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**************************************************************************
     * CONSTRUCTOR
     *************************************************************************/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /**************************************************************************
     * ERC721
     *************************************************************************/

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function balanceOf(address account) public view virtual returns (uint256) {
        if (account == address(0)) revert BalanceQueryForZeroAddress();
        return _balances[account];
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        if (_ownerOf[id] == address(0)) revert NonExistent();
        return _ownerOf[id];
    }

    function approve(address approved, uint256 id) public virtual {
        address owner = _ownerOf[id];
        if (!(msg.sender == owner || _operatorApprovals[owner][msg.sender])) revert NotAuthorized();
        _tokenApprovals[id] = approved;
        emit Approval(owner, approved, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return
            _operatorApprovals[owner][operator] ||
            (openSeaGasFreeListingEnabled &&
                OpenSeaGasFreeListing.isApprovedForAll(owner, operator));
    }

    function getApproved(uint256 id) public view virtual returns (address) {
        if (_ownerOf[id] == address(0)) revert NonExistent();
        return _tokenApprovals[id];
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        address owner = _ownerOf[id];
        if (owner == address(0)) revert NonExistent();
        if (
            owner != from ||
            !(msg.sender == owner ||
                _tokenApprovals[id] == msg.sender ||
                _operatorApprovals[owner][msg.sender])
        ) revert NotAuthorized();
        if (to == address(0)) revert InvalidRecipient();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balances[from]--;
            _balances[to]++;
        }

        _ownerOf[id] = to;

        delete _tokenApprovals[id];

        emit Approval(address(0), to, id);
        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            !(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector)
        ) revert UnsafeRecipient();
    }

    /**************************************************************************
     * ERC165
     *************************************************************************/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == 0x2a55205a; // ERC165 Interface ID for EIP2981
    }

    /**************************************************************************
     * INTERNAL MINT AND BURN
     *************************************************************************/

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert InvalidRecipient();
        if (_ownerOf[id] != address(0)) revert AlreadyMinted();

        // Will probably never be more than uin256.max so may as well save some gas.
        unchecked {
            _balances[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];
        if (_ownerOf[id] == address(0)) revert NonExistent();

        // Ownership check above ensures no underflow.
        unchecked {
            _balances[owner]--;
        }

        delete _ownerOf[id];
        delete _tokenApprovals[id];

        emit Approval(address(0), address(0), id);
        emit Transfer(owner, address(0), id);
    }

    /**************************************************************************
     * SAFE MINT
     *************************************************************************/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
