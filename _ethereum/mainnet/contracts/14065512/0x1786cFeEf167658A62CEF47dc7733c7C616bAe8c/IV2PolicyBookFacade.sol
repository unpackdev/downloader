// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface IV2PolicyBookFacade {
    function addLiquidityAndStakeFor(
        address _liquidityHolderAddr,
        uint256 _liquidityAmount,
        uint256 _stakeSTBLAmount
    ) external;

    /// @param _holder who owns coverage
    /// @param _epochsNumber period policy will cover
    /// @param _coverTokens amount paid for the coverage
    function buyPolicyFor(
        address _holder,
        uint256 _epochsNumber,
        uint256 _coverTokens
    ) external;

    ///// @notice Let user to buy policy by supplying stable coin, access: ANY
    ///// @param _epochsNumber period policy will cover
    ///// @param _coverTokens amount paid for the coverage
    //function buyPolicy(uint256 _epochsNumber, uint256 _coverTokens) external;

    //function policyBook() external view returns (IPolicyBook);

    //function userLiquidity(address account) external view returns (uint256);

    ///// @notice virtual funds deployed by reinsurance pool
    //function VUreinsurnacePool() external view returns (uint256);

    ///// @notice leverage funds deployed by reinsurance pool
    //function LUreinsurnacePool() external view returns (uint256);

    ///// @notice leverage funds deployed by user leverage pool
    //function LUuserLeveragePool(address userLeveragePool) external view returns (uint256);

    ///// @notice total leverage funds deployed to the pool sum of (VUreinsurnacePool,LUreinsurnacePool,LUuserLeveragePool)
    //function totalLeveragedLiquidity() external view returns (uint256);

    //function userleveragedMPL() external view returns (uint256);

    //function reinsurancePoolMPL() external view returns (uint256);

    //function rebalancingThreshold() external view returns (uint256);

    //function safePricingModel() external view returns (bool);

    ///// @notice policyBookFacade initializer
    ///// @param pbProxy polciybook address upgreadable cotnract.
    //function __PolicyBookFacade_init(
    //    address pbProxy,
    //    address liquidityProvider,
    //    uint256 initialDeposit
    //) external;

    ///// @param _epochsNumber period policy will cover
    ///// @param _coverTokens amount paid for the coverage
    ///// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    //function buyPolicyFromDistributor(
    //    uint256 _epochsNumber,
    //    uint256 _coverTokens,
    //    address _distributor
    //) external;

    ///// @param _buyer who is buying the coverage
    ///// @param _epochsNumber period policy will cover
    ///// @param _coverTokens amount paid for the coverage
    ///// @param _distributor if it was sold buy a whitelisted distributor, it is distributor address to receive fee (commission)
    //function buyPolicyFromDistributorFor(
    //    address _buyer,
    //    uint256 _epochsNumber,
    //    uint256 _coverTokens,
    //    address _distributor
    //) external;

    ///// @notice Let user to add liquidity by supplying stable coin, access: ANY
    ///// @param _liquidityAmount is amount of stable coin tokens to secure
    //function addLiquidity(uint256 _liquidityAmount) external;

    ///// @notice Let user to add liquidity by supplying stable coin, access: ANY
    ///// @param _user the one taht add liquidity
    ///// @param _liquidityAmount is amount of stable coin tokens to secure
    //function addLiquidityFromDistributorFor(address _user, uint256 _liquidityAmount) external;

    ///// @notice Let user to add liquidity by supplying stable coin and stake it,
    ///// @dev access: ANY
    //function addLiquidityAndStake(uint256 _liquidityAmount, uint256 _stakeSTBLAmount) external;

    ///// @notice Let user to withdraw deposited liqiudity, access: ANY
    //function withdrawLiquidity() external;

    ///// @notice fetches all the pools data
    ///// @return uint256 VUreinsurnacePool
    ///// @return uint256 LUreinsurnacePool
    ///// @return uint256 LUleveragePool
    ///// @return uint256 user leverage pool address
    //function getPoolsData()
    //    external
    //    view
    //    returns (
    //        uint256,
    //        uint256,
    //        uint256,
    //        address
    //    );

    ///// @notice deploy leverage funds (RP lStable, ULP lStable)
    ///// @param  deployedAmount uint256 the deployed amount to be added or substracted from the total liquidity
    ///// @param leveragePool whether user leverage or reinsurance leverage
    //function deployLeverageFundsAfterRebalance(
    //    uint256 deployedAmount,
    //    ILeveragePortfolio.LeveragePortfolio leveragePool
    //) external;

    ///// @notice deploy virtual funds (RP vStable)
    ///// @param  deployedAmount uint256 the deployed amount to be added to the liquidity
    //function deployVirtualFundsAfterRebalance(uint256 deployedAmount) external;

    /////@dev in case ur changed of the pools by commit a claim or policy expired
    //function reevaluateProvidedLeverageStable() external;

    ///// @notice set the MPL for the user leverage and the reinsurance leverage
    ///// @param _userLeverageMPL uint256 value of the user leverage MPL
    ///// @param _reinsuranceLeverageMPL uint256  value of the reinsurance leverage MPL
    //function setMPLs(uint256 _userLeverageMPL, uint256 _reinsuranceLeverageMPL) external;

    ///// @notice sets the rebalancing threshold value
    ///// @param _newRebalancingThreshold uint256 rebalancing threshhold value
    //function setRebalancingThreshold(uint256 _newRebalancingThreshold) external;

    ///// @notice sets the rebalancing threshold value
    ///// @param _safePricingModel bool is pricing model safe (true) or not (false)
    //function setSafePricingModel(bool _safePricingModel) external;

    ///// @notice returns how many BMI tokens needs to approve in order to submit a claim
    //function getClaimApprovalAmount(address user) external view returns (uint256);

    ///// @notice upserts a withdraw request
    ///// @dev prevents adding a request if an already pending or ready request is open.
    ///// @param _tokensToWithdraw uint256 amount of tokens to withdraw
    //function requestWithdrawal(uint256 _tokensToWithdraw) external;

    //function listUserLeveragePools(uint256 offset, uint256 limit)
    //    external
    //    view
    //    returns (address[] memory _userLeveragePools);

    //function countUserLeveragePools() external view returns (uint256);
}
