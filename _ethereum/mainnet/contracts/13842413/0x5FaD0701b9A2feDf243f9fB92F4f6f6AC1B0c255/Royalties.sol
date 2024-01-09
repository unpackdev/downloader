// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Reservable.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract Royalties is Reserveable {
    /**
     * @notice struct made up of two properties
     * account: address of royalty receiver
     * value: royalty percentage, where 10000 = 100% and 100 = 1%
     */
    LibPart.Part internal royalties;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /**
     * @dev set royalties, only one address can receive the royalties
     * @param _royalties new royalty struct to be set
     */
    function setRoyalties(LibPart.Part memory _royalties) public onlyOwner {
        require(_royalties.account != address(0x0), "RT:001");
        require(_royalties.value >= 0 && _royalties.value < 10000, "RT:002");
        royalties = _royalties;
    }

    /**
     * @dev see {EIP-2981}
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "RT:003");
        LibPart.Part storage _royalties = royalties;
        if (_royalties.account != address(0) && _royalties.value != 0) {
            return (
                _royalties.account,
                (_salePrice * _royalties.value) / 10000
            );
        }
        return (address(0), 0);
    }

    // for rarible
    /**
     * @dev returns royalties details, implemented for Rarible
     * @param id token id
     * @return array of royalty struct
     */
    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory)
    {
        require(_exists(id), "RT:003");
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        LibPart.Part storage _royaltiesRef = royalties;
        _royalties[0].account = _royaltiesRef.account;
        _royalties[0].value = _royaltiesRef.value;
        return _royalties;
    }

    /**
     * @dev see {EIP-165}
     * @param interfaceId interface id of implementation
     * @return true, if implements the interface else false
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES ||
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }
}
