// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./AccessControl.sol";

contract BlueBitUser1155Token is
    Context,
    ERC1155Burnable,
    ERC1155Supply,
    AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdTracker;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => TokenRoyalty) private tokenRoyalty;

    string private baseTokenURI;
    string private _name;
    string private _symbol;
    address public owner;

    struct TokenRoyalty {
        uint96[] royaltyPermiles;
        address[] receivers;
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event BaseURIChanged(string indexed uri, string indexed newuri);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseTokenURI
    ) ERC1155(_baseTokenURI) {
        baseTokenURI = _baseTokenURI;
        owner = _msgSender();
        _setupRole("ADMIN_ROLE", msg.sender);
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _tokenIdTracker.increment();
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /** @dev change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

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

    function setBaseURI(string memory uri_) external onlyRole("ADMIN_ROLE") returns (bool) {
        emit BaseURIChanged(baseTokenURI, uri_);
        baseTokenURI = uri_;
        return true;
    }

    function mint(
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        uint256 supply
    ) external virtual onlyRole("ADMIN_ROLE") returns (uint256 _tokenId) {
        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _tokenId = _tokenIdTracker.current();
        _mint(_msgSender(), _tokenId, supply, "");
        _tokenURIs[_tokenId] = _tokenURI;
        _setTokenRoyalty(_tokenId, _royaltyFee, _receivers);
        _tokenIdTracker.increment();
        return _tokenId;
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            exists(tokenId),
            "ERC1155URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        // If there is no base URI, return the token URI.
        if (bytes(baseTokenURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(baseTokenURI, _tokenURI));
        }
        return
            bytes(baseTokenURI).length > 0
                ? string(abi.encodePacked(baseTokenURI, tokenId.toString()))
                : "";
    }
    function royaltyInfo(
        uint256 _tokenId, 
        uint256 price) 
        external 
        view 
        returns(uint96[] memory, address[] memory, uint256) {
        require(exists(_tokenId),"ERC721Royalty: query for nonexistent token");
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address _operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(_operator, from, to, ids, amounts, data);
    }
}