pragma solidity 0.8.12;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";


//*********************************************************************//
// --------------------------- custom error ------------------------- //
//*********************************************************************//
error ITEM_DOES_NOT_EXIST();


/**
@title Privacy Collection - Lot 00 Drop Contract
*/
contract ArtWork is ERC721, IERC2981, Ownable {

    /// @notice Primary Artist Address.
    address public constant artist = 0x8ba7E0BE0460035699BAddD1fD1aCCb178702348;

    /// @notice Total Items.
    // I am not sure why this variable is being used, seems like a waste of gas.
    uint256 public constant totalItems = 11;

    /// @notice Secondary sales reward splitter contract address.
    address private secondarySalesSplitter;

    /// @notice Poem Seed Address.
    address public poemSeed;

    /**
     * @notice Constructor used to mint all nft's to the artist
     **/
    constructor(address _secondarySalesSplitter) ERC721("Privacy Collection - Lot 00", "PrivacyLot00") {
        secondarySalesSplitter = _secondarySalesSplitter;
        for(uint i = 0; i < totalItems; i++) {
            _mint(artist, i);
        }
    }

    string public constant baseURL = "https://ipfs.io/ipfs/QmQxkK3c8Z85M5jAr2hUega4PkKY3Qd1cNifg3zfwTdDiD/";
    string[11] public metadataURL = 
       ["0.json",
        "1.json",
        "2.json",
        "3.json",
        "4.json",
        "5.json",
        "6.json",
        "7.json",
        "8.json",
        "9.json",
        "10.json"];

    /*
     * @notice returns the tokenURI of the nft
     * @param _tokenId token id
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (!_exists(_tokenId)) {
            revert ITEM_DOES_NOT_EXIST();
        }
        return string(abi.encodePacked(baseURL, metadataURL[_tokenId]));
    }

    /*
     * @notice Sets Poem Seed which has a big reveal.
     * @param _poemSeed poem seed registry address
     */
    function setPoemSeed(address _poemSeed) external onlyOwner {
        poemSeed = _poemSeed;
    }


    /** @dev EIP2981 royalties implementation. */

    /**
     * @notice Internal function Allows to update the royalty address
     * @param newRecipient New royalty address
     */
    function _setRoyalties(address newRecipient) internal {
        secondarySalesSplitter = newRecipient;
    }

    /**
     * @notice Allows to update the royalty address
     * @param newRecipient New royalty address
     */
    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    /**
     * @notice Return royalty info
     * @param _tokenId Token Id
     * @param _salePrice Sales price
     * @return receiver royalty receiver address
     * @return royaltyAmount Royalty Amount
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {   // 15 % royalty
        return (secondarySalesSplitter, (_salePrice * 15) / 100);
    }

    // EIP2981 standard Interface return. Adds to ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}
