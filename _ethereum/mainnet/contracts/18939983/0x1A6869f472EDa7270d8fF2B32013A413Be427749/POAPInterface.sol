// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface POAPInterface {
    /**
     * @dev Emitted when NFT is minted.
     */
    event NewNFTMinted(uint256[], uint256[]);
 
    /**
     * @dev Emitted when the onChainPoll contract is updated, along with updated onChainPoll contract address.
     */
    event OnChainPollContractUpdated(address onChainPollContract);

    /**
     * @dev Mints a new NFT for the poll response.
     * @dev Only the onChainPoll contract can call this function.
     * @param tokenUri The metadata uri for the poll data.
     * @param to The address to mint the NFT.
     */
    function mint(
        string calldata tokenUri,
        address to
    ) external returns (uint256);

    /**
     * @dev Updates the onChainPoll contract's address.
     * @dev Only owner can call this function.
     * @param newOnChainPollContract The new address of the onChainPoll contract.
     */
    function updateOnChainPollContract(address newOnChainPollContract) external;

    /**
     * @dev return the onChainPoll contract's address
     */
    function getOnChainPollContract() external returns (address);

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external;

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external;
}