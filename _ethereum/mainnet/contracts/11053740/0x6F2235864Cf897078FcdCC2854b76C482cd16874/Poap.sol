pragma solidity ^0.5.15;

// Minimal POAP contract implementation
// Needed for the main contract
import "./ERC721.sol";
import "./Roles.sol";

contract PoapRoles {
    using Roles for Roles.Role;

    Roles.Role private _admins;

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.has(account);
    }

    function _removeAdmin(address account) internal {
        _admins.remove(account);
    }

}

contract Poap is ERC721, PoapRoles  {
    event EventToken(uint256 eventId, uint256 tokenId);

    // Last Used id (used to generate new ids)
    uint256 private lastId;

    // EventId for each token
    mapping(uint256 => uint256) private _tokenEvent;

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param tokenId The token id to mint.
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(uint256 eventId, uint256 tokenId, address to) internal returns (bool) {
        _mint(to, tokenId);
        _tokenEvent[tokenId] = eventId;
        emit EventToken(eventId, tokenId);
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param eventId EventId for the new token
     * @param to The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(uint256 eventId, uint256 tokenId, address to) public returns (bool) {
        return _mintToken(eventId, tokenId, to);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function addAdmin(address account) public {
        _addAdmin(account);
    }

}
