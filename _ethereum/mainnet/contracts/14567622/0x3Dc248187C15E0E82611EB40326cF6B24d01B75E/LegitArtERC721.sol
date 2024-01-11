// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IProxyRegistry.sol";
import "./ILegitArtERC721.sol";

/// @title LegitArt NFT
contract LegitArtERC721 is ILegitArtERC721, ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IProxyRegistry public proxyRegistry;

    struct FeeInfo {
        address creator;
        uint256 royaltyFee;
        address gallerist;
        uint256 galleristFee;
    }

    mapping(uint256 => FeeInfo) internal feeInfoOf;

    constructor(IProxyRegistry _proxyRegistry) ERC721("Legit.Art ERC721", "LegitArt") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        proxyRegistry = _proxyRegistry;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "The caller is not a minter");
        _;
    }

    function getFeeInfo(uint256 _tokenId)
        external
        view
        override
        returns (
            address creator,
            uint256 royaltyFee,
            address gallerist,
            uint256 galleristFee
        )
    {
        creator = feeInfoOf[_tokenId].creator;
        royaltyFee = feeInfoOf[_tokenId].royaltyFee;
        gallerist = feeInfoOf[_tokenId].gallerist;
        galleristFee = feeInfoOf[_tokenId].galleristFee;
    }

    /// @notice Mint a new NFT
    function _mintTo(
        address _creator,
        uint256 _royaltyFee,
        address _gallerist,
        uint256 _galleristFee,
        address _to,
        uint256 _tokenId,
        string memory _tokenURI
    ) internal {
        feeInfoOf[_tokenId] = FeeInfo({
            creator: _creator,
            royaltyFee: _royaltyFee,
            gallerist: _gallerist,
            galleristFee: _galleristFee
        });
        _mint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    /// @notice Mint a new NFT
    /// @dev Should be called only by a minter (i.e. Marketplace contract)
    function mintTo(
        address _creator,
        uint256 _royaltyFee,
        address _gallerist,
        uint256 _galleristFee,
        address _to,
        uint256 _tokenId,
        string memory _tokenURI
    ) public override onlyMinter {
        _mintTo(_creator, _royaltyFee, _gallerist, _galleristFee, _to, _tokenId, _tokenURI);
    }

    /// @dev ERC165 support
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's LegitArt proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist LegitArt proxy contract for easy trading.
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function mint(
        uint256 _tokenId,
        string memory _tokenURI,
        uint256 _royaltyFee,
        address _gallerist,
        uint256 _galleristFee
    ) public {
        _mintTo(
            _msgSender(), // creator
            _royaltyFee,
            _gallerist,
            _galleristFee,
            _msgSender(), // to
            _tokenId,
            _tokenURI
        );
    }
}
