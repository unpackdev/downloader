//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./LetsgoNFTBase.sol";

contract LetsgoNFT is ERC721URIStorage, Ownable, LetsgoNFTBase {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes4 _interfaceId = 0xce77acc3;
    mapping(uint256 => uint256) private _royalties;
    mapping(uint256 => address) private _creators;
    mapping(uint256 => AddreessWithPercent[]) private _coCreators;

    constructor() ERC721("LetsgoNFT", "LET") {}

    function mint(uint256 royalty, string memory tokenURI) public returns(uint256) {
        require(
            royalty <= mantissa / 2,
            "mint: royalty should be less or equal to 50%"
        );
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _royalties[tokenId] = royalty;
        _creators[tokenId] = msg.sender;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    function mintExtended(
        uint256 royalty,
        string memory tokenURI,
        AddreessWithPercent[] memory coCreators      
    )  external returns(uint256) {
        this.validateCoCreators(coCreators);
    
        uint256 tokenId = mint(royalty, tokenURI);

        for (uint256 i = 0; i < coCreators.length; i++) {
            _coCreators[tokenId].push(coCreators[i]);
        }
      
        return tokenId;
    }

    function getRoyalty(uint256 tokenId) external view returns (uint256) {
        return _royalties[tokenId];
    }

    function getCreator(uint256 tokenId) external view returns (address) {
        return _creators[tokenId];
    }

    function getCoCreators(uint256 tokenId) external view returns (AddreessWithPercent[] memory) {
        return _coCreators[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == _interfaceId || super.supportsInterface(interfaceId);
    }
}
