pragma solidity 0.8.18;

import "./Admin.sol";

/**
 * @title FeeCalculator
 * @notice Calculates fee for transactions using fee configuration
 */
contract FeeCalculator is Admin {
    /**
     * @notice Fee configuration for a domain
     * @param maxFee maximum fee in USDC
     * @param minFee minimum fee in USDC
     * @param feePercentage fee percentage in basis point
     * @param txnFee transaction fee in USDC for broadcasting transaction on destination domain
     * @param supported if the domain is supported
     */
    struct FeeConfiguration {
        // maximum fee in USDC
        uint256 maxFee;
        // minimum fee in USDC
        uint256 minFee;
        // fee percentage in basis point
        // e.g. 1% is stored as 100
        uint32 feePercentage;
        // transaction fee is in USDC
        uint256 txnFee;
        // if the domain is supported
        bool supported;
    }

    // domain ID -> fee configuration
    mapping(uint32 => FeeConfiguration) private _feeConfigurations;

    // ============ Events ============
    /**
     * @notice Emitted when fee configuration is updated
     * @param domain domain ID
     * @param feeConfiguration fee configuration
     */
    event FeeConfigurationUpdated(uint32 domain, FeeConfiguration feeConfiguration);

    // Errors
    error UnsupportedDomain();
    error MaxFeeLessThanMinFee();
    error FeePercentageGreaterThanMax();

    // ============ Functions  ============
    /**
     * @notice Sets fee configurations for domains
     * @param domain domain ID
     * @param feeConfiguration fee configuration
     */
    function setFeeConfiguration(
        uint32 domain, 
        FeeConfiguration calldata feeConfiguration
    ) 
        public 
        onlyAdmin 
    {
        if (feeConfiguration.maxFee < feeConfiguration.minFee) {
            revert MaxFeeLessThanMinFee();
        }

        if (feeConfiguration.feePercentage > 1000) {
            revert FeePercentageGreaterThanMax();
        }

        _feeConfigurations[domain] = feeConfiguration;

        emit FeeConfigurationUpdated(domain, feeConfiguration);
    }

     /**
     * @notice Checks if a domain is supported
     * @param domain domain ID
     * @return true if the domain is supported
     */
    function isSupportedDomain(uint32 domain) public view returns (bool) {
        return _feeConfigurations[domain].supported;
    }

    /**
     * @notice Sets fee configuration for a domain
     * @param domain domain ID
     * @return FeeConfiguration fee configuration
     */
    function getFeeConfiguration(uint32 domain) public view returns (FeeConfiguration memory) {
        if (!isSupportedDomain(domain)) {
            revert UnsupportedDomain();
        }
        return _feeConfigurations[domain];
    }

    /**
     * @notice Get max fee for a domain
     * @param domain domain ID
     * @return uint256 maximum fee in USDC
     */
    function getMaxFee(uint32 domain) public view returns (uint256) {
        if (!isSupportedDomain(domain)) {
            revert UnsupportedDomain();
        }
        return _feeConfigurations[domain].maxFee;
    }

    /**
     * @notice Get min fee for a domain
     * @param domain domain ID
     * @return uint256 minimum fee in USDC
     */
    function getMinFee(uint32 domain) public view returns (uint256) {
        if (!isSupportedDomain(domain)) {
            revert UnsupportedDomain();
        }
        return _feeConfigurations[domain].minFee;
    }

    /**
     * @notice Get fee percentage for a domain
     * @param domain domain ID
     * @return uint32 fee percentage in basis point
     */
    function getFeePercentage(uint32 domain) public view returns (uint32) {
        if (!isSupportedDomain(domain)) {
            revert UnsupportedDomain();
        }
        return _feeConfigurations[domain].feePercentage;
    }

    /**
     * @notice Get transaction fee for a domain
     * @param domain domain ID
     * @return uint256 transaction fee in USDC
     */
    function getTxnFee(uint32 domain) public view returns (uint256) {
        if (!isSupportedDomain(domain)) {
            revert UnsupportedDomain();
        }
        return _feeConfigurations[domain].txnFee;
    }

    /**
     * @notice Calculates fee for a transaction
     * @param amount amount of USDC
     * @param destinationDomain destination domain ID
     * @return uint256 fee in USDC
     */
    function calculateFee(uint256 amount, uint32 destinationDomain) public view returns (uint256) {
        if (!isSupportedDomain(destinationDomain)) {
            revert UnsupportedDomain();
        }

        FeeConfiguration memory config = _feeConfigurations[destinationDomain];

        // percentage of the amount
        uint256 pctFee = amount * config.feePercentage;

        // round up if necessary
        pctFee = pctFee / 10_000 + (pctFee % 10_000 > 0 ? 1 : 0);

        uint256 maxFee = config.maxFee + config.txnFee;
        uint256 minFee = config.minFee + config.txnFee;

        // check if the percentage fee is within the range of maxFee and minFee
        if (pctFee < minFee) {
            return minFee;
        } else if (pctFee > maxFee) {
            return maxFee;
        }

        return pctFee;
    }
}
