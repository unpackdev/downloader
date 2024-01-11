// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./IERC165.sol";
import "./IAllowlist.sol";
import "./IConfig.sol";

/**
 * @dev
 */
interface IAdmin is IERC165 {

    error AllocationExceeded();
    error ArbitraryAllocationExceeded();
    error ArbitraryTotalAllocationExceeded();
    error ArbitraryAllocationVerificationError();
    error ConfigNotFound(uint256);
    error ExcessiveFunds();
    error ExtensionInvalid();
    error InsufficientFunds();
    error MintClosed();
    error MintQuantityInvalid();
    error MintQuantityPerTxnExceeded();
    error MintQuantityPerWalletExceeded();
    error MintInactive();
    error MintNotStarted();
    error MintPaused();
    error MintProofInvalid();
    error MintQuantityExceedsMaxSupply();
    error PricelistNotFound(uint256);

    /**
    * @dev
    */
    struct Allocation {
        uint256 allowlistId;
        uint256 allocation;
        uint256 price;
    }

    /**
    * @dev creates a configuration
    */
    function createConfig(IConfig.Config memory _config) external;

    /**
    * @dev updates a configuration
    */
    function updateConfig(uint256 _configId, IConfig.Config memory _config) external;

    /**
    * @dev gets allocation data structure by address
    */
    function getAllocationByAddress(address _address, bytes32[][] calldata _proofs) external view returns (Allocation memory);

    /**
    * @dev gets total allocation for an address
    */
    function getAllocationTotalByAddress(address _address, bytes32[][] calldata _proofs) external view returns (uint256);

    /**
    * @dev sets allocations for an allowlist
    */
    function setAllocation(uint256 _allowlistId, uint256 _allocation) external;

    /**
    * @dev sets contract URI
    */
    function setContractURI(string memory _contractURI) external;

    /**
    * @dev gets contract URI
    */
    function getContractURI() external view returns (string memory);

    /**
    * @dev sets extension addresses
    */
    function setExtension(IConfig.Extensions _extension, address _address) external;

    /**
    * @dev creates a pricelist
    */
    function createPricelist(IConfig.Pricelist memory _pricelist) external;

    /**
    * @dev updates a pricelist
    */
    function updatePricelist(uint256 _pricelistId, IConfig.Pricelist memory _pricelist) external;

    /**
    * @dev updates a pricelist by allowlist id
    */
    function updatePricelistByAllowlistId(uint256 _allowlistId, IConfig.Pricelist memory _pricelist) external;

    /**
    * @dev gets pricelist by allowlist id
    */
    function getPricelistByAllowlistId(uint256 _allowlistId) external view returns (IConfig.Pricelist memory);

    /**
    * @dev sets split contract address
    */
    function setSplitContract(address payable _address) external;

    /**
    * @dev gets split contract address
    */
    function getSplitContract() external view returns (address payable);

    /**
    * @dev creates an allowlist
    */
    function createAllowlist(IAllowlist.Allowlist memory _allowlist) external;

    /**
    * @dev updates an allowlist
    */
    function updateAllowlist(uint256 _allowlistId, IAllowlist.Allowlist memory _allowlist) external;

    /**
    * @dev adds share to royalty contract for an account
    */
    function addRoyaltyShare(address _account) external;

    /**
    * @dev removes share from royalty contract for an account
    */
    function removeRoyaltyShare(address _account) external;

    /**
    * @dev reverts transaction if allocation check fails
    */
    function revertOnAllocationCheckFailure(address _address, bytes32[][] calldata _proofs, uint256 _quantity) external returns (Allocation memory);

    /**
    * @dev reverts transaction if allocation check fails
    */
    function revertOnArbitraryAllocationCheckFailure(address _address, uint256 _numMinted, uint256 _quantity, bytes32[] calldata _proof, uint256 _allowlistID, uint256 _allowed) external;

    /**
    * @dev reverts transaction if allocation check fails
    */
    function revertOnTotalAllocationCheckFailure(uint256 _totalMinted, uint256 _quantity, uint256 _allowed) external;

    /**
    * @dev reverts transaction if max per wallet check fails
    */
    function revertOnMaxWalletMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalMinted) external;

    /**
    * @dev reverts transaction if pre-defined mint config checks fail to pass
    */
    function revertOnMintCheckFailure(uint256 _configId, uint256 _quantity, uint256 _totalSupply, bool _paused) external;

    /**
    * @dev reverts transaction if payment doesn't meet required parameters
    */
    function revertOnPaymentFailure(uint256 _configId, uint256 _price, uint256 _quantity, uint256 _payment, bool _override) external;

    /**
    * @dev reverts transaction if payment doesn't meet required parameters
    */
    function revertOnArbitraryPaymentFailure(uint256 _price, uint256 _payment) external;

}
