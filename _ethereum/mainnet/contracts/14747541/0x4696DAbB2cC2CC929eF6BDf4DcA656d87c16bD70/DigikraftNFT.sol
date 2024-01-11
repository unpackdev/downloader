// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract DigikraftNFT is RoyaltiesV2Impl, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdtracker;

    constructor() ERC721("Digikraft.io", "DGK") {}

    function mint(address _to, string memory tokenURI) public {
        super._mint(_to, _tokenIdtracker.current());
        super._setTokenURI(_tokenIdtracker.current(), tokenURI);
        _tokenIdtracker.increment();
    }

    function mint(
        address _to,
        string memory tokenURI,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) public {
        super._mint(_to, _tokenIdtracker.current());
        super._setTokenURI(_tokenIdtracker.current(), tokenURI);
        setRoyalties(
            _tokenIdtracker.current(),
            _royaltiesRecipientAddress,
            _percentageBasisPoints
        );
        _tokenIdtracker.increment();
    }

    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];

        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }

        return (address(0), 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }
}
