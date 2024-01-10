// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

///   _______  _______  _______  _        _______  _______  _______  _______
///  (  ____ \(  ___  )(  ___  )( \      (  ____ )(  ___  )(  ___  )(  ____ )
///  | (    \/| (   ) || (   ) || (      | (    )|| (   ) || (   ) || (    )|
///  | |      | |   | || |   | || |      | (____)|| |   | || (___) || (____)|
///  | |      | |   | || |   | || |      |  _____)| |   | ||  ___  ||  _____)
///  | |      | |   | || |   | || |      | (      | |   | || (   ) || (
///  | (____/\| (___) || (___) || (____/\| )      | (___) || )   ( || )
///  (_______/(_______)(_______)(_______/|/       (_______)|/     \||/
///
///  @author: kfei.eth
///  @notice: Not audited, please use at your own risk.

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CoolPOAP is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _eventIdTracker;
    Counters.Counter private _tokenIdTracker;

    struct Event {
        string uri;
        address host;
    }

    error CP_NoPermission();
    error CP_EventDoesNotExist();
    error CP_TokenDoesNotExist();

    event CP_EventCreated(uint256 indexed eventId, string indexed uri);
    event CP_EventURIUpdated(uint256 indexed eventId, string indexed uri);
    event CP_EventHostUpdated(uint256 indexed eventId, address indexed host);

    mapping(uint256 => Event) _events;
    mapping(uint256 => uint256) _tokenEventIds;

    /**
     * @dev Constructooooooor
     */
    constructor(string memory n, string memory s) ERC721(n, s) {}

    /**
     * @dev Create an event, permissionlessly
     */
    function createEvent(string calldata uri, address host)
        external
        payable
        returns (uint256)
    {
        uint256 id = _eventIdTracker.current() + 1;
        _events[id] = Event({uri: uri, host: host});
        _eventIdTracker.increment();

        emit CP_EventCreated(id, uri);
        return id;
    }

    /**
     * @dev Reverts when the event doesn't exist or caller isn't the host
     */
    modifier onlyHost(uint256 eventId, address user) {
        if (eventId > _eventIdTracker.current()) revert CP_EventDoesNotExist();
        if (_events[eventId].host != user) revert CP_NoPermission();
        _;
    }

    /**
     * @dev Mint tokens to each recipient
     */
    function mint(uint256 eventId, address[] calldata recipients)
        external
        payable
        onlyHost(eventId, msg.sender)
    {
        uint256 currentId = _tokenIdTracker.current();

        unchecked {
            for (uint256 i = 0; i < recipients.length; i++) {
                uint256 tokenId = ++currentId;
                _safeMint(recipients[i], tokenId);
                _tokenEventIds[tokenId] = eventId;
                _tokenIdTracker.increment();
            }
        }
    }

    /**
     * @dev Update the tokenURI for an event
     */
    function setEventURI(uint256 eventId, string calldata uri)
        external
        onlyHost(eventId, msg.sender)
    {
        _events[eventId].uri = uri;
        emit CP_EventURIUpdated(eventId, uri);
    }

    /**
     * @dev Transfer the host role
     */
    function setEventHost(uint256 eventId, address host)
        external
        onlyHost(eventId, msg.sender)
    {
        _events[eventId].host = host;
        emit CP_EventHostUpdated(eventId, host);
    }

    /**
     * @notice Just in case
     */
    function withdraw(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        recipient.transfer(amount);
    }

    /**
     * @notice Just in case
     */
    function withdraw(
        address recipient,
        address erc20,
        uint256 amount
    ) external onlyOwner {
        IERC20(erc20).transfer(recipient, amount);
    }

    /**
     * @dev Get event URI by ID
     */
    function getEventURIById(uint256 eventId)
        external
        view
        returns (string memory)
    {
        return _events[eventId].uri;
    }

    /**
     * @dev Get event host by ID
     */
    function getEventHostById(uint256 eventId) external view returns (address) {
        return _events[eventId].host;
    }

    /**
     * @dev Get event ID by token
     */
    function getEventIdByToken(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        if (!_exists(tokenId)) revert CP_TokenDoesNotExist();
        return _tokenEventIds[tokenId];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert CP_TokenDoesNotExist();
        return _events[_tokenEventIds[tokenId]].uri;
    }

    /**
     * @notice Just in case
     */
    receive() external payable {}
}
