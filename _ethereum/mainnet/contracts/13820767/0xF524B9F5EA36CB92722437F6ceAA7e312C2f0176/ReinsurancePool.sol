// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "./OwnableUpgradeable.sol";

import "./AbstractLeveragePortfolio.sol";
import "./IReinsurancePool.sol";
import "./IBMIStaking.sol";

contract ReinsurancePool is AbstractLeveragePortfolio, IReinsurancePool, OwnableUpgradeable {
    using SafeERC20 for ERC20;

    IERC20 public bmiToken;
    ERC20 public stblToken;
    IBMIStaking public bmiStaking;

    address public claimVotingAddress;

    uint256 public stblDecimals;

    address public aaveProtocol;
    address public compoundProtocol;
    address public yearnProtocol;

    event Recovered(address tokenAddress, uint256 tokenAmount);
    event STBLWithdrawn(address user, uint256 amount);
    event DefiInterestAdded(uint256 interestAmount);

    modifier onlyClaimVoting() {
        require(claimVotingAddress == _msgSender(), "RP: Caller is not a ClaimVoting contract");
        _;
    }

    modifier onlyDefiProtocols() {
        require(
            aaveProtocol == _msgSender() ||
                compoundProtocol == _msgSender() ||
                yearnProtocol == _msgSender(),
            "RP: Caller is not a defi protocols contract"
        );
        _;
    }

    function __ReinsurancePool_init() external initializer {
        __LeveragePortfolio_init();
        __Ownable_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        stblToken = ERC20(_contractsRegistry.getUSDTContract());
        bmiStaking = IBMIStaking(_contractsRegistry.getBMIStakingContract());
        bmiToken = IERC20(_contractsRegistry.getBMIContract());
        capitalPool = ICapitalPool(_contractsRegistry.getCapitalPoolContract());
        claimVotingAddress = _contractsRegistry.getClaimVotingContract();
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        compoundProtocol = _contractsRegistry.getCompoundProtocolContract();
        aaveProtocol = _contractsRegistry.getAaveProtocolContract();
        yearnProtocol = _contractsRegistry.getYearnProtocolContract();
        leveragePortfolioView = ILeveragePortfolioView(
            _contractsRegistry.getLeveragePortfolioViewContract()
        );
        policyBookAdmin = _contractsRegistry.getPolicyBookAdminContract();
        stblDecimals = stblToken.decimals();
    }

    function withdrawBMITo(address to, uint256 amount) external override onlyClaimVoting {
        bmiToken.transfer(to, amount);
    }

    function withdrawSTBLTo(address to, uint256 amount) external override onlyClaimVoting {
        stblToken.safeTransfer(to, DecimalsConverter.convertFrom18(amount, stblDecimals));

        emit STBLWithdrawn(to, amount);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);

        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @notice add the 20% of premium + portion of 80% of premium where reisnurance pool participate in coverage pools (vStable)
    /// @dev access CapitalPool
    /// @param  premiumAmount uint256 the premium amount which is 20% of premium + portion of 80%
    function addPolicyPremium(uint256, uint256 premiumAmount) external override onlyCapitalPool {
        totalLiquidity += premiumAmount;

        emit PremiumAdded(premiumAmount);
    }

    /// @notice add the interest amount from defi protocol : access defi protocols
    /// @param  interestAmount uint256 the interest amount from defi protocols
    function addInterestFromDefiProtocols(uint256 interestAmount)
        external
        override
        onlyDefiProtocols
    {
        uint256 amount = DecimalsConverter.convertTo18(interestAmount, stblDecimals);
        totalLiquidity += amount;

        capitalPool.addReinsurancePoolHardSTBL(interestAmount);

        _reevaluateProvidedLeverageStable(LeveragePortfolio.REINSURANCEPOOL, amount);

        emit DefiInterestAdded(amount);
    }
}
