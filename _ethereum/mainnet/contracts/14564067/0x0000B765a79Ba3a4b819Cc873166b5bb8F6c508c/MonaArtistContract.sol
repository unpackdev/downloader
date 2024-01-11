// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";

contract MonaArtistContract is Initializable, IERC2981, ERC721 {

    uint private EIP2981RoyaltyPercent;

    address private EIP2981RoyaltyAddress;

    address public monaGalleryAddress;

    address public newContract;

    function initialize(
        uint royalty, 
        address royaltyAddress,
        address _monaGalleryAddress,
        address _openseaProxyRegistry,
        string memory name_
    ) external initializer {
        __Ownable_init();
        __ERC721_init(_openseaProxyRegistry, name_);
        __MonaArtistContract_init(royalty, royaltyAddress, _monaGalleryAddress);
    }

    function __MonaArtistContract_init(
        uint royalty,
        address royaltyAddress,
        address _monaGalleryAddress
    ) internal onlyInitializing {
        require(royalty <= 1000, "Can't go over 10 percent royalty!");
        require(royaltyAddress != address(0), "Royalty address cannot be null!");
        require(_monaGalleryAddress != address(0), "Mona exchange address cannot be null!");

        EIP2981RoyaltyAddress = royaltyAddress;
        EIP2981RoyaltyPercent = royalty;
        monaGalleryAddress = _monaGalleryAddress;
    }

    function mint(string memory uri) external onlyOwner {
        _mint(monaGalleryAddress, uri);
    }

    function _burnToMigrate(uint tokenId) external {
        require(msg.sender == newContract);
        _burn(tokenId);
    }

    function setMonaGalleryAddress(address addr) external onlyOwner {
        monaGalleryAddress = addr;
    }

    function setNewContractAddress(address addr) external onlyOwner {
        newContract = addr;
    }

    /**
     * @notice returns royalty info for EIP2981 supporting marketplaces
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint tokenId, uint salePrice) external view override returns(address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Royality querry for non-existant token!");
        return(owner(), salePrice * EIP2981RoyaltyPercent / 10000);
    }

    /**
     * @notice sets the royalty percentage for EIP2981 supporting marketplaces
     * @dev percentage is in bassis points (parts per 10,000).
            Example: 5% = 500, 0.5% = 50 
     * @param amount - percent amount
     */
    function setRoyaltyPercent(uint256 amount) external onlyOwner {
        require(amount <= 1000, "Can't go over 10 percent!");
        EIP2981RoyaltyPercent = amount; 
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokensOfOwner(address owner) external view returns(uint[] memory) {
        uint[] memory tokens = new uint[](_balances[owner]);
        uint y = totalSupply + 1;
        uint x;

        for (uint i = 1; i < y; i++) {
            if (ownerOf(i) == owner) {
                tokens[x] = i;
                x++;
            }
        }

        return tokens;
    }
}