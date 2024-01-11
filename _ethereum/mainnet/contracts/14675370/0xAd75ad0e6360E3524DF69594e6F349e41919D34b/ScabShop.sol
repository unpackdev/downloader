// SPDX-License-Identifier: MIT

/**
░░░░░░░░▒░░░░░░░░░░░░░░░░▒▒▒▒▒░░░░░░░░░░▒░░░░░░░░░
░░░░░░▒▓███░░░░░░░░▒▒▒▒▒░░▒▒███░░░░░░░▓▒██░░░░░░░░
░░░░▓█░░░▓█▒░░░░▒▓▒░░░░░░░░░░██░░░░░░██▒░██░░░░░░░
░░░░▒██░░▒▒░░░░▓█░░░░░░░░░░░░██▓░░░░░▓█▓░▒█▒░░░░░░
░░░░░▒██░░░░░░██░░░░░░░░░░░░▒░██▒░░░░▓█▓▒▒░░░░░░░░
░░░░░░▓██░░░░▓█▒░░░░░░░░░░░░▒░▒██░░░░▓██▓▓░░░░░░░░
░░░░░░░▓██░░░██░░░░░░░░░░░░▓░░░██▒░░░▓█▓▒██░░░░░░░
░░░░░░░░██▓░░██▒░░░░░░░░░░▒░░░░▒██░░░▓█▓░▓██░░░░░░
░░░░░░░░░██▓░▓██░░░░░░░░░▒▒░░░░░██▒░░▓█▓░░▓██░░░░░
░░░░░░░░░░██▒░██▓░░░░▓███████▒░░▒██░░▓█▓░░░█▓░░░░░
░░░░▒█▒░░░░█▓░░▓█▓░░░░░░░░░░░░░░░▓█▒░▓█▓░░▒░░░░░░░
░░░░▓██░░░▒░░░░░▒██▒░░░░░░░░░░░▓░░░░░▓██▒░░░░░░░░░
░░░░░▓██▓░░░░░░░░░░▒▓▓▓▒▒░░▒▒▓▓▒░░░░░▓▓░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

CTHDRL x Scott Campbell

Contract: Scab Shop
Website: https://scab.shop
**/

pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./ERC721.sol";
import "./IAccessControl.sol";
import "./AccessControl.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ScabShop is ERC721, Ownable, AccessControl {
    using Counters for Counters.Counter;

    event Render(uint256 id);

    struct MintInfo {
        address artist;
        uint64 renderedAt;
        uint16 royaltyBPS;
        string metadataURI;
    }

    Counters.Counter private currentId;

    mapping(uint256 => MintInfo) public mints;
    mapping(address => address) private overrideRoyaltyRecipients;

    bytes32 public constant ARTIST_ROLE = keccak256('ARTIST_ROLE');

    constructor() ERC721('Scab Shop', 'SCAB') {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ARTIST_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            _interfaceId == type(IERC721).interfaceId ||
            _interfaceId == type(IAccessControl).interfaceId ||
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
        @dev Batch grant/revoke artist roles for gas efficiency
        @param recipients array of artist addresses
        @param isArtist whether to grant or revoke the artist role
    */
    function setArtists(address[] calldata recipients, bool isArtist)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (isArtist) {
                _grantRole(ARTIST_ROLE, recipients[i]);
            } else {
                _revokeRole(ARTIST_ROLE, recipients[i]);
            }
        }
        return true;
    }

    /**
        @dev Convenience function to get the artist of any fiven token
        @param _id token id
        @return address of artist
    */
    function artistOf(uint256 _id) public view returns (address) {
        return mints[_id].artist;
    }

    /**
        @dev Get URI for given token id
        @param _id token id to get uri for
        @return URI of metadata
    */
    function tokenURI(uint256 _id)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory _metadata = mints[_id].metadataURI;
        return string(abi.encodePacked(_metadata));
    }

    /**
        @dev Artist function to mint a new piece
        @param _metadata The URI of the metadata for this piece
        @param _to The address that the piece should be minted to
        @param _royalty The royalty rate for this particular piece
    */
    function mint(
        string memory _metadata,
        address _to,
        uint16 _royalty
    ) public onlyRole(ARTIST_ROLE) returns (uint256) {
        require(_royalty <= 2000, 'ERC2981Royalties: Too high');
        currentId.increment();
        uint256 _id = currentId.current();
        _mint(_to, _id);
        mints[_id] = MintInfo({
            metadataURI: _metadata,
            artist: msg.sender,
            renderedAt: 0,
            royaltyBPS: _royalty
        });
        return _id;
    }

    /**
        @dev Owner function to update metadata URI if needed
        @param _id The ID of the token
        @param _metadata new metadata URL
    */
    function updateMetadata(uint256 _id, string memory _metadata)
        external onlyOwner
    {
        mints[_id].metadataURI = _metadata;
    }

    /**
        @dev Artist function to mark that one of their pieces has been rendered
        @param _id The ID of the token
        @param _metadata new metadata URL
    */
    function markRendered(uint256 _id, string memory _metadata)
        public
        onlyRole(ARTIST_ROLE)
    {
        require(
            address(msg.sender) == mints[_id].artist,
            'Only the artist can render the piece'
        );
        require(
            mints[_id].renderedAt == 0,
            'This piece has already been rendered'
        );
        mints[_id].metadataURI = _metadata;
        mints[_id].renderedAt = uint64(block.timestamp);
        emit Render(_id);
    }

    /**
        @dev Check if any particular piece has been rendered to skin.
        @param _id The ID of the token
    */
    function isRendered(uint256 _id) public view returns (bool) {
        return mints[_id].renderedAt > 0;
    }

    /**
        @param _id Token ID to burn
        User burn function for token id
     */
    function burn(uint256 _id) public {
        require(_isApprovedOrOwner(_msgSender(), _id), 'Not approved');
        _burn(_id);
    }

    // EIP-2981
    // https://eips.ethereum.org/EIPS/eip-2981
    /**
        @dev Get royalty information for token
        @param _price Sale price for the token
     */
    function royaltyInfo(uint256 _id, uint256 _price)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        address _artist = mints[_id].artist;
        if (overrideRoyaltyRecipients[_artist] == address(0x0)) {
            receiver = owner();
        } else {
            receiver = overrideRoyaltyRecipients[_artist];
        }
        royaltyAmount = (_price * mints[_id].royaltyBPS) / 10000;
    }

    /**
        @dev Set a royalty address for a particular artist
        @param _artist the wallet address of the approved artist
        @param _to payable address where the royalty should be sent
    */
    function setRoyalty(address _artist, address _to) external onlyOwner {
        overrideRoyaltyRecipients[_artist] = _to;
    }
}
