// SPDX-License-Identifier: MIT
// PaintSwap / doublesharp / cipher0x
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Counters.sol";

import "./INFTeacher.sol";
import "./ERC721PresetMinterPauserAutoIdRoyalty.sol";
import "./ERC721SplitWithdrawals.sol";

contract NFTeacher is INFTeacher, ERC721SplitWithdrawals, ERC721PresetMinterPauserAutoIdRoyalty, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public immutable MINT_PRICE;
    uint256 public mintStart;

    mapping(address => bool) private marketplaces;
    address[] public royaltyERC20Tokens;

    // track token ids as they are minted
    Counters.Counter private tokenIds;

    uint16 public constant MAX_SUPPLY = 5000;
    uint16 public currentMaxSupply;
    uint8 public immutable MAX_PER_TX;

    string private baseURI;

    // uses the OZ preset
    constructor(
        string memory _baseTokenURI,
        uint256 _mintStart,
        uint256 _MINT_PRICE,
        uint8 _maxPerTx,
        uint16 _currentMaxSupply,
        address[] memory _recipients,
        uint16[] memory _splits
    )
        ERC721PresetMinterPauserAutoIdRoyalty('NFTeacher', 'NFTEACHER', _baseTokenURI, 500)
        ERC721SplitWithdrawals(_recipients, _splits)
    {
        // state
        mintStart = _mintStart;
        baseURI = _baseTokenURI;

        // immutable
        currentMaxSupply = _currentMaxSupply;
        MAX_PER_TX = _maxPerTx;
        MINT_PRICE = _MINT_PRICE;

        // mint tokens to the contract
        for (uint256 i = 0; i < 5; i++) {
            tokenIds.increment();
            _safeMint(address(this), tokenIds.current());
        }
    }

    /**
     * @dev Mints a new token up to the current supply, stopping at the max supply.
     */
    function mintNFTeacher(uint256 _quantity) public payable override {
        require(mintStart <= block.timestamp, 'Minting not started.');
        require(MAX_PER_TX >= _quantity, 'Too many mints.');
        require(currentMaxSupply >= tokenIds.current() + _quantity, 'No more tokens, currently.');
        require(MAX_SUPPLY >= tokenIds.current() + _quantity, 'No more tokens, ever.');
        require(MINT_PRICE * _quantity == msg.value, 'Wrong value sent.');

        for (uint8 i = 0; i < _quantity; i++) {
            tokenIds.increment();
            _safeMint(msg.sender, tokenIds.current());
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override mustExist(_tokenId) returns (string memory) {
        string memory _uri = super.tokenURI(_tokenId);
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, '.json')) : '';
    }

    /**
     * Override isApprovedForAll to whitelisted marketplaces to enable listings without needing approval.
     * Just makes it easier for users.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721, IERC721)
        returns (bool isOperator)
    {
        if (marketplaces[_operator]) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /// @dev Gets the count of royalty contracts
    function getRoyaltyERC20TokenCount() external view override returns (uint256) {
        return royaltyERC20Tokens.length;
    }

    /// @dev Gets the count of royalty contracts
    function getRoyaltyERC20Tokens() external view override returns (address[] memory) {
        return royaltyERC20Tokens;
    }

    // OWNER

    /// @dev Set the mint start time, only by the owner
    function setMintStart(uint256 _mintStart) external override onlyOwner {
        mintStart = _mintStart;
    }

    /// @dev Set the base URI for the token, only by the owner
    function setBaseURI(string memory _uri) external override onlyOwner {
        baseURI = _uri;
    }

    /// @notice set the whitelisted marketplace contract addresses
    /// @dev Only the owner can call this method
    /// @param _marketplace the marketplace contract address to whitelist
    /// @param _allowed the whitelist status
    function setMarketplaceApproval(address _marketplace, bool _allowed) external override onlyOwner {
        emit MarketplaceApprovalUpdated(_marketplace, _allowed, marketplaces[_marketplace]);
        marketplaces[_marketplace] = _allowed;
    }

    /// @dev Set a list of ERC20 token addresses to check for royalties
    /// @param _royaltyERC20Tokens and array of ERC20 contract addresses
    function setErc20RoyaltyTokens(address[] memory _royaltyERC20Tokens) external override onlyOwner {
        royaltyERC20Tokens = _royaltyERC20Tokens;
    }

    /// @dev Set a list of ERC20 token addresses to check for royalties
    /// @param _currentMaxSupply and array of ERC20 contract addresses
    function setCurrentMaxSupply(uint16 _currentMaxSupply) external override onlyOwner {
        require(MAX_SUPPLY >= _currentMaxSupply, 'Current max supply too high.');
        require(currentMaxSupply < _currentMaxSupply, 'Up only.');
        currentMaxSupply = _currentMaxSupply;
    }

    /// @dev Send the held tokens to someone
    /// @param _to address to send to
    /// @param _tokenId token id to send
    function sendHeldTokens(address _to, uint256 _tokenId) external onlyOwner {
        require(address(this) == ownerOf(_tokenId), 'Not the token owner.');
        _transfer(address(this), _to, _tokenId);
    }

    // PRIVATE

    /// @dev override the base URI for the token
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @dev The receive function is triggered when FTM is received
    receive() external payable virtual {
        // check ERC20 token balances while we have the chance, if we send FTM it will forward them
        for (uint256 i = 0; i < royaltyERC20Tokens.length; i++) {
            // send the tokens to the recipients
            IERC20 _token = IERC20(royaltyERC20Tokens[i]);
            if (_token.balanceOf(address(this)) > 0) {
                this.withdrawTokens(royaltyERC20Tokens[i]);
            }
        }

        // withdraw the splits
        this.withdraw();
    }
}
