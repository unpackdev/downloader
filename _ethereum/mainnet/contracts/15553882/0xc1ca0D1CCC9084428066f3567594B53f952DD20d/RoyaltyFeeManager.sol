// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC2981.sol";

import "./TheRoyaltyFeeManager.sol";
import "./IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeManager
 * @notice It handles the logic to check and transfer royalty fees (if any).
 */
contract RoyaltyFeeManager is TheRoyaltyManager, Ownable {
    // https://eips.ethereum.org/EIPS/eip-2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoyaltyFeeRegistry public immutable royaltyFeeRegistry;

    //  initialize a royalty fee registry
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
    }

    //
    // function calculateRoyaltyFeeAndGetRecipient
    //  @Description: Calculate royalty fee and return the fee recepient
    //  @param address
    //  @param uint256
    //  @param uint256
    //  @return external
    //
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view override returns (address, uint256) {
        //  Check if the royalty fee informatoin has been registered
        (address receiver, uint256 royaltyAmount) = royaltyFeeRegistry.royaltyInfo(collection, amount);

        // If both the receipient's address is blank and the fee is 0, check if ERC 2981 API is supported
        if ((receiver == address(0)) || (royaltyAmount == 0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
                (receiver, royaltyAmount) = IERC2981(collection).royaltyInfo(tokenId, amount);
            }
        }
        return (receiver, royaltyAmount);
    }
}
