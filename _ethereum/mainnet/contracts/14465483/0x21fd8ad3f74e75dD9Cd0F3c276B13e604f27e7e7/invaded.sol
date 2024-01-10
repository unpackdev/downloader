// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @creator: denkozeth
/// Special thanks to Pak and his Censored collection for inspiring us.

//    ██ ███    ██ ██    ██  █████  ██████  ███████ ██████
//    ██ ████   ██ ██    ██ ██   ██ ██   ██ ██      ██   ██
//    ██ ██ ██  ██ ██    ██ ███████ ██   ██ █████   ██   ██
//    ██ ██  ██ ██  ██  ██  ██   ██ ██   ██ ██      ██   ██
//    ██ ██   ████   ████   ██   ██ ██████  ███████ ██████

import "./AdminControl.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";

interface IUkReserved {
    function metadata() external view returns (string memory);
}

interface IInvader {
    function metadata(
        uint256 tokenId,
        string memory message,
        uint256 value,
        uint256 angle,
        string memory community
    ) external view returns (string memory);

    function getAngle() external view returns (uint256);

    function validateMessage(string memory messag_)
        external
        pure
        returns (bool);
}

contract Invaded is ReentrancyGuard, AdminControl, ERC721 {
    uint256 private _tokenIndex;
    mapping(uint256 => string) private _tokenMessages;
    mapping(uint256 => uint256) private _tokenValues;
    mapping(uint256 => uint256) private _tokenAngles;
    mapping(bytes32 => bool) private _messageHashes;
    mapping(address => uint256) private _owners;
    mapping(address => string) private _communityTags;
    address[] private _communities;
    uint256 private _supportBalance;
    uint256 private _messageEndTime;

    bool private _freedom;
    bool private _uniqueMessagesOnly;
    address _invaderAddress;
    address _reservedAddress;
    address _creatorAddress;

    mapping(uint256 => bool) private _tokenFreedom;
    mapping(uint256 => address) private _tokenInvaderAddress;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    address public constant _UKRAINE_ADDRESS =
        0x165CD37b4C644C2921454429E7F9358d18A45e14;

    constructor() ERC721("invaded", unicode"]]]]]]]]]") {
        _creatorAddress = msg.sender;
        _tokenIndex++; //first token is reserved
    }

    /**
     * @dev Activate reserved token
     */
    function activateReserved(address reservedAddress) external adminRequired {
        _reservedAddress = reservedAddress;
        if (!_exists(1)) {
            _mint(msg.sender, 1);
        }
    }

    /**
     * @dev Deactivate this contract
     */
    function deactivate(uint256 messageEndTime) external adminRequired {
        _messageEndTime = messageEndTime;
    }

    /**
     * Set the unique messages state
     */
    function setUniqueMessagesOnly(bool unique) public adminRequired {
        _uniqueMessagesOnly = unique;
    }

    /**
     * Set the freedom state
     */
    function setFreedom(uint256[] calldata tokenIds, bool freedom)
        public
        adminRequired
    {
        if (tokenIds.length == 0) {
            _freedom = freedom;
        } else {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _tokenFreedom[tokenIds[i]] = freedom;
            }
        }
    }

    /**
     * @dev Update metadata
     */
    function updateTokenMetadata(
        uint256[] calldata tokenIds,
        address invaderAddress
    ) external adminRequired {
        if (tokenIds.length == 0) {
            _invaderAddress = invaderAddress;
        } else {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _tokenInvaderAddress[tokenIds[i]] = invaderAddress;
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, ERC721)
        returns (bool)
    {
        return
            AdminControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 ||
            interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function withdrawAll() external adminRequired {
        (bool success1, ) = _creatorAddress.call{value: _supportBalance}("");
        require(success1);
        (bool success2, ) = _UKRAINE_ADDRESS.call{value: address(this).balance}(
            ""
        );
        require(success2);
    }

    /**
     * @dev Returns registered communities
     */
    function getCommunities() public view returns (address[] memory) {
        return _communities;
    }

    /**
     * @dev Update community information
     */
    function updateCommunity(address communityAddress, string memory tag_)
        external
        adminRequired
    {
        require(
            IERC165(communityAddress).supportsInterface(
                type(IERC721).interfaceId
            ),
            "IERC721"
        );
        bool not_found = bytes(_communityTags[communityAddress]).length == 0;
        _communityTags[communityAddress] = tag_;
        if (not_found) {
            if (bytes(tag_).length == 0) {
                return;
            }
            _communities.push(communityAddress);
        } else {
            if (bytes(tag_).length == 0) {
                for (uint256 i = 0; i < _communities.length; i++) {
                    if (communityAddress == _communities[i]) {
                        _communities[i] = _communities[_communities.length - 1];
                        _communities.pop();
                        break;
                    }
                }
            }
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (tokenId == 1) {
            return IUkReserved(_reservedAddress).metadata();
        } else {
            string memory community;
            for (uint256 i = 0; i < _communities.length; i++) {
                try
                    IERC721(_communities[i]).balanceOf(ownerOf(tokenId))
                returns (uint256 balance) {
                    if (balance > 0) {
                        community = _communityTags[_communities[i]];
                    }
                } catch (bytes memory) {}
                if (bytes(community).length > 0) {
                    break;
                }
            }

            return
                IInvader(
                    _tokenInvaderAddress[tokenId] != address(0)
                        ? _tokenInvaderAddress[tokenId]
                        : _invaderAddress
                ).metadata(
                        tokenId,
                        _tokenMessages[tokenId],
                        _tokenValues[tokenId],
                        _tokenAngles[tokenId],
                        community
                    );
        }
    }

    /**
     * @dev See {ERC721-_beforeTokenTranfser}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            from == address(0) ||
                (_exists(tokenId) && tokenId == 1) ||
                _tokenFreedom[tokenId] ||
                _freedom,
            "ERC721: transfer not permitted"
        );
        _owners[from] = 0;
        _owners[to] = tokenId;
    }

    /**
     * @dev Get sernder's token ID
     */
    function getYourTokenId() external view returns (uint256) {
        return _owners[msg.sender];
    }

    /**
     * @dev Validate that a message can be written
     */
    function validateMessage(string memory message_)
        public
        view
        returns (bool)
    {
        require(
            !_uniqueMessagesOnly ||
                (_uniqueMessagesOnly &&
                    !_messageHashes[keccak256(bytes(message_))]),
            "Message already exists"
        );
        return IInvader(_invaderAddress).validateMessage(message_);
    }

    /**
     * @dev Write a message and get an NFT.
     */
    function message(string memory message_, bool support_)
        external
        payable
        nonReentrant
    {
        require(
            ((_messageEndTime == 0 || block.timestamp <= _messageEndTime) &&
                _tokenIndex >= 2) || msg.sender == owner(),
            "Cannot message"
        );
        require(balanceOf(msg.sender) == 0, "You have already sent a message");
        validateMessage(message_);
        if (msg.value > 0 && support_) {
            _supportBalance = _supportBalance + msg.value / 10;
        }
        _tokenIndex++;
        _tokenMessages[_tokenIndex] = message_;
        _tokenValues[_tokenIndex] = msg.value;
        _tokenAngles[_tokenIndex] = IInvader(_invaderAddress).getAngle();
        _messageHashes[keccak256(bytes(message_))] = true;
        _owners[msg.sender] = _tokenIndex;
        _mint(msg.sender, _tokenIndex);
    }

    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        adminRequired
    {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */

    function getRoyalties(uint256)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256)
        external
        view
        returns (address payable[] memory recipients)
    {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        returns (address, uint256)
    {
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }
}
