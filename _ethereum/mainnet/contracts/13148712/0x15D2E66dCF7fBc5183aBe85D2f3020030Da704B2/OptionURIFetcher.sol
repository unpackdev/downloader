// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./Option.sol";

// Interfaces
import "./IERC721Metadata.sol";
import "./IERC1155MetadataURI.sol";

contract OptionURIFetcher is Initializable, OwnableUpgradeable {
    Option public option;
    string internal _contractURI;

    function initialize(
        address optionAddress,
        string calldata _initialContractURI
    ) external initializer {
        __Ownable_init_unchained();
        option = Option(optionAddress);
        _contractURI = _initialContractURI;
    }

    /**
     * @notice Sets the Option contract metadata URI.
     *
     * Requirements:
     *  - {_msgSender} must be the owner
     */
    function setContractURI(string calldata _uri) external onlyOwner {
        _contractURI = _uri;
    }

    /**
     * @notice Fetches the Option contract metadata URI.
     * @return Contract URI hash
     */
    function fetchContractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Fetches the URI of the first token that is in the {Option.TokenBundle}
     * @param optionId The ID of the option to query
     * @return String of the option URI
     */
    function fetchOptionURI(uint256 optionId) public view returns (string memory) {
        Option.TokenBundle memory bundle = option.bundleOf(optionId);
        address underlying = bundle.addresses[0];
        uint256 underlyingId = bundle.ids[0];

        try IERC721Metadata(underlying).tokenURI(underlyingId) returns (string memory _uri) {
            return _uri;
        } catch (bytes memory) {
        }

        try IERC1155MetadataURI(underlying).uri(underlyingId) returns (string memory _uri) {
            return _uri;
        } catch (bytes memory) {
        }

        return "";
    }
}
