// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Royalty.sol";
import "./Adminable.sol";
import "./IDutchAuction.sol";
import "./ERC721BatchEnumerable.sol";

/**
 * @title Posterlad NFT contract made by Artiffine.
 * @author https://artiffine.com/
 */
contract PosterladNFT is ERC721, Adminable, ERC721Royalty {
    uint256 public immutable MAX_SUPPLY;
    IDutchAuction public immutable dutchAuction;

    string private _contractURI;
    string private _uri;
    uint256 private _totalSupply;

    error TokenIdDoesNotExist(uint256 tokenId);
    error WrongTokenIdsArrayLength(uint256 length);
    error NoTokensToMint();
    error EtherValueSentNotExact();
    error TokenAlreadyMinted(uint256 tokenId);
    error ArgumentIsAddressZero();
    error ContractBalanceIsZero();
    error TransferFailed();

    /**
     * @param _name Name of the collection.
     * @param _symbol Symbol of the collection.
     * @param _baseUri URI of the collection metadata folder.
     * @param _contractUri URI of contract-metadata json.
     * @param _dutchAuction Address of DutchAuction contract.
     * @param _maxSupply Number of tokens.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _contractUri,
        IDutchAuction _dutchAuction,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        require(_maxSupply != 0);
        require(address(_dutchAuction) != address(0));
        MAX_SUPPLY = _maxSupply;
        dutchAuction = _dutchAuction;
        _uri = _baseUri;
        _contractURI = _contractUri;
    }

    /**
     * @dev Adds support for `ERC721Royalty` interface.
     *
     * @param interfaceId Interface id.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Adds support for `ERC721Royalty` interface.
     *
     * @param tokenId Token id.
     */
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev Adds counter for `totalSupply()` function.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        if (from == address(0)) {
            ++_totalSupply;
        }
    }

    /* External Functions */

    /**
     * @notice Mints token by paying exact price in ETH.
     *
     * @dev Token id needs to be lesser than `maxSupply()`.
     *
     * @param _tokenId Token id.
     * @param _to Address to mint tokens to.
     */
    function mint(uint256 _tokenId, address _to) external payable {
        if (_tokenId >= MAX_SUPPLY) revert TokenIdDoesNotExist(_tokenId);
        uint256 price = dutchAuction.getAuctionPrice();
        if (msg.value != price) revert EtherValueSentNotExact();
        _safeMint(_to, _tokenId);
    }

    /**
     * @notice Returns current price auction in wei.
     *
     * @dev Throws `AuctionIsClosed()` error.
     */
    function getAuctionPrice() external view returns (uint256) {
        return dutchAuction.getAuctionPrice();
    }

    /**
     * @notice Returns URI of contract-level metadata.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Returns total minted supply.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns minted status of tokens.
     *
     * @param _tokenIds Array of token ids.
     */
    function getMintedStatusBatch(uint256[] memory _tokenIds) external view returns (bool[] memory) {
        uint256 length = _tokenIds.length;
        bool[] memory mintedStatus = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            mintedStatus[i] = _exists(_tokenIds[i]);
        }
        return mintedStatus;
    }

    /* Admin Functions */

    /**
     * @notice Mints token for free, only callable by an admin/owner.
     *
     * @dev Token id needs to be lesser than `maxSupply()`.
     *
     * @param _tokenId Token id.
     * @param _to Address to mint tokens to.
     */
    function freeMint(uint256 _tokenId, address _to) external onlyAdmin {
        if (_tokenId >= MAX_SUPPLY) revert TokenIdDoesNotExist(_tokenId);
        _safeMint(_to, _tokenId);
    }

    /**
     * @notice Mints tokens for free, callable only by an admin/owner.
     *
     * @param _tokenIds Array of token ids, lesser than `maxSupply()`.
     * @param _to Address to mint tokens to.
     */
    function batchFreeMint(uint256[] memory _tokenIds, address _to) external onlyAdmin {
        uint256 amount = _tokenIds.length;
        if (amount == 0) revert NoTokensToMint();
        for (uint256 i = 0; i < amount; ++i) {
            if (_tokenIds[i] >= MAX_SUPPLY) revert TokenIdDoesNotExist(_tokenIds[i]);
            _safeMint(_to, _tokenIds[i]);
        }
    }

    /**
     * @notice Sets URI of contract-level metadata.
     *
     * @param _URI URI of contract-level metadata.
     */
    function setContractURI(string memory _URI) external onlyAdmin {
        _contractURI = _URI;
    }

    /**
     * @notice Sets URI metadata for a given token id.
     *
     * @param _baseUri Token id.
     */
    function setBaseURI(string memory _baseUri) external onlyAdmin {
        _uri = _baseUri;
    }

    /**
     * @notice Sets Royalty info for the collection.
     *
     * @param _recipient Address to receive royalty.
     * @param _fraction Fraction of royalty.
     */
    function setDefaultRoyalty(address _recipient, uint96 _fraction) external onlyAdmin {
        _setDefaultRoyalty(_recipient, _fraction);
    }

    /* Owner Functions */

    /**
     * @notice Transfers all native currency to the owner, callable only by the owner.
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ContractBalanceIsZero();
        (bool success, ) = msg.sender.call{value: balance}('');
        if (!success) revert TransferFailed();
    }

    /**
     * @notice Recovers ERC20 token back to the owner, callable only by the owner.
     *
     * @param _token IERC20 token address to recover.
     */
    function recoverToken(IERC20 _token) external onlyOwner {
        if (address(_token) == address(0)) revert ArgumentIsAddressZero();
        uint256 balance = _token.balanceOf(address(this));
        if (balance == 0) revert ContractBalanceIsZero();
        _token.transfer(owner(), balance);
    }
}
