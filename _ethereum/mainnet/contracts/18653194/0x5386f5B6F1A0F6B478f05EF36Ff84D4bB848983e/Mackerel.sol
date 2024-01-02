// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721RoyaltyUpgradeable.sol";

contract Mackerel is
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721RoyaltyUpgradeable,
    AccessControlUpgradeable
{
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string public baseURI;
    uint256 private _totalSupply;
    uint256 private _maxSupply;

    function initialize(
        string memory name_,
        string memory symbol_,
        address royaltyPayee_,
        uint96 feeNumerator_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __AccessControl_init_unchained();
        _setDefaultRoyalty(royaltyPayee_, feeNumerator_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());

        _maxSupply = 10000;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice public function for admin set base URI for NFT token.
    function setBaseURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        baseURI = _uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721PausableUpgradeable, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function safeMint(address to) external onlyRole(MINTER_ROLE) returns (uint256 newNftId) {
        newNftId = _totalSupply + 1;
        require(newNftId <= _maxSupply, "max supply reached");
        _safeMint(to, newNftId);
        _totalSupply = newNftId;
    }

    function burn(uint256 tokenId) public override onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(tokenId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721RoyaltyUpgradeable, ERC721Upgradeable) onlyRole(BURNER_ROLE) {
        super._burn(tokenId);
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721RoyaltyUpgradeable, ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
