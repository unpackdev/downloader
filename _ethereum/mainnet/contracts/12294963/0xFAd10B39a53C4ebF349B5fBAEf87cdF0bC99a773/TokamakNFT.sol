// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

import "./AccessControl.sol";
import "./Counters.sol";

contract TokamakNFT is ERC721Enumerable, AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (string => bool) private _eventExists;
    string[] private _events;
    mapping (uint256 => string) private _tokenEvent;
    

    string private _tokenBaseURI;

    constructor(address owner, address minter) ERC721("Tokamak NFT", "TOK") {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);       
        _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);

        _setupRole(OWNER_ROLE, owner);
        _setupRole(MINTER_ROLE, minter);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "Only owner can use.");
        _;
    }

    modifier onlyMinter {
        require(isMinter(msg.sender), "Only minter can use.");
        _;
    }

    modifier ifOwnerOrMinter {
        require(isOwner(msg.sender) || isMinter(msg.sender), "Only minter can use.");
        _;
    }

    /**
     * @dev Returns true if msg.sender has an OWNER role.
     */
    function isOwner(address user) public view returns (bool) 
    {
        return hasRole(OWNER_ROLE, user);
    }


    /**
     * @dev Returns true if msg.sender has a MINTER role.
     */
    function isMinter(address user) public view returns(bool) 
    {
        return hasRole(MINTER_ROLE, user);
    }

    /**
     * @dev Adds new user as a minter.
     */
    function addMinter(address user) external onlyOwner
    {
        grantRole(MINTER_ROLE, user);
    }

    /**
     * @dev Removes the user as a minter.
     */
    function removeMinter(address user) external onlyOwner
    {
        revokeRole(MINTER_ROLE, user);
    }

    /**
     * @dev Removes the user as a minter.
     */
    function setBaseURI(string memory tokenBaseURI) external ifOwnerOrMinter
    {
        _tokenBaseURI = tokenBaseURI;
    }

    /**
     * @dev Returns the base URI for token.
     */
    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
     * @dev Returns the length.
     */
    function eventsLength() external view returns (uint)
    {
        return _events.length;
    }

    /**
     * @dev Returns events array
     */
    function events() external view returns (string[] memory)
    {
        return _events;
    }    

    /**
     * @dev Event by index
     */
    function eventByIndex(uint index) external view returns (string memory)
    {
        return _events[index];
    } 

    /**
     * @dev Returns event for given tokenId
     */
    function eventForToken(uint256 tokenId) external view returns (string memory)
    {
        return _tokenEvent[tokenId];
    }

    /**
     * @dev Adds new event
     */
    function registerEvent(string memory eventName) external ifOwnerOrMinter
    {
        require(_eventExists[eventName] == false, "Event is already registered");

        _eventExists[eventName] = true;
        _events.push(eventName);
    }

    /**
     * @dev Mints new token and returns it.
     */
    function mintToken(address user, string memory eventName) external onlyMinter returns (uint256)
    {
        require(_eventExists[eventName], "Event is not registered");

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _tokenEvent[tokenId] = eventName;
        _mint(user, tokenId);

        return tokenId;
    }
}
