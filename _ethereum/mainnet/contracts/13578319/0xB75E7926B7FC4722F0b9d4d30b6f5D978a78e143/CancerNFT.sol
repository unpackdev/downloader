//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./ERC165Storage.sol";
import "./IERC165.sol";
import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./Splitter.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}


contract CancerNFT is ERC721, IERC2981, Ownable {
    // ERC165
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    mapping(bytes4 => bool) private _supportedInterfaces;


    // 100 max
    uint8 public royaltyFraction = 10; // 10% initially

    address public royaltyDestination;

    string public uri;

    uint256 public collectionSize;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _registerInterface(_INTERFACE_ID_ERC2981);
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        transferOwnership(_msgSender());
        royaltyDestination = address(new Splitter(_msgSender()));
    }

    function setRoyaltyDestination(address royaltyDestination_) external onlyOwner {
        royaltyDestination = royaltyDestination_;
    }

    function setRoyaltyFraction(uint8 royaltyFraction_) external onlyOwner {
        require(royaltyFraction_ <= 50, "50% max royalty");
        royaltyFraction = royaltyFraction_;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, collectionSize);
            collectionSize++;
        }
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (royaltyDestination, uint256(_salePrice * royaltyFraction / 100));
    }

    function setURI(string memory uri_) external onlyOwner {
        uri = uri_;
    }


    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
