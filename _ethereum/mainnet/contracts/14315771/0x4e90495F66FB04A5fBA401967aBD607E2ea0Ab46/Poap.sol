// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.5.2;

import "./Initializable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./PoapRoles.sol";
import "./PoapPausable.sol";

/**
 * @title POAP contract in Ethereum
 * @dev Mainnet point of interaction with POAP
 * - Users can:
 *   # Add Event Organizer
 *   # Mint token for an event
 *   # Batch Mint
 *   # Burn Tokens if admin
 *   # Pause contract if admin
 *   # Unpause contract if admin
 *   # ERC721 full interface (base, metadata, enumerable)
 * - To be covered by a proxy contract
 * @author POAP
 * - Developers:
 *   # Agustin Lavarello
 *   # Rodrigo Manuel Navarro Lajous
 *   # Ramiro Gonzales
**/
contract Poap is Initializable, ERC721, ERC721Enumerable, PoapRoles, PoapPausable {
   
    /**
     * @dev Emmited when token is created
     */
    event EventToken(uint256 eventId, uint256 tokenId);

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base token URI
    string private _baseURI;

    // Last Used id (used to generate new ids)
    uint256 private lastId;

    // Event Id for each token
    mapping(uint256 => uint256) private _tokenEvent;


    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Gets the Event Id for the token
     * @param tokenId ( uint256 ) The Token Id you want to query
     * @return uint256 representing the Event id for the token
     */
    function tokenEvent(uint256 tokenId) public view returns (uint256) {
        return _tokenEvent[tokenId];
    }

    /**
     * @dev Gets the Token Id and Event Id for a given index of the tokens list of the requested owner
     * @param owner ( address ) Owner address of the token list to be queried
     * @param index ( uint256 ) Index to be accessed of the requested tokens list
     * @return ( uint256, uint256 ) Token Id and Event Id for the given index of the tokens list owned by the requested address
     */
    function tokenDetailsOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId, uint256 eventId) {
        tokenId = tokenOfOwnerByIndex(owner, index);
        eventId = tokenEvent(tokenId);
    }

    /**
     * @dev Gets URI for the token metadata
     * @param tokenId ( uint256 ) The Token Id you want to get the URI
     * @return ( string ) URI for the token metadata 
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        uint eventId = _tokenEvent[tokenId];
        return _strConcat(_baseURI, _uint2str(eventId), "/", _uint2str(tokenId), "");
    }

    /**
     * @dev Sets Base URI for the token metadata.
     * Requires 
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     * @param baseURI ( string ) The base URI to change
     */
    function setBaseURI(string memory baseURI) public onlyAdmin whenNotPaused {
        _baseURI = baseURI;
    }

    /**
     * @dev Approves another address to transfer the given token ID (Implements ERC71)
     * Wrapper for function extended from ERC721 (  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol )
     * Requires 
     * - The msg sender to be the owner, approved, or operator
     * - The contract does not have to be paused
     * @param to ( address ) The addres to be approved for the given token ID
     * @param tokenId ( uint256 ) ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    /**
     * @dev Sets or unsets the approval of a given operator (Implements ERC71)
     * Wrapper for function extended from ERC721 (  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol )
     * Requires 
     * - The msg sender to be the owner, approved, or operator
     * - The contract does not have to be paused
     * @param to ( address ) The address of the operator to set the approval
     * @param approved ( bool ) Represents the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Wrapper for function extended from ERC721 (  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol )
     * Requires 
     * - The msg sender to be the owner, approved, or operator
     * - Contract not paused
     * @param from ( address ) The address of the current owner of the token
     * @param to ( address ) The address to receive the ownership of the given token ID
     * @param tokenId ( uint256 ) ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address (Implements ERC71)
     * Wrapper for function extended from ERC721 (  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol )
     * Requires 
     * - The msg sender to be the owner, approved, or operator
     * - The contract does not have to be paused
     * @param from ( address ) The address of the current owner of the token
     * @param to ( address ) The address to receive the ownership of the given token ID
     * @param tokenId ( uint256 ) ID of the token to be transferred
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address (Implements ERC71)
     * Wrapper for function extended from ERC721 (  https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol )
     * Requires 
     * - The msg sender to be the owner, approved, or operator
     * - The contract does not have to be paused
     * @param from ( address ) The address of the current owner of the token
     * @param to ( address ) The address to receive the ownership of the given token ID
     * @param tokenId ( uint256 ) ID of the token to be transferred
     * @param _data ( bytes ) Data to send along with a safe transfer check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Mint token to address
     * @param eventId ( uint256 ) EventId for the new token
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(uint256 eventId, address to)
    public whenNotPaused onlyEventMinter(eventId) returns (bool)
    {
        lastId += 1;
        return _mintToken(eventId, lastId, to);
    }

    /**
     * @dev Mint specific token to address.
     * Requires 
     * - The msg sender to be the admin, or event minter for the specific event Id
     * - The contract does not have to be paused
     * @param eventId ( uint256 ) EventId for the new token
     * @param tokenId ( uint256 ) Token Id for the new token
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintToken(uint256 eventId, uint256 tokenId, address to)
    public whenNotPaused onlyEventMinter(eventId) returns (bool)
    {
        return _mintToken(eventId, tokenId, to);
    }

    /**
     * @dev Mint token to many addresses.
     * Requires 
     * - The msg sender to be the admin, or event minter for the specific event Id
     * - The contract does not have to be paused
     * @param eventId ( uint256 ) EventId for the new token
     * @param to ( array of address ) The addresses that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintEventToManyUsers(uint256 eventId, address[] memory to)
    public whenNotPaused onlyEventMinter(eventId) returns (bool)
    {
        for (uint256 i = 0; i < to.length; ++i) {
            _mintToken(eventId, lastId + 1 + i, to[i]);
        }
        lastId += to.length;
        return true;
    }

    /**
     * @dev Mint many tokens to address.
     * Requires 
     * - The msg sender to be the admin
     * - The contract does not have to be paused
     * @param eventIds ( array uint256 ) Event Ids to assing to user
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintUserToManyEvents(uint256[] memory eventIds, address to)
    public whenNotPaused onlyAdmin() returns (bool)
    {
        for (uint256 i = 0; i < eventIds.length; ++i) {
            _mintToken(eventIds[i], lastId + 1 + i, to);
        }
        lastId += eventIds.length;
        return true;
    }

    /**
     * @dev Burns a specific ERC721 token.
     * Requires 
     * - The msg sender to be the owner, approved, or admin
     * @param tokenId ( uint256 ) Id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId) || isAdmin(msg.sender), "Sender doesn't have permission");
        _burn(tokenId);
    }

    function initialize(string memory __name, string memory __symbol, string memory __baseURI, address[] memory admins)
    public initializer
    {
        ERC721.initialize();
        ERC721Enumerable.initialize();
        PoapRoles.initialize(msg.sender);
        PoapPausable.initialize();

        // Add the requested admins
        for (uint256 i = 0; i < admins.length; ++i) {
            _addAdmin(admins[i]);
        }

        _name = __name;
        _symbol = __symbol;
        _baseURI = __baseURI;

        // Register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Internal function to burn a specific token
     * - Reverts if the token does not exist
     * @param owner ( addreess ) The owner of the token to burn
     * @param tokenId ( uint256 ) ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        delete _tokenEvent[tokenId];
    }

    /**
     * @dev Internal function to mint tokens
     * @param eventId ( uint256 ) EventId for the new token
     * @param tokenId ( uint256 ) The token id to mint.
     * @param to ( address ) The address that will receive the minted tokens.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mintToken(uint256 eventId, uint256 tokenId, address to) internal returns (bool) {
        _mint(to, tokenId);
        _tokenEvent[tokenId] = eventId;
        emit EventToken(eventId, tokenId);
        return true;
    }

    /**
     * @dev Function to convert uint to string
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Function to concat strings
     * Taken from https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
     */
    function _strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e)
    internal pure returns (string memory _concatenatedString)
    {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    /**
     * @dev Admin can remove other Admin.
     * @param account ( address ) Address of the admin to be removed
     */
    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }
}
