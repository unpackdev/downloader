// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ERC2981.sol";

import "./ERC721A.sol";

/**
 * @dev Implementation of the ERC721A token
 */
contract AIToken is ERC721A, ERC2981, Ownable {
    /// @notice Uri of metadata. Set after deployment.
    string private uri;

    /// @notice address that can burn tokens
    address public burner;

    /// @notice address that can mint tokens
    address public minter;

    /**
     * Sets Royalty receiver
     * @param _royaltyReceiver Address of royalty receiver
     */
    constructor(address _royaltyReceiver) ERC721A("Huxley A.I.", "A.I.") {
        _setDefaultRoyalty(_royaltyReceiver, 500);
    }

    /**
     * @dev Mints a certain amount of Tokens. Sender must be the minter address.
     * @param _account Address that will receive the tokens
     * @param _quantity Amount to mint.
     */
    function mint(address _account, uint256 _quantity) external {
        require(msg.sender == minter, "AI: Not minter");
        _safeMint(_account, _quantity);
    }

    /**
     * Burn a list of tokenIds
     * @dev burner contract should check tokenIds ownership/approval before calling
     * this function since <b>_burn()</b> is not going to check it.
     *
     * @param _tokenIds TokenIds to be burned
     */
    function burn(uint256[] memory _tokenIds) external {
        require(msg.sender == burner, "AI: Not burner");

        for (uint256 i; i < _tokenIds.length; ) {
            uint256 _tokenId = _tokenIds[i];

            // approvalCheck is false.
            _burn(_tokenId, false);
            unchecked {
                ++i;
            }
        }
    }

    /// @dev IP Licenses
    function IPLicensesIncluded() external pure returns (string memory) {
        return "Personal Use, Commercial Display, Merchandising";
    }

    /// @notice Set base uri. OnlyOwner can call it.
    function setBaseURI(string memory _value) external onlyOwner {
        uri = _value;
    }

    /// @notice Returns base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /// @notice Set address of Burner
    function setBurner(address _addr) external onlyOwner {
        burner = _addr;
    }

    /// @notice Set address of Minter
    function setMinter(address _addr) external onlyOwner {
        minter = _addr;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 numerator
    ) external onlyOwner {
        ERC2981._setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}
