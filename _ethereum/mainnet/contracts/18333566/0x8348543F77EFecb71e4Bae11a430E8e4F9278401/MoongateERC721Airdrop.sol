// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Royalty.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

/// @custom:security-contact contact@moongate.id
contract MoongateERC721Airdrop is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Royalty,
    ERC721Pausable,
    Ownable,
    AccessControl,
    ERC721Burnable
{
    using Strings for uint256;
    string private _uri = "";
    uint256 private _nextTokenId;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // {_feeDenominator} is defaults to 10000
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v5.0/contracts/token/common/ERC2981.sol#L78
    uint96 public constant royaltyFeeNumeratorLimit = 2000; // 20%

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) ERC721(name_, symbol_) Ownable(_msgSender()) {
        _uri = uri_;
        _grantRole(ADMIN_ROLE, _msgSender());
        setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    modifier onlyAdmin() {
        if (owner() == _msgSender()) {
            _;
        } else {
            require(
                hasRole(ADMIN_ROLE, _msgSender()),
                "Caller is not an administrator"
            );
            _;
        }
    }

    function grantAdmin(address account) public onlyOwner {
        _grantRole(ADMIN_ROLE, account);
    }

    function revokeAdmin(address account) public onlyOwner {
        _revokeRole(ADMIN_ROLE, account);
    }

    function airdrop(address to, string memory uri) public onlyAdmin {
        require(bytes(_baseURI()).length == 0, "Existing baseURI");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function airdropAutoId(address to) public onlyAdmin {
        require(bytes(_baseURI()).length > 0, "Missing baseURI");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenId.toString());
    }

    event baseURIChanged(string newuri);

    function setBaseURI(string memory newuri) public onlyAdmin {
        _uri = newuri;
        emit baseURIChanged(newuri);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyAdmin {
        _setTokenURI(tokenId, uri);
    }

    event DefaultRoyaltyChanged(address receiver, uint96 feeNumerator);

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyAdmin {
        require(
            feeNumerator <= royaltyFeeNumeratorLimit,
            "Royalty fee will exceed limit"
        );
        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltyChanged(receiver, feeNumerator);
    }

    event TokenRoyaltyChanged(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    );

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyAdmin {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltyChanged(tokenId, receiver, feeNumerator);
    }

    event TokenRoyaltyReset(uint256 tokenId);

    function resetTokenRoyalty(uint256 tokenId) public onlyAdmin {
        _resetTokenRoyalty(tokenId);
        emit TokenRoyaltyReset(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            ERC721,
            ERC721Enumerable,
            ERC721URIStorage,
            ERC721Royalty,
            AccessControl
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
