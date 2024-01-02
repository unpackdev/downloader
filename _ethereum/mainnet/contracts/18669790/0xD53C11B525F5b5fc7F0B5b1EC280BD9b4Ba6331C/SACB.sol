// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract SACB is
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    ERC2981,
    Ownable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    /// @notice max total supply
    uint256 public constant MAX_SUPPLY = 10000;
    /// @notice purchase price of one token
    uint256 public constant PRICE = 0.05 ether;
    /// @notice token Ids counter
    Counters.Counter private _tokenIdCounter;
    /// @notice indicator of the activity of the sale
    bool public saleIsActive;
    /// @notice base URI
    string public baseURI;

    /// @dev - supply limit
    error SupplyLimit(string err);
    /// @dev - unequal length of arrays
    error InvalidArrayLengths(string err);
    /// @dev - address to the zero;
    error ZeroAddress(string err);
    /// @dev - passed zero quantity
    error ZeroQuantity(string err);
    /// @dev - sale not active
    error SaleNotActive(string err);
    ///@dev returned if user not have enough ETH for operation
    error NotEnoughETH(string err);
    /// @dev - zero total supply
    error ZeroTotalSupply(string err);
    /// @dev - passed empty string
    error EmptyString(string err);

    /// @notice emitted when the token URI is updated
    event UpdateURI(uint256 indexed tokenId, string newUri);
    /// @notice emitted when the base URI is updated
    event UpdateBaseURI(string baseURI);
    /// @notice emitted when sale is turned on and off
    event ActivateSale(bool isActive);
    /// @notice emitted when owner make withdraw ETH from contract
    event Withdraw(address indexed to, uint256 amount);

    constructor(
        uint96 fee_, // royalty fee percent
        address feeRecipient_, // fee recipient address
        string memory baseURI_ // base URI
    ) ERC721("The Separate Assault CryptoBrigade", "SACB") {
        //check that feeRecipient_ is performed on _setDefaultRoyalty, so there is no need to check it here
        _setDefaultRoyalty(feeRecipient_, fee_);
        saleIsActive = true;
        if (bytes(baseURI_).length > 0) {
            //baseURI can be an empty string
            baseURI = baseURI_;
        }
        _tokenIdCounter.increment();
    }

    /**
    @dev the modifier makes a check of nft token sale activity
    */
    modifier isActive() {
        if (!saleIsActive) {
            revert SaleNotActive("SACB: Sale not active");
        }
        _;
    }

    //================================== External functions ========================================

    /**
     * @dev The function sells nft tokens for the user. Accepts ETH as
     * payment and performs minting.
     * @param quantity - number of nft tokens
     */
    function safeMints(uint256 quantity)
        external
        payable
        nonReentrant
        isActive
    {
        if (quantity == 0) {
            revert ZeroQuantity("SACB: Zero quantity");
        }
        if (quantity > MAX_SUPPLY - totalSupply()) {
            revert SupplyLimit("SACB: Mintable limit exhausted");
        }
        uint256 ethPurchaseAmount = quantity * PRICE;

        if (msg.value < ethPurchaseAmount) {
            revert NotEnoughETH("SACB: Not enough ETH");
        }
        if (msg.value > ethPurchaseAmount) {
            uint256 excessETH = msg.value - ethPurchaseAmount;
            _sendETH(msg.sender, excessETH);
        }
        for (uint256 i; i < quantity; i++) {
            _mint(msg.sender);
        }
    }

    /**
     * @dev The function enables and disables the sale of nft tokens
     * @param _isActive - true - enable, false - disable
     */
    function activateSales(bool _isActive) external onlyOwner {
        saleIsActive = _isActive;
        emit ActivateSale(_isActive);
    }

    /**
     * @dev The function withdraws ETH from the contract to
     * the owner's address
     */
    function withdraw() external onlyOwner nonReentrant {
        _withdraw(owner());
    }

    /**
     * @dev The function withdraws ETH from the contract to
     * the recipient address
     */
    function withdrawTo(address to) external onlyOwner nonReentrant {
        if (to == address(0)) {
            revert ZeroAddress("SACB: Zero address");
        }
        _withdraw(to);
    }

    /**
     * @dev function updates the base URI. Only owner can call it.
     * @param _newBaseURI - new baseURI
     */
    function updateBaseURI(string calldata _newBaseURI) external onlyOwner {
        //_newBaseURI can be an empty string (even if baseURI had some value before), no need to check its length here
        baseURI = _newBaseURI;
        emit UpdateBaseURI(baseURI);
    }

    /**
     * @dev This function updates the uri for a specific token.
     * Only owner can call it.
     * @param tokenId - token id
     * @param uri - new token uri
     */
    function updateURI(uint256 tokenId, string calldata uri)
        external
        onlyOwner
    {
        if (bytes(uri).length == 0) {
            revert EmptyString("SACB: Empty string");
        }
        _setTokenURI(tokenId, uri);
        emit UpdateURI(tokenId, uri);
    }

    /**
     * @dev This function performs a batch update of the token uri.
     * Only owner can call it.
     * @param tokenIds - array of token ids
     * @param uris - array of token uris
     */
    function updateUriBatch(uint256[] calldata tokenIds, string[] calldata uris)
        external
        onlyOwner
    {
        if (tokenIds.length != uris.length) {
            revert InvalidArrayLengths("SACB: Invalid array lengths");
        }
        for (uint256 i; i < tokenIds.length; i++) {
            if (bytes(uris[i]).length == 0) {
                revert EmptyString("SACB: Empty string");
            }
            _setTokenURI(tokenIds[i], uris[i]);
            emit UpdateURI(tokenIds[i], uris[i]);
        }
    }

    /** 
    @dev Sets the royalty information that all ids in this contract will default to. 
    Only owner can call it.
    @param receiver procceds fee recipient
    @param feeNumerator fee percent 
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     * Only owner can call it.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Removes royalty information for a specific token id.
     */
    function deleteTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    //================================== Internal functions ========================================
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721-_safeMint}.
     */
    function _mint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
     * @dev See {IERC721-_burn}.
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    /**
     * @dev See {IERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
    @notice internal support function for ETH transfer.
    @param to_ - recipient wallet address
    @param amount_ - amount of ETH
    */
    function _sendETH(address to_, uint256 amount_) internal {
        (bool success, ) = to_.call{value: amount_}("");
        require(success, "Transfer failed");
    }

    /**
    @notice internal function for withdaw ETH from contract.
    @param to - recipient wallet address
    */
    function _withdraw(address to) internal {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NotEnoughETH("SACB: Not enough ETH");
        }
        _sendETH(to, balance);
        emit Withdraw(to, balance);
    }

    //==================================== View functions ============================================

    /**
     * @dev Function returns an array of ID tokens owned by the user.
     */
    function userTokens(address user)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        if (user == address(0)) revert ZeroAddress("SACB: Zero address");
        uint256[] memory result = new uint256[](balanceOf(user));
        for (uint256 i; i < balanceOf(user); i++) {
            result[i] = tokenOfOwnerByIndex(user, i);
        }
        return result;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(ERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
