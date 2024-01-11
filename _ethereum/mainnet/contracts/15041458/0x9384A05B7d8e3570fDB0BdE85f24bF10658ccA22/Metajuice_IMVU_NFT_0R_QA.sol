//Contract based on https://docs.openzeppelin.com/contracts/4.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./ERC721URIStorage.sol";

import "./ERC721Royalty.sol";
import "./ERC721Burnable.sol";

import "./Minting.sol";

contract Metajuice_IMVU_NFT_0R_QA is ERC721Royalty, ERC721Burnable, ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    mapping(uint256 => bytes) public blueprints;

    string private baseURI;
    string private baseURI_Ext = "";

    event AssetMinted(address to, uint256 id, bytes blueprint);

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not the contract owner or IMX");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx,
        address _imvu_finance_wallet,
        string memory _baseUri,
        address _royaltyRecipient,
        uint96  _royaltyPercentage)

        ERC721(_name,_symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _imx);
        _setupRole(DEFAULT_ADMIN_ROLE, _imvu_finance_wallet);
        
        _setDefaultRoyalty(_royaltyRecipient, _royaltyPercentage);
        
        baseURI = _baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), '/', tokenId, baseURI_Ext));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mintFor(
        address to,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external onlyAdmin {
        _tokenIds.increment();
        require(quantity == 1, "Mintable: invalid quantity");
        
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        
        uint256 newItemId = _tokenIds.current();
        super._safeMint(to, newItemId);
        
        blueprints[id] = blueprint;
        string memory TokenURI = string(blueprint);
        super._setTokenURI(newItemId, TokenURI);

        emit AssetMinted(to, id, blueprint);

    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}
