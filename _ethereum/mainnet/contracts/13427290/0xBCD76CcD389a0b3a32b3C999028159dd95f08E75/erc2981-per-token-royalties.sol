// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ierc2981-royalties.sol";
import "./supports-interface.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
contract ERC2981PerTokenRoyalties is IERC2981Royalties, SupportsInterface {

    /**
    * @dev This is where the info about the royalty resides
    * @dev recipient is the address where the royalties should be sent to.
    * @dev value is the percentage of the sale value that will be sent as royalty.
    * @notice "value" will be expressed as an unsigned integer between 0 and 1000. 
    * This means that 10000 = 100%, and 1 = 0.01%
    */
    struct Royalty {
        address recipient;
        uint256 value;
    }

    /**
    * @dev the data structure where the NFT id points to the Royalty struct with the
    * corresponding royalty info.
    */
    mapping(uint256 => Royalty) internal idToRoyalties;

    constructor(){
        supportedInterfaces[0x2a55205a] = true; // ERC2981
    }

    /** 
    * @dev Sets token royalties
    * @param id the token id fir which we register the royalties
    * @param recipient recipient of the royalties
    * @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    */
    function _setTokenRoyalty(
        uint256 id,
        address recipient,
        uint256 value
    ) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');

        idToRoyalties[id] = Royalty(recipient, value);
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = idToRoyalties[_tokenId];
        return (royalty.recipient, (_salePrice * royalty.value) / 10000);
    }
}