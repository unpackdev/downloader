// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IERC1155.sol";
import "./INFTGemMultiToken.sol";
import "./INFTGemPoolFactory.sol";
import "./IControllable.sol";
import "./INFTGemPool.sol";
import "./IProposal.sol";
import "./IProposalData.sol";


library GovernanceLib {

    // calculates the CREATE2 address for the quantized erc20 without making any external calls
    function addressOfPropoal(
        address factory,
        address submitter,
        string memory title
    ) public pure returns (address govAddress) {
        govAddress = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(submitter, title)),
                        hex"74f827a6bb3b7ed4cd86bd3c09b189a9496bc40d83635649e1e4df1c4e836ebf" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev create vote tokens to vote on given proposal
     */
    function createProposalVoteTokens(address multitoken, uint256 proposalHash) external {
        for (uint256 i = 0; i < INFTGemMultiToken(multitoken).allTokenHoldersLength(0); i++) {
            address holder = INFTGemMultiToken(multitoken).allTokenHolders(0, i);
            INFTGemMultiToken(multitoken).mint(holder, proposalHash,
                IERC1155(multitoken).balanceOf(holder, 0)
            );
        }
    }

    /**
     * @dev destroy the vote tokens for the given proposal
     */
    function destroyProposalVoteTokens(address multitoken, uint256 proposalHash) external {
        for (uint256 i = 0; i < INFTGemMultiToken(multitoken).allTokenHoldersLength(0); i++) {
            address holder = INFTGemMultiToken(multitoken).allTokenHolders(0, i);
            INFTGemMultiToken(multitoken).burn(holder, proposalHash,
                IERC1155(multitoken).balanceOf(holder, proposalHash)
            );
        }
    }

        /**
     * @dev execute craete pool proposal
     */
    function execute(
        address factory,
        address proposalAddress) public returns (address newPool) {

        // get the data for the new pool from the proposal
        address proposalData = IProposal(proposalAddress).proposalData();

        (
            string memory symbol,
            string memory name,

            uint256 ethPrice,
            uint256 minTime,
            uint256 maxTime,
            uint256 diffStep,
            uint256 maxClaims,

            address allowedToken
        ) = ICreatePoolProposalData(proposalData).data();

        // create the new pool
        newPool = createPool(
            factory,

            symbol,
            name,

            ethPrice,
            minTime,
            maxTime,
            diffStep,
            maxClaims,

            allowedToken
        );
    }

    /**
     * @dev create a new pool
     */
    function createPool(
        address factory,

        string memory symbol,
        string memory name,

        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,

        address allowedToken
    ) public returns (address pool) {
        pool = INFTGemPoolFactory(factory).createNFTGemPool(
            symbol,
            name,

            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,

            allowedToken
        );
    }

}
