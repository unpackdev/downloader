//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CountersUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./CheekyCorgiBase.sol";

contract CheekyCorgiAdmin is CheekyCorgiBase
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;
    
    // ---------------------- ADMIN FUNCTIONS -----------------------
    /// @dev Set some NFTs aside
    function reserve(uint256 _count) external onlyAdmin {
        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(_msgSender(), newItemId);
        }
    }

    function setYieldToken(address _YieldToken) external onlyAdmin {
        YIELD_TOKEN = IYieldTokenUpgradeable(_YieldToken);
        // set sploot address
        PAYMENT_METHODS[3].token = _YieldToken;
    }

    function setProvenanceHash(string memory provenanceHash) external onlyAdmin {
        PROVENANCE_HASH = provenanceHash;
    }

    function updateBaseURI(string memory newURI) external onlyAdmin {
        _setBaseURI(newURI);
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyAdmin {
        maxSupply = _maxSupply;
    }

    function updateQuantity(uint256 _maxPrivateQuantity, uint256 _maxPublicQuantity) external onlyAdmin {
        maxPrivateQuantity = _maxPrivateQuantity;
        maxPublicQuantity = _maxPublicQuantity;
    }

    function updatePrice(uint256 _privatePrice, uint256 _publicPrice) external onlyAdmin {
        privatePrice = _privatePrice;
        publicPrice = _publicPrice;
    }

    /**
    ===============================================================================
    [DANGER] please do not confuse the _tokenIndex, and input correctly like below:
    ===============================================================================
    _tokenIndex: 
        0: USDT
        1: USDC
        2: SHIBA
        3: SPLOOT
    */
    function updatePriceOfToken(uint256 _tokenIndex, uint256 _publicPrice) external onlyAdmin {
        require(_tokenIndex < 4, "Unsupported token");
        PAYMENT_METHODS[_tokenIndex].publicPrice = _publicPrice * (10**PAYMENT_METHODS[_tokenIndex].decimals);
    }

    ///  @dev Pauses all token transfers.
    function pause() external virtual onlyAdmin {
        _pause();
    }

    /// @dev Unpauses all token transfers.
    function unpause() external virtual onlyAdmin {
        _unpause();
    }

    function updateWhitelist(address[] calldata whitelist) external onlyAdmin {
        for (uint256 i = 0; i < whitelist.length; i++) {
            _privateSaleWhitelist[whitelist[i]] = true;
        }
    }

    function updateUcdHolders(address[] calldata _holders) external onlyAdmin {
        for (uint256 i = 0; i < _holders.length; i++) {
            claimableUcdHolders[_holders[i]] = true;
        }
    }

    function withdrawToTreasury() external onlyTreasury {
        (bool success, ) = TREASURY.call{value: address(this).balance}("");
        for (uint256 i = 0; i < 3; i++) {
            IERC20 _token = IERC20(PAYMENT_METHODS[i].token);
            _token.transfer(
                TREASURY, 
                _token.balanceOf(address(this))
            );
        }
        require(success);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setBaseURI(string memory _baseTokenURI) internal virtual {
        baseTokenURI = _baseTokenURI;
    }
}
