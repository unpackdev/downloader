//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./IRoyaltyEngineV1.sol";

/// @dev This library uses the Royalty Registry to see if royalties are configured for a specified NFT.
/// The Royalty Registry looks at a number of sources to see if the original creator set a royalty
/// configurationon the contract, such as EIP-2981, Manifold, Rarible, etc.
/// See https://royaltyregistry.xyz/ for more details and deployed addresses.
/// The output will be a list of addresses and a value that each should receive.
library Royalties {
    /// @dev Validate royalties addresses and amounts arrays
    function _validateRoyalties(
        address payable[] memory recipients,
        uint256[] memory amounts
    ) internal pure returns (bool) {
        // Verify royalties were found
        if (recipients.length == 0) {
            return false;
        }

        // Verify array lengths match
        if (recipients.length != amounts.length) {
            return false;
        }

        // Calculate the total rewards BP
        uint256 totalRewardsBp = 0;

        // Verify valid addresses and amounts
        for (uint8 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0x0)) {
                return false;
            }

            if (amounts[i] == 0 || amounts[i] > 10_000) {
                return false;
            }

            totalRewardsBp += amounts[i];
        }

        // Total rewards across all addresses should not be above 100%
        if (totalRewardsBp > 10_000) {
            return false;
        }

        // No issues found, use them
        return true;
    }

    /// @dev Gets the royalties for a specified NFT and uses the fallback values if none are found
    /// A sale price of 10,000 will be used as the value to query since the protocol uses basis points
    /// to track a percentage of value to send to the creators.  (10k basis points = 100%)
    function _getRoyaltyOverride(
        address royaltyRegistry,
        address nftContractAddress,
        uint256 nftId,
        address fallbackCreator,
        uint256 fallbackCreatorBasisPoints
    )
        internal
        view
        returns (
            address[] memory creators,
            uint256[] memory creatorSaleBasisPoints
        )
    {
        // Query the royalty registry
        if (royaltyRegistry != address(0x0)) {
            // Use 10k to get back basis points
            try
                IRoyaltyEngineV1(royaltyRegistry).getRoyaltyView(
                    nftContractAddress,
                    nftId,
                    10_000
                )
            returns (
                address payable[] memory recipients,
                uint256[] memory amounts
            ) {
                // Check to see if valid results were found
                if (_validateRoyalties(recipients, amounts)) {
                    // Convert to non-payable
                    // https://github.com/ethereum/solidity/issues/5462
                    address[] memory convertedAddresses = new address[](
                        recipients.length
                    );
                    for (uint8 i = 0; i < recipients.length; i++) {
                        convertedAddresses[i] = recipients[i];
                    }

                    // Use the valid royalties
                    return (convertedAddresses, amounts);
                }
            } catch {
                // Ignore an errors
            }
        }
        // None found, use fallback address... address 0x0 means no creator rewards
        address[] memory addressesArray = new address[](1);
        addressesArray[0] = fallbackCreator;

        // Use fallback value, and ensure it is not above 100%
        require(fallbackCreatorBasisPoints <= 10_000, "Invalid bp");
        uint256[] memory creatorBasisPointsArray = new uint256[](1);
        creatorBasisPointsArray[0] = fallbackCreatorBasisPoints;

        return (addressesArray, creatorBasisPointsArray);
    }
}
