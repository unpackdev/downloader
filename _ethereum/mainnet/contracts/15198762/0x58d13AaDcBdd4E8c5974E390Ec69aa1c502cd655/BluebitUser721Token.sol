// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./Context.sol";
import "./Counters.sol";
import "./AccessControl.sol";

contract BlueBitUser721Token is
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721URIStorage,
    AccessControl
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    string private baseTokenURI;
    address public owner;
    mapping(uint256 => TokenRoyalty) private tokenRoyalty;

    struct TokenRoyalty {
        uint96[] royaltyPermiles;
        address[] receivers;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Pack(uint256[] tokenIds);
    event RemovedFromPack(uint256[] tokenIds);

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI
    ) ERC721(name, symbol) {
        baseTokenURI = _baseTokenURI;
        owner = _msgSender();
        _setupRole("ADMIN_ROLE", msg.sender);
        _tokenIdTracker.increment();
    }

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory _baseTokenURI) external onlyRole("ADMIN_ROLE") {
        baseTokenURI = _baseTokenURI;
    }

    function mint(
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers
    ) external virtual onlyRole("ADMIN_ROLE") returns (uint256 _tokenId) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _tokenId = _tokenIdTracker.current();
        _mint(_msgSender(), _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        _setTokenRoyalty(_tokenId, _royaltyFee, _receivers);
        _tokenIdTracker.increment();
        return _tokenId;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        _resetTokenRoyalty(tokenId);
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function royaltyInfo(
        uint256 _tokenId, 
        uint256 price) 
        external 
        view 
        returns(uint96[] memory, address[] memory, uint256) {
        require(_exists(_tokenId),"ERC721Royalty: query for nonexistent token");
        require(price > 0, "ERC721Royalty: amount should be greater than zero");
        uint96[] memory royaltyFee = new uint96[](tokenRoyalty[_tokenId].royaltyPermiles.length); 
        address[] memory receivers = tokenRoyalty[_tokenId].receivers; 
        uint256 royalty;
        uint96[] memory _royaltyFees = tokenRoyalty[_tokenId].royaltyPermiles;
        for( uint96 i = 0; i < _royaltyFees.length; i++) {
            royaltyFee[i] = uint96(price * _royaltyFees[i] / 1000);
            royalty += royaltyFee[i];        
        }

        return (royaltyFee, receivers, royalty); 

    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _setTokenRoyalty(
        uint256 _tokenId,
        uint96[] calldata royaltyFeePermiles,
        address[] calldata receivers
    ) internal {
        require(royaltyFeePermiles.length == receivers.length,"ERC721Royalty: length should be same");
        tokenRoyalty[_tokenId] = TokenRoyalty(royaltyFeePermiles, receivers);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete tokenRoyalty[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}