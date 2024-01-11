// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./draft-ERC721VotesUpgradeable.sol";
import "./Initializable.sol";

contract Ey3k0nHonorary is Initializable, ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    ERC721VotesUpgradeable,
    OwnableUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public newClaimableOwner;
    address public newClaimableDefaultOwner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) initializer public {
        __ERC721_init("Ey3k0n Honorary", "Ey3HON");
        __ERC721URIStorage_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __Ownable_init();
        __EIP712_init("Ey3k0n Honorary", "1");
        __ERC721Votes_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, owner);
        transferOwnership(owner);
        transferDefaultAdminRole(owner);
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Upgradeable, ERC721VotesUpgradeable)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function grantMintRole(address newMinter) public virtual onlyRole(MINTER_ROLE) {
        _grantRole(MINTER_ROLE, newMinter);
    }

    function revokeMintRole(address newMinter) public virtual onlyRole(MINTER_ROLE) {
        _revokeRole(MINTER_ROLE, newMinter);
    }

    function burn(uint256 tokenId) public virtual override onlyRole(MINTER_ROLE) {
        _burn(tokenId);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        newClaimableOwner = newOwner;
    }

    function claimOwnership() public virtual {
        require(msg.sender == newClaimableOwner, "Ownable: newClaimableOwner is not msg.sender");
        _transferOwnership(newClaimableOwner);
    }

    function transferDefaultAdminRole(address newDefault) public onlyRole(DEFAULT_ADMIN_ROLE) {
        newClaimableDefaultOwner = newDefault;
    }

    function claimDefaultAdminRole() public {
        require(newClaimableDefaultOwner == msg.sender, "caller is not the claimable owner");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function revokeDefaultAdminRole(address adminAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(msg.sender != adminAddress, "You cannot revoke yourself");
        _revokeRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyRole(MINTER_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }
}
