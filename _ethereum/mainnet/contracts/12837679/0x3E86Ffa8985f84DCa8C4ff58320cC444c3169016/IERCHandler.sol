pragma solidity >= 0.6.12;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author ChainSafe Systems.
 */
interface IERCHandler {

    function getWETHAddress() external view  returns (address);

    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) external;

    /**
        @notice Sets oneSplitAddress for the handler
        @param contractAddress Address of oneSplit contract
     */
    function setOneSplitAddress(address contractAddress) external;

    /**
        @notice Correlates {resourceID} with {contractAddress}.
        @param contractAddress Address of contract for qhich liquidity pool needs to be created.
     */
    function setLiquidityPool(string memory name, string memory symbol, uint8 decimals, address contractAddress, address lpAddress) external;

    function setLiquidityPoolOwner(address newOwner, address tokenAddress, address lpAddress) external;


    /**
        @notice Marks {contractAddress} as mintable/burnable.
        @param contractAddress Address of contract to be used when making or executing deposits.
     */
    function setBurnable(address contractAddress) external;
    /**
        @notice Used to manually release funds from ERC safes.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amountOrTokenID Either the amount of ERC20 tokens or the ERC721 token ID to release.
     */
    function withdraw(address tokenAddress, address recipient, uint256 amountOrTokenID) external;


}
