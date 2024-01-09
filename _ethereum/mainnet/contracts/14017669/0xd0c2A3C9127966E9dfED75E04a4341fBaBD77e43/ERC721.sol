// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenSeaGasFreeListing.sol";

/// @notice Fork of Rari-Capital Solmate
///         https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol
/// @dev Reverts on `balanceOf` and `tokenURI` as per the 721 spec.
///      Also includes Opensea gas free listing and EIP2981 (royalty info).
/// @author samking.eth
abstract contract ERC721 {
    /**************************************************************************
     * STORAGE
     *************************************************************************/

    string public name;
    string public symbol;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public _balances;

    mapping(uint256 => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals;

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

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function approve(address approved, uint256 id) public virtual {
        address owner = ownerOf[id];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "NOT_AUTHORIZED");
        _tokenApprovals[id] = approved;
        emit Approval(owner, approved, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public virtual returns (bool) {
        return
            _operatorApprovals[owner][operator] ||
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }

    function getApproved(uint256 tokenId) public virtual returns (address) {
        require(ownerOf[tokenId] != address(0), "NON_EXISTANT");
        return _tokenApprovals[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from ||
                msg.sender == _tokenApprovals[id] ||
                _operatorApprovals[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balances[from]--;
            _balances[to]++;
        }

        ownerOf[id] = to;

        delete _tokenApprovals[id];

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

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
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
        require(to != address(0), "INVALID_RECIPIENT");
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balances[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];
        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balances[owner]--;
        }

        delete ownerOf[id];
        delete _tokenApprovals[id];

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
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
