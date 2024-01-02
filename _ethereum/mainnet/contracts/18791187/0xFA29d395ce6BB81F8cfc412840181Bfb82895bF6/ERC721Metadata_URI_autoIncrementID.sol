/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./ERC721.sol";
import "./DecodeTokenURI.sol";
import "./Strings.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721Metadata_URI_autoIncrementID is ERC721 {
    using DecodeTokenURI for bytes;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    address private _deployedContract;

    /**
     * @dev Hardcoded base URI in order to remove the need for a constructor, it
     * can be set anytime by an admin
     * @dev baseTokenURI MUST be set to something else for generative art implementations as the storage is centralized
     * (multisig).
     */
    string internal _baseTokenURI;

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId));

        if (_deployedContract == address(0)) {
            return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
        } else {
            return string(
            abi.encodePacked(
                _baseTokenURI, // Ensure _baseTokenURI ends with '/'
                Strings.toHexString(uint256(uint160(_deployedContract)), 20),
                "/",
                Strings.toString(_tokenId)
            )
        );
        }

        
    }

    /**
     * @notice Optional function to set the base URI
     * @dev child contract MAY require access control to the external function
     * implementation
     * @param baseURI_ string representing the base URI to assign
     * @param deployedContract_ address of the deployed contract, set to address(0) if not applicable to baseURI, see tokenURI()
     */
    function _setBaseURI(string memory baseURI_, address deployedContract_) internal {
        _baseTokenURI = baseURI_;


        _deployedContract = deployedContract_;

    }


}
