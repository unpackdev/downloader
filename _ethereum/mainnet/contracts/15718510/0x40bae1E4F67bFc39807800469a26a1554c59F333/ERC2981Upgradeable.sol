// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Initializable.sol";
import "./ERC165Upgradeable.sol";
import "./IERC165Upgradeable.sol";

import "./IERC2981Upgradeable.sol";

abstract contract ERC2981Upgradeable is Initializable, IERC2981Upgradeable, ERC165Upgradeable {
    struct Royalty {
        address receiver;
        uint256 bps;
    }

    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // token id -> royalty
    mapping(uint256 => Royalty) public royaltyMap;
    address public defaultRoyaltyReceiver;
    uint256 public defaultRoyaltyBPs;

    event RoyaltySet(uint256 indexed tokenId, address receiver, uint256 royaltyBPs);
    event DefaultRoyaltySet(address receiver, uint256 royaltyBPs);

    modifier onlyValidRoyalty(address _receiver, uint256 _royaltyBPs) {
        require(_receiver != address(0), "_receiver can not be 0x0");
        require(_royaltyBPs <= 10000, "_royaltyBPs should less than 10000");
        _;
    }

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
        uint256 bps = royalty.bps;
        // if this token not set specifically, use default settings
        if (receiver == address(0)) {
            receiver = defaultRoyaltyReceiver;
            bps = defaultRoyaltyBPs;
        }
        // if default is not set either, royaltyAmount is 0
        royaltyAmount = (_salePrice * bps) / 10000;
    }

    function _setTokenRoyalty(
        uint256 _id,
        address _receiver,
        uint256 _royaltyBPs
    ) internal onlyValidRoyalty(_receiver, _royaltyBPs) {
        royaltyMap[_id] = Royalty({receiver: _receiver, bps: _royaltyBPs});
        emit RoyaltySet(_id, _receiver, _royaltyBPs);
    }

    // all tokens that not set specifically can use default royalty
    function _setDefaultRoyalty(address _receiver, uint256 _royaltyBPs)
        internal
        onlyValidRoyalty(_receiver, _royaltyBPs)
    {
        defaultRoyaltyReceiver = _receiver;
        defaultRoyaltyBPs = _royaltyBPs;
        emit DefaultRoyaltySet(_receiver, _royaltyBPs);
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
