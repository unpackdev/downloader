// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./Governable.sol";
import "./ESVSP721Storage.sol";
import "./IESVSP721.sol";

contract ESVSP721 is IESVSP721, Governable, ERC721Enumerable, ESVSP721StorageV1 {
    /// Emitted when `baseTokenURI` is updated
    event BaseTokenURIUpdated(string oldBaseTokenURI, string newBaseTokenURI);

    function initialize(string memory name_, string memory symbol_) external initializer {
        __ERC721_init(name_, symbol_);
        __Governable_init();

        nextTokenId = 1;
    }

    /**
     * @notice Burn NFT
     * @dev Revert if caller isn't the esVSP
     * @param tokenId_ The id of the token to burn
     */
    function burn(uint256 tokenId_) external override {
        require(_msgSender() == address(esVSP), "not-esvsp");
        _burn(tokenId_);
    }

    /**
     * @notice Mint NFT
     * @dev Revert if caller isn't the esVSP
     * @param to_ The receiver account
     */
    function mint(address to_) external override returns (uint256 _tokenId) {
        require(_msgSender() == address(esVSP), "not-esvsp");
        _tokenId = nextTokenId++;
        _mint(to_, _tokenId);
    }

    /**
     * @notice Base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Transfer position (locked/boosted) when transferring the NFT
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override {
        super._beforeTokenTransfer(from_, to_, tokenId_);

        if (from_ != address(0) && to_ != address(0)) {
            esVSP.transferPosition(tokenId_, to_);
        }
    }

    /** Governance methods **/

    /**
     * @notice Update the base token URI
     */
    function setBaseTokenURI(string memory baseTokenURI_) external onlyGovernor {
        emit BaseTokenURIUpdated(baseTokenURI, baseTokenURI_);
        baseTokenURI = baseTokenURI_;
    }

    /**
     * @notice Initialized esVSP contract
     * @dev Called once
     */
    function initializeESVSP(IESVSP esVSP_) external onlyGovernor {
        require(address(esVSP) == address(0), "already-initialized");
        require(address(esVSP_) != address(0), "address-is-null");
        esVSP = esVSP_;
    }
}
