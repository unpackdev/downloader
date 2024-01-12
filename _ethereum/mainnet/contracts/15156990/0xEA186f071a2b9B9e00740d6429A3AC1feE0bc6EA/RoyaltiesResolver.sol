//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC721.sol";
import "./Ownable.sol";

contract RoyaltiesResolver is Ownable {

    event RoyaltiesConfigured(address indexed recipient, uint256 numerator, uint256 denominator);

    // Royalties
    address public royaltyRecipient;
    uint256 public royaltyNumerator;
    uint256 public royaltyDenominator;

    // Errors
    string private constant WRONG_NUMBERS = "Wrong input";

    /**
     * Constructor, no special features.
     */
    constructor() {
    }

    /**
     * Returns a royalty amount. This is a fixed
     * percentage of a sale price received by the receipient.
     */
    function royaltyInfo(uint256 /* _tokenId */, uint256 _salePrice) 
    public view returns (address, uint256) {
        address receiver = royaltyRecipient;
        uint256 royaltyAmount = _salePrice * royaltyNumerator / royaltyDenominator;
        return (receiver, royaltyAmount);
    }

    /**
     * An owner method for configuring royalties.
     */
    function configureRoyalties(address recipient, uint256 numerator, 
    uint256 denominator) public onlyOwner {
        require(numerator <= denominator, WRONG_NUMBERS);
        royaltyRecipient = recipient;
        royaltyNumerator = numerator;
        royaltyDenominator = denominator;
        emit RoyaltiesConfigured(recipient, numerator, denominator);
    }
}

