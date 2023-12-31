// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice modified from Solmate 721.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
 
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transferFrom(
        address from,
        address to
    ) public virtual {

        if (from != _ownerOf[1]) {
            revert ("WRONG_FROM");
        }
        if (to == address(0)) {
            revert ("INVALID_RECIPIENT");
        }
        if (msg.sender != from) {
            revert ("NOT_AUTHORIZED");
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[1] = to;

        emit Transfer(from, to, 1);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    function _mint(address to) internal virtual {
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[1] = to;

        emit Transfer(address(0), to, 1);
    }
}
