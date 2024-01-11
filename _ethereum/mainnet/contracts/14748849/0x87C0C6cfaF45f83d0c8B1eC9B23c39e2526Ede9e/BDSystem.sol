// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./SafeERC20.sol";

import "./ErrorCodes.sol";
import "./Supervisor.sol";
import "./Buyback.sol";
import "./Mnt.sol";

contract BDSystem is AccessControl {
    uint256 internal constant EXP_SCALE = 1e18;
    using SafeERC20 for Mnt;

    struct Agreement {
        /// Emission boost for liquidity provider
        uint256 liquidityProviderBoost;
        /// Percentage of the total emissions earned by the representative
        uint256 representativeBonus;
        /// The number of the block in which agreement ends.
        uint32 endBlock;
        /// Business Development Representative
        address representative;
    }
    /// Linking the liquidity provider with the agreement
    mapping(address => Agreement) public providerToAgreement;
    /// Counts liquidity providers of the representative
    mapping(address => uint256) public representativesProviderCounter;

    Supervisor public supervisor;

    event AgreementAdded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 startBlock,
        uint32 endBlock
    );
    event AgreementEnded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 endBlock
    );

    constructor(address admin_, Supervisor supervisor_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        supervisor = supervisor_;
    }

    /*** Admin functions ***/

    /**
     * @notice Creates a new agreement between liquidity provider and representative
     * @dev Admin function to create a new agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the liquidity provider representative.
     * @param representativeBonus_ percentage of the emission boost for representative
     * @param liquidityProviderBoost_ percentage of the boost for liquidity provider
     * @param endBlock_ The number of the first block when agreement will not be in effect
     */
    function createAgreement(
        address liquidityProvider_,
        address representative_,
        uint256 representativeBonus_,
        uint256 liquidityProviderBoost_,
        uint32 endBlock_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // (1 + liquidityProviderBoost) * (1 + representativeBonus) <= 150%
        require(
            (EXP_SCALE + liquidityProviderBoost_) * (EXP_SCALE + representativeBonus_) <= 1.5e36,
            ErrorCodes.EC_INVALID_BOOSTS
        );
        // one account at one time can be a liquidity provider once,
        require(!isAccountLiquidityProvider(liquidityProvider_), ErrorCodes.EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER);
        // one account can't be a liquidity provider and a representative at the same time
        require(
            !isAccountRepresentative(liquidityProvider_) && !isAccountLiquidityProvider(representative_),
            ErrorCodes.EC_PROVIDER_CANT_BE_REPRESENTATIVE
        );

        // we are distribution MNT tokens for liquidity provider
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        supervisor.distributeAllMnt(liquidityProvider_);

        // we are creating agreement between liquidity provider and representative
        providerToAgreement[liquidityProvider_] = Agreement({
            representative: representative_,
            liquidityProviderBoost: liquidityProviderBoost_,
            representativeBonus: representativeBonus_,
            endBlock: endBlock_
        });
        representativesProviderCounter[representative_]++;

        emit AgreementAdded(
            liquidityProvider_,
            representative_,
            representativeBonus_,
            liquidityProviderBoost_,
            uint32(_getBlockNumber()),
            endBlock_
        );
    }

    /**
     * @notice Removes a agreement between liquidity provider and representative
     * @dev Admin function to remove a agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the representative.
     */
    function removeAgreement(address liquidityProvider_, address representative_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        Agreement storage agreement = providerToAgreement[liquidityProvider_];
        require(agreement.representative == representative_, ErrorCodes.EC_INVALID_PROVIDER_REPRESENTATIVE);

        emit AgreementEnded(
            liquidityProvider_,
            representative_,
            agreement.representativeBonus,
            agreement.liquidityProviderBoost,
            agreement.endBlock
        );

        // We call emission system for liquidity provider, so liquidity provider and his representative will accrue
        // MNT tokens with their emission boosts
        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign
        supervisor.distributeAllMnt(liquidityProvider_);

        // We remove agreement between liquidity provider and representative
        delete providerToAgreement[liquidityProvider_];
        representativesProviderCounter[representative_]--;
    }

    /*** Helper special functions ***/

    /**
     * @notice Calculates boosts for liquidity provider and representative.
     * @param liquidityProvider_ address of the liquidity provider,
     * @param deltaIndex_ difference between the current MNT index and the index of the last update for
     *        the liquidity provider
     */
    function calculateEmissionBoost(address liquidityProvider_, uint256 deltaIndex_)
        public
        view
        returns (
            address representative,
            uint256 representativeBonus,
            uint256 providerBoostedIndex
        )
    {
        // get a representative for the account_ and his representative bonus
        Agreement storage agreement = providerToAgreement[liquidityProvider_];
        representative = agreement.representative;

        // if account isn't liquidity provider we return from method.
        if (representative == address(0)) return (address(0), 0, 0);

        representativeBonus = agreement.representativeBonus;
        providerBoostedIndex = (deltaIndex_ * agreement.liquidityProviderBoost) / EXP_SCALE;
    }

    /**
     * @notice checks if `account_` is liquidity provider.
     * @dev account_ is liquidity provider if he has agreement.
     * @param account_ address to check
     * @return `true` if `account_` is liquidity provider, otherwise returns false
     */
    function isAccountLiquidityProvider(address account_) public view returns (bool) {
        return providerToAgreement[account_].representative != address(0);
    }

    /**
     * @notice checks if `account_` is business development representative.
     * @dev account_ is business development representative if he has liquidity providers.
     * @param account_ address to check
     * @return `true` if `account_` is business development representative, otherwise returns false
     */
    function isAccountRepresentative(address account_) public view returns (bool) {
        return representativesProviderCounter[account_] > 0;
    }

    /**
     * @notice checks if agreement is expired
     * @dev reverts if the `account_` is not a valid liquidity provider
     * @param account_ address of the liquidity provider
     * @return `true` if agreement is expired, otherwise returns false
     */
    function isAgreementExpired(address account_) external view returns (bool) {
        require(isAccountLiquidityProvider(account_), ErrorCodes.EC_ACCOUNT_HAS_NO_AGREEMENT);
        return providerToAgreement[account_].endBlock <= _getBlockNumber();
    }

    /// @dev Function to simply retrieve block number
    ///      This exists mainly for inheriting test contracts to stub this result.
    // slither-disable-next-line dead-code
    function _getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}
