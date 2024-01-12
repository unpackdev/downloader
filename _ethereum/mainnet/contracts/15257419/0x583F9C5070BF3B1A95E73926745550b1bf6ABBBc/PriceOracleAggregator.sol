// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";
import "./UUPSProxiable.sol";
import "./IPriceOracleAggregator.sol";
import "./IOracle.sol";

////////////////////////////////////////////////////////////////////////////////////////////
/// @title PriceOracleAggregator
/// @author @samparsky
/// @notice aggregator of price oracle for assets in LendingPairs
////////////////////////////////////////////////////////////////////////////////////////////

contract PriceOracleAggregator is IPriceOracleAggregator {
    /// STATE VARIABLES ////

    /// @dev admin allowed to update price oracle
    address public owner;

    /// @dev new owner
    address internal newOwner;

    /// @notice token to the oracle address
    mapping(IERC20 => IOracle) public assetToOracle;

    /// @notice stable to is stable status
    mapping(IERC20 => bool) public stableTokens;

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "INVALID_OWNER");
        owner = _owner;
    }

    /// @notice adds oracle for an asset e.g. ETH
    /// @param _asset the oracle for the asset
    /// @param _oracle the oracle address
    function setOracleForAsset(IERC20[] calldata _asset, IOracle[] calldata _oracle)
        external
        override
        onlyOwner
    {
        require(_asset.length == _oracle.length, "INV");
        uint256 size = _asset.length;

        for (uint256 i = 0; i < size; i++) {
            IOracle oracle = _oracle[i];
            require(address(oracle) != address(0), "INVALID_ORACLE");
            assetToOracle[_asset[i]] = oracle;
            emit UpdateOracle(_asset[i], oracle);
        }
    }

    /// @notice remove oracle
    function removeOracleForAsset(IERC20 _asset) external onlyOwner {
        assetToOracle[_asset] = IOracle(address(0));
        emit UpdateOracle(_asset, IOracle(address(0)));
    }

    /// @notice addStable use to add stablecoin asset that should be hardcoded
    function addStable(IERC20[] calldata _tokens) public onlyOwner {
        uint256 size = _tokens.length;
        for (uint256 i = 0; i < size; i++) {
            stableTokens[_tokens[i]] = true;
            emit StableTokenAdded(_tokens[i], block.timestamp);
        }
    }

    /// @notice returns price of token in USD in 1e8 decimals
    /// @param _token token to fetch price
    function getPriceInUSD(IERC20 _token) public view override returns (uint256 price) {
        IOracle oracle = assetToOracle[_token];

        if (address(oracle) != address(0)) {
            price = uint256(assetToOracle[_token].latestAnswer());
        } else if (stableTokens[_token] == true) {
            price = 1e8;
        }

        require(price > 0, "INVALID_PRICE");
    }

    function getPriceInUSDMultiple(IERC20[] calldata _tokens)
        external
        view
        override
        returns (uint256[] memory prices)
    {
        uint256 size = _tokens.length;
        for (uint256 i = 0; i < size; i++) {
            prices[i] = getPriceInUSD(_tokens[i]);
        }
    }

    /// @notice accept transfer of control
    function acceptOwnership() external {
        require(msg.sender == newOwner, "invalid owner");

        // emit event before state change to do not trigger null address
        emit OwnershipAccepted(owner, newOwner, block.timestamp);

        owner = newOwner;
        newOwner = address(0);
    }

    /// @notice Transfer control from current owner address to another
    /// @param _newOwner The new team
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_NEW_OWNER");
        newOwner = _newOwner;
        emit TransferControl(_newOwner, block.timestamp);
    }
}
