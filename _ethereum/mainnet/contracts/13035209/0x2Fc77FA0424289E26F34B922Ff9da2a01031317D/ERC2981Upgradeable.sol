// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165Upgradeable.sol";

import "./IERC2981Upgradeable.sol";

contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    event RoyaltySet(uint256 indexed tokenId, Royalty royalty);

    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    struct Royalty {
        address receiver;
        uint256 bps;
    }

    // token id -> royalty
    mapping(uint256 => Royalty) public royaltyMap;

    function __ERC2981_init() internal initializer {
        __ERC165_init_unchained();
        __ERC2981_init_unchained();
    }

    function __ERC2981_init_unchained() internal initializer {}

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = royaltyMap[_tokenId];
        receiver = royalty.receiver;
        royaltyAmount = (_salePrice * royalty.bps) / 10000;
    }

    function _setRoyalty(uint256 _id, Royalty memory _royalty) internal {
        //        require(_royalty.account != address(0), "Recipient should be present");
        require(_royalty.bps <= 10000, "Royalty bps should less than 10000");
        royaltyMap[_id] = _royalty;
        emit RoyaltySet(_id, _royalty);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * ERC165 bytes to add to interface array - set in parent contract
     * implementing this standard
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     * _registerInterface(_INTERFACE_ID_ERC2981);
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC2981Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    uint256[46] private __gap;
}
