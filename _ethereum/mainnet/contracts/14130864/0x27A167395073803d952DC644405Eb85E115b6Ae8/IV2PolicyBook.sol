// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

// import "./IPolicyBookFabric.sol";
// import "./IClaimingRegistry.sol";
// import "./IPolicyBookFacade.sol";

interface IV2PolicyBook {
    function policyBookFacade() external view returns (address);

    ///// @notice Let eligible contracts add liqiudity for another user by supplying stable coin
    ///// @param _liquidityHolderAddr is address of address to assign cover
    ///// @param _liqudityAmount is amount of stable coin tokens to secure
    function addLiquidityFor(address _liquidityHolderAddr, uint256 _liqudityAmount) external;

    /// @notice view function to get precise policy price
    /// @param _epochsNumber is number of epochs to cover
    /// @param _coverTokens is number of tokens to cover
    /// @param _buyer address of the user who buy the policy
    /// @return totalSeconds is number of seconds to cover
    /// @return totalPrice is the policy price which will pay by the buyer
    function getPolicyPrice(
        uint256 _epochsNumber,
        uint256 _coverTokens,
        address _buyer
    )
        external
        view
        returns (
            uint256 totalSeconds,
            uint256 totalPrice,
            uint256 pricePercentage
        );

    //enum WithdrawalStatus {NONE, PENDING, READY, EXPIRED}

    //struct PolicyHolder {
    //    uint256 coverTokens;
    //    uint256 startEpochNumber;
    //    uint256 endEpochNumber;
    //    uint256 paid;
    //    uint256 reinsurancePrice;
    //}

    //struct WithdrawalInfo {
    //    uint256 withdrawalAmount;
    //    uint256 readyToWithdrawDate;
    //    bool withdrawalAllowed;
    //}

    //struct BuyPolicyParameters {
    //    address buyer;
    //    address holder;
    //    uint256 epochsNumber;
    //    uint256 coverTokens;
    //    uint256 distributorFee;
    //    address distributor;
    //}

    //function policyHolders(address _holder)
    //    external
    //    view
    //    returns (
    //        uint256,
    //        uint256,
    //        uint256,
    //        uint256,
    //        uint256
    //    );

    //function policyBookFacade() external view returns (IPolicyBookFacade);

    //function setPolicyBookFacade(address _policyBookFacade) external;

    //function EPOCH_DURATION() external view returns (uint256);

    //function stblDecimals() external view returns (uint256);

    //function READY_TO_WITHDRAW_PERIOD() external view returns (uint256);

    //function whitelisted() external view returns (bool);

    //function epochStartTime() external view returns (uint256);

    //// @TODO: should we let DAO to change contract address?
    ///// @notice Returns address of contract this PolicyBook covers, access: ANY
    ///// @return _contract is address of covered contract
    //function insuranceContractAddress() external view returns (address _contract);

    ///// @notice Returns type of contract this PolicyBook covers, access: ANY
    ///// @return _type is type of contract
    //function contractType() external view returns (IPolicyBookFabric.ContractType _type);

    //function totalLiquidity() external view returns (uint256);

    //function totalCoverTokens() external view returns (uint256);

    //// /// @notice return MPL for user leverage pool
    //// function userleveragedMPL() external view returns (uint256);

    //// /// @notice return MPL for reinsurance pool
    //// function reinsurancePoolMPL() external view returns (uint256);

    //// function bmiRewardMultiplier() external view returns (uint256);

    //function withdrawalsInfo(address _userAddr)
    //    external
    //    view
    //    returns (
    //        uint256 _withdrawalAmount,
    //        uint256 _readyToWithdrawDate,
    //        bool _withdrawalAllowed
    //    );

    //function __PolicyBook_init(
    //    address _insuranceContract,
    //    IPolicyBookFabric.ContractType _contractType,
    //    string calldata _description,
    //    string calldata _projectSymbol
    //) external;

    //function whitelist(bool _whitelisted) external;

    ///// @notice get STBL equivalent
    //function convertBMIXToSTBL(uint256 _amount) external view returns (uint256);

    ///// @notice get BMIX equivalent
    //function convertSTBLToBMIX(uint256 _amount) external view returns (uint256);

    ///// @notice submits new claim of the policy book
    //function submitClaimAndInitializeVoting(string calldata evidenceURI) external;

    ///// @notice submits new appeal claim of the policy book
    //function submitAppealAndInitializeVoting(string calldata evidenceURI) external;

    ///// @notice updates info on claim acceptance
    //function commitClaim(
    //    address claimer,
    //    uint256 claimAmount,
    //    uint256 claimEndTime,
    //    IClaimingRegistry.ClaimStatus status
    //) external;

    ///// @notice forces an update of RewardsGenerator multiplier
    //function forceUpdateBMICoverStakingRewardMultiplier() external;

    ///// @notice function to get precise current cover and liquidity
    //function getNewCoverAndLiquidity()
    //    external
    //    view
    //    returns (uint256 newTotalCoverTokens, uint256 newTotalLiquidity);

    //function updateEpochsInfo() external;

    //function secondsToEndCurrentEpoch() external view returns (uint256);

    //function getAvailableBMIXWithdrawableAmount(address _userAddr) external view returns (uint256);

    //function getWithdrawalStatus(address _userAddr) external view returns (WithdrawalStatus);

    //function requestWithdrawal(uint256 _tokensToWithdraw, address _user) external;

    //// function requestWithdrawalWithPermit(
    ////     uint256 _tokensToWithdraw,
    ////     uint8 _v,
    ////     bytes32 _r,
    ////     bytes32 _s
    //// ) external;

    //function unlockTokens() external;

    ///// @notice Let user to withdraw deposited liqiudity, access: ANY
    //function withdrawLiquidity(address sender) external returns (uint256);

    /////@notice for doing defi hard rebalancing, access: policyBookFacade
    //function updateLiquidity(uint256 _newLiquidity) external;

    //function getAPY() external view returns (uint256);

    ///// @notice Getting user stats, access: ANY
    //function userStats(address _user) external view returns (PolicyHolder memory);

    ///// @notice Getting number stats, access: ANY
    ///// @return _maxCapacities is a max token amount that a user can buy
    ///// @return _totalSTBLLiquidity is PolicyBook's liquidity
    ///// @return _totalLeveragedLiquidity is PolicyBook's leveraged liquidity
    ///// @return _stakedSTBL is how much stable coin are staked on this PolicyBook
    ///// @return _annualProfitYields is its APY
    ///// @return _annualInsuranceCost is percentage of cover tokens that is required to be paid for 1 year of insurance
    //function numberStats()
    //    external
    //    view
    //    returns (
    //        uint256 _maxCapacities,
    //        uint256 _totalSTBLLiquidity,
    //        uint256 _totalLeveragedLiquidity,
    //        uint256 _stakedSTBL,
    //        uint256 _annualProfitYields,
    //        uint256 _annualInsuranceCost,
    //        uint256 _bmiXRatio
    //    );

    ///// @notice Getting info, access: ANY
    ///// @return _symbol is the symbol of PolicyBook (bmiXCover)
    ///// @return _insuredContract is an addres of insured contract
    ///// @return _contractType is a type of insured contract
    ///// @return _whitelisted is a state of whitelisting
    //function info()
    //    external
    //    view
    //    returns (
    //        string memory _symbol,
    //        address _insuredContract,
    //        IPolicyBookFabric.ContractType _contractType,
    //        bool _whitelisted
    //    );
}
