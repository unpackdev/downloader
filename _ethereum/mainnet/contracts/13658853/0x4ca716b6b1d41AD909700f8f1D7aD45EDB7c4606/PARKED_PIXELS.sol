//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./RoyaltiesV2.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract PARKED_PIXELS is ERC721, Ownable, RoyaltiesV2 {
    uint256 public totalSupply;
    string private baseURIOverride;
    LibPart.Part[] public royalties;

    constructor(
        uint256 _totalSupply,
        address _developer,
        address _artist,
        string memory _baseURIOverride
    ) ERC721("PARKED PIXELS", "PARKED PIXELS") {
        baseURIOverride = _baseURIOverride;
        totalSupply = _totalSupply;
        _mint(_developer, 0);
        for (uint256 i = 1; i < totalSupply; i++) {
            _mint(_artist, i);
        }

        LibPart.Part memory ownerRoyalty;
        ownerRoyalty.value = 900;
        ownerRoyalty.account = payable(_artist);

        LibPart.Part memory developerRoyalty;
        developerRoyalty.value = 100;
        developerRoyalty.account = payable(_developer);
        royalties.push(ownerRoyalty);
        royalties.push(developerRoyalty);

        transferOwnership(_artist);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURIOverride;
    }

    function getRaribleV2Royalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return royalties;
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
        return super.supportsInterface(interfaceId);
    }
}
