// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";
import "./NiftyOptions.sol";



// Interfaces
import "./IERC721Metadata.sol";
import "./IERC1155MetadataURI.sol";

contract URIFetcher is Initializable, OwnableUpgradeable {
    
    using Strings for uint256;
    
    string internal _baseURI;

    struct TokenBundle {
        uint8[] types;
        address[] addresses;
        uint256[] ids;
        uint256[] amounts;
    }

    function initialize(string calldata _initialContractURI) external initializer {
        __Ownable_init_unchained();
        _baseURI = _initialContractURI;
    }

    /**
     * @notice Sets the Option contract metadata URI.
     * example:  _baseURI ="https://api.niftyoptions.org/metadata/"
     *
     * Requirements:
     *  - {_msgSender} must be the owner
     */
    function setBaseURI(string calldata _uri) external onlyOwner {
        _baseURI = _uri;
    }

    /**
     * @notice Fetches the Option contract metadata URI.
     * @return Contract URI hash
     */
    function fetchContractURI() external view returns (string memory) {
        return string(abi.encodePacked(_baseURI, "contract"));
    }

    /**
     * @notice Fetches the URI of the first token that is in the {Option.TokenBundle}
     * @param optionId The ID of the option to query
     * @return String of the option URI
     */
    function fetchOptionURI(uint256 optionId) public view returns (string memory) {
      
        return string(abi.encodePacked(_baseURI, "token/", optionId.toString(),".json" )); 
    }
 
}
