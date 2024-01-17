// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**

   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
   ◊◊◊◊◊◊◊◊◊◊ ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊◊ ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊        ◊◊◊◊ ◊◊◊◊  ◊◊◊◊ ◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊ ◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊  ◊◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊ ◊◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊          ◊◊◊◊  ◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊       ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊      ◊◊◊◊◊◊◊◊◊  ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊◊   ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊
      ◊◊◊◊    ◊◊◊◊ ◊◊◊◊  ◊◊◊◊◊◊◊◊◊       ◊◊◊◊◊◊◊   ◊◊◊◊ ◊◊◊◊  ◊◊◊◊  ◊◊◊◊  ◊◊◊◊◊◊◊◊    ◊◊◊◊◊◊◊◊◊  ◊◊◊◊  ◊◊◊◊

 */

import "./Auth.sol";
import "./Strings.sol";
import "./IMetadata.sol";
import "./ITheGardenNFT.sol";

/**
 * @author Fount Gallery
 * @title  Off-chain token metadata module
 * @notice Separate contract for token metadata so it can be upgraded if necessary
 */
contract Metadata is IMetadata, Auth {
    using Strings for uint256;

    /// @notice Address of the NFT contract so it can query the active batch
    address public theGarden;

    /// @notice Base URI for each arrangement
    mapping(uint256 => string) public baseUriForArrangement;

    /// @dev Error for when there's no base URI set for an arrangement
    error NoUriForArrangement();

    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    constructor(address owner_, address admin_) Auth(owner_, admin_) {}

    /* ------------------------------------------------------------------------
       A D M I N
    ------------------------------------------------------------------------ */

    /**
     * @notice Admin function to set The Garden contract address
     * @dev Allows `tokenURI` to get the active arrangement from The Garden
     * @param theGarden_ The Garden contract address
     */
    function setTheGardenAddress(address theGarden_) external onlyOwnerOrAdmin {
        theGarden = theGarden_;
    }

    /**
     * @notice Admin function to set base URI for a given arrangement
     * @param arrangement The arrangement number to set the base URI for
     * @param baseUri The base URI for the arrangement
     */
    function setBaseUriForArrangement(uint256 arrangement, string memory baseUri)
        external
        onlyOwnerOrAdmin
    {
        baseUriForArrangement[arrangement] = baseUri;
    }

    /* ------------------------------------------------------------------------
       R E N D E R
    ------------------------------------------------------------------------ */

    /**
     * @notice Renders token metadata from a base URI
     * @dev Checks with The Garden contract to get the arrangement that the token
     * is from. It then looks up the base URI in this contract. If it's not been set
     * for the arrangement, then it will revert, else it concats the token id
     * on to the base URI for the arrangement.
     *
     * @param id The token to get metadata for
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 arrangement = ITheGardenNFT(theGarden).arrangementForToken(id);
        bytes memory uri = bytes(baseUriForArrangement[arrangement]);
        if (!(uri.length > 0)) revert NoUriForArrangement();
        return string.concat(string(uri), id.toString());
    }
}
