// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ERC165.sol";

import "./ERC2981ContractWideRoyalties.sol";

/**
 * @title Artist Portfolio
 * @author Adcoda AG (adcoda.com)
 */
contract Portfolio is ERC721URIStorage, ERC2981ContractWideRoyalties, Ownable {

    /// The maximum ERC-2981 royalties percentage
    uint256 public constant MAX_ROYALTIES_PCT = 750;

    /// Locked token IDs
    mapping(uint256 => bool) private _lockedTokenIds;

    /// Use Counters for token IDs
    using Counters for Counters.Counter;

    /// Token ID counter
    Counters.Counter private _tokenIds;

    /**
     * @notice Boom... Let's go!
     * @param _royaltiesPercentage Initial royalties percentage for ERC-2981
     */
    constructor(uint256 _royaltiesPercentage) ERC721("Ayyoub Bouzerda Art", "AYYOUB")    {
        require(
            _royaltiesPercentage <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _msgSender(),
            _royaltiesPercentage
        );
    }

    /**
     * @notice Returns the current total supply derived from token count
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice Mints token
     * @param _tokenURI The token URI
     */
    function mintToken(string memory _tokenURI) external onlyOwner {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();

        _safeMint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @notice Update a tokens URI
     * @param _tokenId The token ID
     * @param _tokenURI The token URI
     */
    function updateTokenURI(uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        require(_lockedTokenIds[_tokenId] != true, 'Token is Locked');

        _setTokenURI(_tokenId, _tokenURI);
    }

    /**
     * @notice Lock a tokens so it's URI cannot be changed anymore
     * @param _tokenId The token ID
     */
    function lockToken(uint256 _tokenId) external onlyOwner {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        require(_lockedTokenIds[_tokenId] != true, 'Token Already Locked');

        _lockedTokenIds[_tokenId] = true;
    }

    /**
     * @notice Check if token is locked
     * @param _tokenId The token ID
     */
    function isTokenLocked(uint256 _tokenId) public view returns (bool tokenLocked) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");

        tokenLocked = _lockedTokenIds[_tokenId] == true;
    }

    /**
     * @notice Withdraws any ERC20 tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _amount Amount to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawERC20(address _token, address _to, uint256 _amount, bool _hasVerifiedToken) external onlyOwner {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC20(_token).transfer(
            _to,
            _amount
        );
    }

    /**
     * @notice Withdraws any ERC721 tokens
     * @dev WARNING: Double check token is legit before calling this
     * @param _token Contract address of token
     * @param _to Address to which to withdraw
     * @param _tokenId Token ID to withdraw
     * @param _hasVerifiedToken Must be true (sanity check)
     */
    function withdrawERC721(address _token, address _to, uint256 _tokenId, bool _hasVerifiedToken) external onlyOwner {
        require(
            _hasVerifiedToken == true,
            "Need to verify token"
        );

        IERC721(_token).safeTransferFrom(
            address(this),
            _to,
            _tokenId
        );
    }

    /**
     * @notice Sets token royalties (ERC-2981)
     * @param _recipient Recipient of the royalties
     * @param _value Royalty percentage (using 2 decimals - 10000 = 100, 0 = 0)
     */
    function setRoyalties(address _recipient, uint256 _value) external onlyOwner {
        require(
            _value <= MAX_ROYALTIES_PCT,
            "Royalties too high"
        );

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 _interfaceId) public view override (ERC721, ERC2981Base) returns (bool doesSupportInterface)    {
        doesSupportInterface = super.supportsInterface(_interfaceId);
    }
}
