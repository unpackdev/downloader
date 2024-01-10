// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC1155.sol";

contract ArtOfResistance is ERC1155, ERC2981, Ownable {
    using Address for address payable;

    /******************************
     * Constants, structs, events *
     ******************************/
    uint96 public constant SECONDARY_FEE_BPS = 250;

    struct Token {
        // Updatable by the owner
        string uri;
        bool frozen;
        uint256 price;
        uint256 supply;
        // Managed by the contract
        uint256 minted;
        // Fixed at creation
        address recipient;
    }

    event PermanentURI(string _value, uint256 indexed _id);
    event Donation(uint256 indexed value, address indexed from);

    /********************
     * Public variables *
     ********************/

    /// Token count
    uint256 public tokenCount;

    /// Token data
    mapping(uint256 => Token) public tokens;

    /// Switch for pausing mints
    bool public mintingPaused;

    /******************
     * Initialization *
     ******************/

    constructor() ERC1155("") {}

    /********************
     * Public functions *
     ********************/

    /// Mint a token
    function mint(uint256 _tokenId) external payable tokenExists(_tokenId) {
        Token storage token = tokens[_tokenId];

        require(!mintingPaused, "Minting paused");
        require(msg.value >= token.price, "Not enough ether");
        require(available(_tokenId) > 0, "No tokens left");

        token.minted += 1;
        _mint(msg.sender, _tokenId, 1, "");
        _donate(token.recipient);
    }

    /// Check how many copies of a token can still be minted
    function available(uint256 _tokenId)
        public
        view
        tokenExists(_tokenId)
        returns (uint256)
    {
        return tokens[_tokenId].supply - tokens[_tokenId].minted;
    }

    /// Get the metadata URI for a token
    function uri(uint256 _tokenId)
        public
        view
        override
        tokenExists(_tokenId)
        returns (string memory)
    {
        return tokens[_tokenId].uri;
    }

    /// Get the current state of all created tokens
    function allTokens() external view returns (Token[] memory _tokens) {
        _tokens = new Token[](tokenCount);

        for (uint256 i; i < tokenCount; i++) {
            _tokens[i] = tokens[i];
        }
    }

    /*****************
     * Admin actions *
     *****************/

    /// Create a batch of new tokens
    function create(Token[] calldata _newTokens) external onlyOwner {
        for (uint256 i; i < _newTokens.length; i++) {
            _create(_newTokens[i]);
        }
    }

    /// Update a token
    function update(uint256 _tokenId, Token calldata _newToken)
        external
        onlyOwner
        tokenExists(_tokenId)
    {
        Token storage token = tokens[_tokenId];

        require(!token.frozen, "Token is frozen");
        require(_newToken.supply >= token.minted, "Supply too low");

        _update(_tokenId, _newToken);
    }

    /// Update minting state
    function setMintingPaused(bool _paused) external onlyOwner {
        mintingPaused = _paused;
    }

    /*************
     * Internals *
     *************/

    /// Forward all ether to another address
    function _donate(address _to) internal {
        payable(_to).sendValue(msg.value);
        emit Donation(msg.value, msg.sender);
    }

    /// Create a new token
    function _create(Token calldata _newToken) internal {
        require(_newToken.supply > 0, "Token supply must be >0");

        uint256 tokenId = tokenCount;
        tokenCount += 1;

        _update(tokenId, _newToken);
        tokens[tokenId].recipient = _newToken.recipient;

        _setTokenRoyalty(tokenId, _newToken.recipient, SECONDARY_FEE_BPS);
    }

    /// Update a token's properties in storage
    function _update(uint256 _tokenId, Token calldata _newToken) internal {
        Token storage token = tokens[_tokenId];

        token.uri = _newToken.uri;
        token.price = _newToken.price;
        token.supply = _newToken.supply;
        token.frozen = _newToken.frozen;

        if (_newToken.frozen) {
            emit PermanentURI(_newToken.uri, _tokenId);
        } else {
            emit URI(_newToken.uri, _tokenId);
        }
    }

    /// See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC2981, ERC1155)
        returns (bool)
    {
        return
            ERC2981.supportsInterface(_interfaceId) ||
            ERC1155.supportsInterface(_interfaceId);
    }

    /// Check if a token exists
    modifier tokenExists(uint256 _tokenId) {
        require(_tokenId < tokenCount, "Token does not exist");
        _;
    }
}
