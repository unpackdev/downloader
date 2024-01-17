// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721AUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

import "./TokenMetadata.sol";
import "./PrimarySale.sol";
import "./Royalty.sol";

abstract contract BaseWhitelist is
    TokenMetadata,
    PrimarySale,
    Royalty,
    ERC2771ContextUpgradeable,
    ERC721AUpgradeable
{
    // URI for the contract metadata
    string public contractURI;

    // total collection size
    uint256 public totalQuantity;

    // tracks the number of NFTs minted on public sale
    uint256 supply;

    // public sale status
    bool public isSaleActive;

    /**===========================================================================
                                    Setter Functions
    ============================================================================== */
    function _setOwnership(address owner) internal onlyInitializing {
        _transferOwnership(owner);
    }

    function _setSaleState() internal onlyInitializing {
        isSaleActive = true;
    }

    function setContractURI(string memory uri) external onlyOwner {
        contractURI = uri;
    }

    function setName(string memory name) external onlyOwner {
        ERC721AStorage.layout()._name = name;
    }

    function setSymbol(string memory symbol) external onlyOwner {
        ERC721AStorage.layout()._symbol = symbol;
    }

    function setSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    /***********************************************************************
                                OVERRIDE FUNCTIONS
     *************************************************************************/

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (delayReveal && isRevealed == false) {
            return previewURI;
        }
        return _actualTokenURI(tokenId);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }

    /***********************************************************************
                                INTERNAL FUNCTIONS
     *************************************************************************/

    function _refundIfOver(uint256 price) internal {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            (bool success, ) = _msgSender().call{value: msg.value - price}("");
            require(success, "Payment failed");
        }
    }

    function _actualTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length != 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        "/",
                        _toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }
}
