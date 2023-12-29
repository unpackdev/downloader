// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

//  **     **  **       **                    ****   **
// /**    /** /**      //                    /**/   /**
// /**    /** /**       **  ******  ******  ****** ******
// /**    /** /******  /** **////  **////**///**/ ///**/
// /**    /** /**///** /**//***** /**   /**  /**    /**
// /**    /** /**  /** /** /////**/**   /**  /**    /**
// //*******  /******  /** ****** //******   /**    //**
// ///////    /////    // //////   //////    //      //

import "./AccessControl.sol";
import "./EIP712.sol";
import "./ERC721Psi.sol";
import "./ERC721PsiAddressData.sol";
import "./ERC2981.sol";
import "./Errors.sol";
import "./IAccessControl.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IGenesisBase.sol";
import "./MintData.sol";
import "./Ownable.sol";

/**
 * @title GenesisBase
 *
 * @dev GenesisBase implements ERC721 and should be used as a base
 * for GenesisPFP and the other upcoming Genesis contracts
 */
abstract contract GenesisBase is IGenesisBase, ERC721PsiAddressData, ERC2981, EIP712, Ownable, AccessControl {
    // =============================================================
    //                   VARIABLES
    // =============================================================

    /// @notice baseURI for computing tokenURI
    string public baseURI;

    // =============================================================
    //                   MAPPINGS
    // =============================================================

    /// @notice Mapping for an address to a bool
    /// @notice Tracks if a user minted its tokens
    mapping(bytes32 => bool) public minted;

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisBase
     */
    function setBaseURI(string calldata _uri) external override onlyOwner {
        if (bytes(baseURI).length > 0) {
            revert Errors.BaseURIAlreadyInitialized();
        }
        baseURI = _uri;
    }

    /**
     * @inheritdoc IGenesisBase
     */
    function updateDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =============================================================
    //                   PUBLIC
    // =============================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Psi, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // =============================================================
    //                   INTERNAL
    // =============================================================

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
