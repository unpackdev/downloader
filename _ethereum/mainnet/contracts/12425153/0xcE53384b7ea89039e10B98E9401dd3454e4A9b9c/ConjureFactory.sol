// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./CloneLibrary.sol";

/// @author Conjure Finance Team
/// @title ConjureFactory
/// @notice Factory contract to create new instances of Conjure
contract ConjureFactory {
    using CloneLibrary for address;

    event NewConjure(address conjure, address etherCollateral);
    event FactoryOwnerChanged(address newowner);

    address payable public factoryOwner;
    address public conjureImplementation;
    address public etherCollateralImplementation;
    address payable public conjureRouter;

    constructor(
        address _conjureImplementation,
        address _etherCollateralImplementation,
        address payable _conjureRouter
    )
    {
        require(_conjureImplementation != address(0), "No zero address for conjure");
        require(_etherCollateralImplementation != address(0), "No zero address for etherCollateral");
        require(_conjureRouter != address(0), "No zero address for conjureRouter");
        
        factoryOwner = msg.sender;
        conjureImplementation = _conjureImplementation;
        etherCollateralImplementation = _etherCollateralImplementation;
        conjureRouter = _conjureRouter;
    }

    /**
     * @dev lets anyone mint a new Conjure contract
     *
     *  @param oracleTypesValuesWeightsDecimals array containing the oracle type, oracle value, oracle weight,
     *         oracle decimals array
     *  @param callDataArray thr callData array for the oracle setup
     *  @param signatures_ the array containing the signatures if the oracles
     *  @param oracleAddresses_ the addresses array of the oracles containing 2 addresses: 1. address to call,
     *         2. address of the token for supply if needed
     *  @param divisorAssetTypeMintingFeeRatio array containing 2 arrays: 1. divisor + assetType, 2. mintingFee + CRatio
     *  @param conjureAddresses containing the 2 conjure needed addresses: owner, ethUsdChainLinkOracle
     *  @param nameSymbol array containing the name and the symbol of the asset
     *  @param inverse indicator if this an inverse asset
     *  @return conjure the conjure contract address
     *  @return etherCollateral the EtherCollateral address
    */
    function conjureMint(
        // oracle type, oracle value, oracle weight, oracle decimals array
        uint256[][4] memory oracleTypesValuesWeightsDecimals,
        bytes[] memory callDataArray,
        string[] memory signatures_,
        // oracle address to call, token address for supply
        address[][2] memory oracleAddresses_,
        // divisor, asset type // mintingFee, CRatio
        uint256[2][2] memory divisorAssetTypeMintingFeeRatio,
        // owner, ethUsdChainLinkOracle
        address[] memory conjureAddresses,
        // name, symbol
        string[2] memory nameSymbol,
        // inverse asset indicator
        bool inverse
    )
    external
    returns(address conjure, address etherCollateral)
    {
        conjure = conjureImplementation.createClone();
        etherCollateral = etherCollateralImplementation.createClone();
        
        emit NewConjure(conjure, etherCollateral);

        IConjure(conjure).initialize(
            nameSymbol,
            conjureAddresses,
            address(this),
            etherCollateral
        );

        IEtherCollateral(etherCollateral).initialize(
            payable(conjure),
            conjureAddresses[0],
            address(this),
            divisorAssetTypeMintingFeeRatio[1]
        );

        IConjure(conjure).init(
            inverse,
            divisorAssetTypeMintingFeeRatio[0],
            oracleAddresses_,
            oracleTypesValuesWeightsDecimals,
            signatures_,
            callDataArray
        );
    }

    /**
     * @dev gets the address of the current factory owner
     *
     * @return the address of the conjure router
    */
    function getConjureRouter() external view returns (address payable) {
        return conjureRouter;
    }

    /**
     * @dev lets the owner change the current conjure implementation
     *
     * @param conjureImplementation_ the address of the new implementation
    */
    function newConjureImplementation(address conjureImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(conjureImplementation_ != address(0), "No zero address for conjureImplementation_");
        
        conjureImplementation = conjureImplementation_;
    }

    /**
     * @dev lets the owner change the current EtherCollateral implementation
     *
     * @param etherCollateralImplementation_ the address of the new implementation
    */
    function newEtherCollateralImplementation(address etherCollateralImplementation_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(etherCollateralImplementation_ != address(0), "No zero address for etherCollateralImplementation_");

        etherCollateralImplementation = etherCollateralImplementation_;
    }

    /**
     * @dev lets the owner change the current conjure router
     *
     * @param conjureRouter_ the address of the new router
    */
    function newConjureRouter(address payable conjureRouter_) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(conjureRouter_ != address(0), "No zero address for conjureRouter_");
        
        conjureRouter = conjureRouter_;
    }

    /**
     * @dev lets the owner change the ownership to another address
     *
     * @param newOwner the address of the new owner
    */
    function newFactoryOwner(address payable newOwner) external {
        require(msg.sender == factoryOwner, "Only factory owner");
        require(newOwner != address(0), "No zero address for newOwner");
        
        factoryOwner = newOwner;
        emit FactoryOwnerChanged(factoryOwner);
    }

    /**
     * receive function to receive funds
    */
    receive() external payable {}
}

interface IConjure {
    function initialize(
        string[2] memory nameSymbol,
        address[] memory conjureAddresses,
        address factoryAddress_,
        address collateralContract
    ) external;

    function init(
        bool inverse_,
        uint256[2] memory divisorAssetType,
        address[][2] memory oracleAddresses_,
        uint256[][4] memory oracleTypesValuesWeightsDecimals,
        string[] memory signatures_,
        bytes[] memory callData_
    ) external;
}

interface IEtherCollateral {
    function initialize(
        address payable _asset,
        address _owner,
        address _factoryAddress,
        uint256[2] memory _mintingFeeRatio
    )
    external;
}
