// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./WiVWineNFT.sol";

contract WiV is ERC721, ERC721Enumerable, ERC721URIStorage, AccessControl, ReentrancyGuard, WiVWineNFT {
    using Counters for Counters.Counter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("WiV", "WiV") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /**
        Minting lot - wine type value should be within the enum list
     */
    function mintLot(uint256 _process_id,
                     address _owner_address,
                     string memory _brand_name,
                     string memory _region,
                     uint256 _wine_type,
                     uint256 _year,
                     string memory _production_country,
                     string memory _producer,
                     uint256 _bottle_quantity,
                     string memory _uri ) public virtual override onlyRole(MINTER_ROLE) nonReentrant {
        if (_wine_type > uint(Wine_Type.OTHER)) {
            revert MintingError(_process_id, Strings.toString(_wine_type));
        }
        _safeMint(_owner_address, _tokenIdCounter.current());

        Lot memory tmp_lot = Lot(_brand_name,
                                 _region,
                                 Wine_Type(_wine_type),
                                 _year,
                                 _production_country,
                                 _producer,
                                 true,
                                 _bottle_quantity);
        lots[_tokenIdCounter.current()] = tmp_lot;
        _setTokenURI(_tokenIdCounter.current(), _uri);

        emit LotMinted(_tokenIdCounter.current(), _process_id);
        // increment after event has been emitted
        _tokenIdCounter.increment();
    }

    /**
        Burning lot either to unmint the wine as an NFT or for redeeming of the wine.
     */
    function burnLot( uint256 _product_id, uint256 _burn_type) public virtual override nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _product_id), "burnLot: caller is not owner nor approved");

        if (_burn_type > uint(Burn_Type.REDEEM)) {
            revert BurningError(_product_id, Strings.toString(_burn_type));
        }

        _burn(_product_id);
        delete lots[_product_id];

        if (_burn_type == uint(Burn_Type.REDEEM)) {
            emit LotRedeemed(_product_id);    
        } else {
            emit LotDestroyed(_product_id);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://wivstorage.azureedge.net/wine-metadata/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
