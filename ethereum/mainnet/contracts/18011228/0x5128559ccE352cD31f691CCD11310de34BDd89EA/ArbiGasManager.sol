pragma solidity ^0.8.13;
import "./Governable.sol";


contract ArbiGasManager is Governable{
    address public gasClerk;
    address public refundAddress;
    mapping(bytes32 => uint) public functionGasLimit;
    uint public defaultGasLimit;
    uint public maxSubmissionCostCeiling;
    uint public maxSubmissionCost;
    uint public gasPriceCeiling;
    uint public gasPrice;

    struct L2GasParams {
        uint256 _maxSubmissionCost;
        uint256 _maxGas;
        uint256 _gasPriceBid;
    }


    constructor(address _gov, address _gasClerk, address _l2RefundAddress) Governable(_gov){
        gasClerk = _gasClerk;
        refundAddress = _l2RefundAddress;
        defaultGasLimit = 10**6; //Same gas stipend as Optimism bridge
        maxSubmissionCost = 0.01 ether;
        maxSubmissionCostCeiling = 0.05 ether;
        gasPriceCeiling = 2 * 10**10; //20 gWEI
        gasPrice = 10**9; //1 gWEI
    }

    error OnlyGasClerk();
    error MaxSubmissionCostAboveCeiling();
    error GasPriceAboveCeiling();

    modifier onlyGasClerk(){
        if(msg.sender != gasClerk) revert OnlyGasClerk();
        _;
    }

    /**
     * @notice Sets the default gas limit.
     * @dev This function can only be called by the gas clerk.
     * @param newDefaultGasLimit The new default gas limit to set.
     */
    function setDefaultGasLimit(uint newDefaultGasLimit) external onlyGasClerk {
        defaultGasLimit = newDefaultGasLimit; 
    }

    /**
     * @notice Sets the gas limit for a specific function on a contract.
     * @dev This function can only be called by the gas clerk.
     * @param contractAddress The address of the contract.
     * @param functionSelector The selector of the function to set the gas limit for.
     * @param gasLimit The new gas limit to set.
     */
    function setFunctionGasLimit(address contractAddress, bytes4 functionSelector, uint gasLimit) external onlyGasClerk {
        bytes32 hash = keccak256(abi.encodePacked(functionSelector, contractAddress));
        functionGasLimit[hash] = gasLimit; 
    }

    /**
     * @notice Sets the max submission cost.
     * @dev Throws if new submission cost exceeds the ceiling. Can only be called by the gas clerk.
     * @param newMaxSubmissionCost The new max submission cost to set.
     */
    function setMaxSubmissionCost(uint newMaxSubmissionCost) external onlyGasClerk {
        if(newMaxSubmissionCost > maxSubmissionCostCeiling) revert MaxSubmissionCostAboveCeiling();
        maxSubmissionCost = newMaxSubmissionCost;
    }

    /**
     * @notice Sets the gas price.
     * @dev Throws if new gas price exceeds the ceiling. Can only be called by the gas clerk.
     * @param newGasPrice The new gas price to set.
     */
    function setGasPrice(uint newGasPrice) external onlyGasClerk {
        if(newGasPrice > gasPriceCeiling) revert GasPriceAboveCeiling();
        gasPrice = newGasPrice;
    }

    /**
     * @notice Fetches gas parameters for a specific function on a contract.
     * @param contractAddress The address of the contract.
     * @param functionSelector The selector of the function to get gas parameters for.
     * @return L2GasParams Returns a struct containing gas parameters.
     */
    function getGasParams(address contractAddress, bytes4 functionSelector) public view returns(L2GasParams memory){
        L2GasParams memory gasParams;
        gasParams._maxSubmissionCost = maxSubmissionCost;
        gasParams._gasPriceBid = gasPrice;
        bytes32 hash = keccak256(abi.encodePacked(functionSelector, contractAddress));
        uint gasLimit = functionGasLimit[hash]; 
        if(gasLimit == 0) gasLimit = defaultGasLimit;
        gasParams._maxGas = gasLimit;
        return gasParams;
    }

    /**
     * @notice Sets the L2 refund address.
     * @dev Can only be called by governance.
     * @param newRefundAddress The new refund address to set.
     */
    function setRefundAddress(address newRefundAddress) external onlyGov {
        refundAddress = newRefundAddress;
    }

    /**
     * @notice Sets the max submission cost ceiling.
     * @dev Can only be called by governance.
     * @param newMaxSubmissionCostCeiling The new max submission cost ceiling to set.
     */
    function setMaxSubmissionCostCeiling(uint newMaxSubmissionCostCeiling) external onlyGov {
       maxSubmissionCostCeiling = newMaxSubmissionCostCeiling; 
    }

    /**
     * @notice Sets the gas price ceiling.
     * @dev Can only be called by governance.
     * @param newGasPriceCeiling The new gas price ceiling to set.
     */
    function setGasPriceCeiling(uint newGasPriceCeiling) external onlyGov {
       gasPriceCeiling = newGasPriceCeiling; 
    }
    /**
     * @notice Sets the gas clerk address.
     * @dev Can only be called by governance.
     * @param newGasClerk The new address to be set as the gas clerk.
     */
    function setGasClerk(address newGasClerk) external onlyGov {
        gasClerk = newGasClerk;
    }

    /**
     * @notice Fetches the default minimum call value based on gas settings.
     * @return minval Returns the default minimum call value calculated as `gasPrice * gasDefaultLimit + maxSubmissionCost`.
     */
    function getDefaultMinimumCallValue() public view returns(uint minval){
        return gasPrice * defaultGasLimit + maxSubmissionCost;
    }

    /**
     * @notice Fetches the minimum call value for a specific function on a contract based on gas settings.
     * @dev This function computes the gas limit using the default if not explicitly set for the function.
     * @param contractAddress The address of the L2 contract to be called.
     * @param functionSelector The selector of the function to get the minimum call value for.
     * @return minval Returns the minimum call value calculated as `gasPrice * gasLimit + maxSubmissionCost`.
     */
    function getFunctionMinimumCallValue(address contractAddress, bytes4 functionSelector) public view returns (uint minval) {
        bytes32 hash = keccak256(abi.encodePacked(functionSelector, contractAddress));
        uint gasLimit = functionGasLimit[hash];
        if(gasLimit == 0) gasLimit = defaultGasLimit;
        return gasPrice * gasLimit + maxSubmissionCost;
    }

    /**
     * @notice Checks if the provided call value is sufficient based on default gas settings.
     * @dev This function checks if the provided call value is greater than or equal to the default minimum call value and the current contract balance.
     * @param callValue The call value to check for sufficiency.
     * @return Returns `true` if the call value is sufficient, otherwise `false`.
     */
    function isCallValueSufficient(uint callValue) public view returns (bool){
        return getDefaultMinimumCallValue() <= callValue + address(this).balance;
    }

    /**
     * @notice Checks if the provided call value is sufficient for a specific function on a contract based on gas settings.
     * @dev This function checks if the provided call value is greater than or equal to the minimum call value for the specified function and the current contract balance.
     * @param contractAddress The address of the contract.
     * @param functionSelector The selector of the function to check the call value for.
     * @param callValue The call value to check for sufficiency.
     * @return Returns `true` if the call value is sufficient for the specified function, otherwise `false`.
     */
    function isCallValueSufficient(address contractAddress, bytes4 functionSelector, uint callValue) public view returns (bool){
        return getFunctionMinimumCallValue(contractAddress, functionSelector) <= callValue + address(this).balance;
    }
}
