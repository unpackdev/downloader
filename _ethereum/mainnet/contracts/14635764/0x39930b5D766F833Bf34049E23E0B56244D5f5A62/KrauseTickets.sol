// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;
import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";

import "./SafetyLatchUpgradeable.sol";

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract KrauseTickets is
    ERC1155Upgradeable,
    OwnableUpgradeable,
    SafetyLatchUpgradeable,
    IERC721Receiver
{
    using Strings for uint256;

    event Exchanged(
        address exchanger,
        uint256 legacyTokenId,
        address legacyContract
    );

    string private baseUri;
    string public contractURI;
    string public name;
    string public symbol;

    uint256 public constant upperLevelId = 0;
    uint256 public upperLevelEdition;
    uint256 public constant clubLevelId = 1;
    uint256 public clubLevelEdition;
    uint256 public constant courtsideId = 2;
    uint256 public courtsideEdition;

    address public willCallTickets;
    address public legacyTickets;

    uint256 public royaltyFeeInBips; // 1% = 100
    address public royaltyReceiver;

    function initialize(
        address _willCallTickets,
        address _legacyTickets,
        string memory _uri
    ) public initializer {
        willCallTickets = _willCallTickets;
        legacyTickets = _legacyTickets;
        baseUri = _uri;
        royaltyReceiver = msg.sender;
        name = "Krause House Ticket";
        symbol = "KH";
        upperLevelEdition = 61;
        clubLevelEdition = 60;
        courtsideEdition = 59;
        __ERC1155_init("");
        __Ownable_init();
        __SafetyLatchUpgradeable_init();
    }

    /// @notice set name and symbol for contract
    function setName(string memory _name, string memory _symbol)
        public
        onlyOwner
    {
        name = _name;
        symbol = _symbol;
    }

    /// @notice mint more tickets to the address
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external onlyOwner {
        _mint(_to, _id, _amount, "");
    }

    /// @notice set editions for legacy ticekts
    function setEditions(
        uint256 _upperLevel,
        uint256 _clubLevel,
        uint256 _courtside
    ) external onlyOwner {
        upperLevelEdition = _upperLevel;
        clubLevelEdition = _clubLevel;
        courtsideEdition = _courtside;
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(ERC1155Upgradeable)
        returns (bool)
    {
        return
            bytes4(keccak256("royaltyInfo(uint256,uint256)")) == interfaceID ||
            super.supportsInterface(interfaceID);
    }

    /// @notice get uri based on token id
    /// @param tokenId token id to get uri for
    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory _baseUri = baseUri;
        return
            bytes(_baseUri).length > 0
                ? string(abi.encodePacked(_baseUri, tokenId.toString()))
                : "";
    }

    /// @notice for OpenSea royalty compatibility
    function setContractURI(string memory _uri) public onlyOwner {
        contractURI = _uri;
    }

    /// @notice set base uri for all tokens
    /// @param _uri base uri string
    function setUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyReceiver, _calculateRoyalty(_salePrice));
    }

    /// @notice allow setting royalty info
    /// @param _royaltyReceiver address of the receiver of the royalty
    /// @param _royaltyFeeInBips royalty fee in bips (100 = 1%)
    function setRoyaltyInfo(address _royaltyReceiver, uint256 _royaltyFeeInBips)
        external
        onlyOwner
    {
        royaltyReceiver = _royaltyReceiver;
        royaltyFeeInBips = _royaltyFeeInBips;
    }

    /// @notice Callback for receiving an ERC721 mints a ticket if the token was a legacy NFT
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external returns (bytes4) {
        if (msg.sender == willCallTickets) {
            _exchangeWillCall(from);
        } else if (msg.sender == legacyTickets) {
            _exchangeTicket(from, tokenId);
        } else {
            return this.onERC721Received.selector;
        }
        emit Exchanged(from, tokenId, msg.sender);
        return this.onERC721Received.selector;
    }

    /// @notice Exchange a ticket (burns the legacy ticket)
    /// @param to The address to mint the ticket to
    function _exchangeTicket(address to, uint256 tokenId) private {
        (bool success, bytes memory data) = legacyTickets.call(
            abi.encodeWithSignature("tokenToEdition(uint256)", tokenId)
        );
        uint256 edition = abi.decode(data, (uint256));
        if (success && edition == upperLevelEdition) {
            _mintUpperLevel(to);
        } else if (success && edition == clubLevelEdition) {
            _mintClubLevel(to);
        } else if (success && edition == courtsideEdition) {
            _mintCourtside(to);
        }
    }

    /// @notice Exchange a will call ticket (burns the legacy ticket)
    /// @param to The address to mint the ticket to
    function _exchangeWillCall(address to) private {
        _mintUpperLevel(to);
    }

    /// @notice Mint an upper level ticket for user
    /// @param to The address to mint the ticket to
    function _mintUpperLevel(address to) private {
        _mint(to, upperLevelId, 1, "");
    }

    /// @notice Mint a club level ticket for user
    /// @param to The address to mint the ticket to
    function _mintClubLevel(address to) private {
        _mint(to, clubLevelId, 1, "");
    }

    /// @notice Mint a courtside ticket for user
    /// @param to The address to mint the ticket to
    function _mintCourtside(address to) private {
        _mint(to, courtsideId, 1, "");
    }

    /// @notice Calculates royalty amount based on token's sale price
    /// @dev Divides sale price by 10000 since 10000 bips = 100%
    /// @param _salePrice The sale price of token in wei
    function _calculateRoyalty(uint256 _salePrice)
        private
        view
        returns (uint256)
    {
        return (_salePrice / 10000) * royaltyFeeInBips;
    }
}
