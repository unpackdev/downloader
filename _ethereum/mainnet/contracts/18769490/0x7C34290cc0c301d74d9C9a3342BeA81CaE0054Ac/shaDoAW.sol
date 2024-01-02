//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./ERC721AQueryable.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";

/*
--------------------------------------------------------------------------------------------
              ██                      ████████                    ████████    ██        ██ 
    ██████    ██            ██████    ██      ██      ██████    ██        ██  ██        ██ 
  ██          ████████            ██  ██        ██  ██      ██  ██        ██  ██        ██ 
    ██████    ██      ██    ████████  ██        ██  ██      ██  ████████████  ██        ██ 
          ██  ██      ██  ██      ██  ██      ██    ██      ██  ██        ██  ██  ████  ██ 
  ████████    ██      ██    ████████  ████████        ██████    ██        ██    ██    ██  



██████████████  ██████████████████████        ████████████████████        ████  ████████  ██
████      ████  ████████████      ████  ██████  ██████      ████  ████████  ██  ████████  ██
██  ██████████        ████████████  ██  ████████  ██  ██████  ██  ████████  ██  ████████  ██
████      ████  ██████  ████        ██  ████████  ██  ██████  ██            ██  ████████  ██
██████████  ██  ██████  ██  ██████  ██  ██████  ████  ██████  ██  ████████  ██  ██    ██  ██
██        ████  ██████  ████        ██        ████████      ████  ████████  ████  ████  ████
--------------------------------------------------------------------------------------------

shaDoAW
By Joan Heemskerk
Presented by Folia.app
*/

/// @title shaDoAW
/// @notice https://doaw.folia.app
/// @author @okwme
/// @dev ERC721A contract for shaDoAW. External upgradeable metadata.

contract shaDoAW is ERC721AQueryable, Ownable {
    address public metadata;

    constructor(address metadata_) ERC721A("shaDoaW", "shaDoAW") {
        metadata = metadata_;
    }

    /// @dev Allows minting by sending directly to the contract.
    fallback() external payable {
        revert("NO DIRECT SEND");
    }

    /// @dev Allows minting by sending directly to the contract.
    receive() external payable {
        revert("NO DIRECT SEND");
    }

    /// @dev Overwrites the _startTokenId function from ERC721A so that the first token id is 1
    /// @return uint256 the id of the first token
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    /// @dev overwrites the tokenURI function from ERC721
    /// @param id the id of the NFT
    /// @return string the URI of the NFT
    function tokenURI(
        uint256 id
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        return Metadata(metadata).getSecondMetadata(id);
    }

    /**
     * @dev Mints a specified number of tokens and assigns them to the specified addresses.
     * Can only be called by the contract owner.
     *
     * @param to An array of addresses to which the tokens will be minted.
     */
    function adminMint(address[] memory to) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], 1);
        }
    }

    /// @dev set the metadata address as called by the owner
    /// @param metadata_ the address of the metadata contract
    function setMetadata(address metadata_) public onlyOwner {
        require(metadata_ != address(0), "NO ZERO ADDRESS");
        metadata = metadata_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    /// @dev set the royalty percentage as called by the owner
    /// @param interfaceId the interface id
    /// @return bool whether the interface is supported
    /// @notice ERC2981, ERC721A, IERC721A are overridden to support multiple interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
