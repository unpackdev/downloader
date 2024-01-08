// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./BoilerplateStrategy.sol";
import "./CompoundInteractor.sol";

import "./ComptrollerInterface.sol";
import "./CTokenInterfaces.sol";
import "./IUniswapV2Router02.sol";

contract CompoundNoFoldStrategy is BoilerplateStrategy, CompoundInteractor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public uniswapRouter;

    constructor(
        address _vault,
        address _underlying,
        address _strategist,
        address _ctoken,
        address _uniswap        
    ) public
      BoilerplateStrategy(_vault, _underlying, _strategist)
      CompoundInteractor(_ctoken)
    {           
        uniswapRouter = _uniswap;

        // set these tokens to be not salvagable
        unsalvageableTokens[underlying] = true;
        unsalvageableTokens[ctoken] = true;
        unsalvageableTokens[comp] = true;
    }

    /*****
     * VIEW INTERFACE
     *****/

    function getNameStrategy() external view override returns(string memory){
      return "CompoundNoFoldStrategy";
    }

    function want() external override view returns(address){
      return address(underlying);
    }

    /**
     * Returns the current balance. Ignores COMP/CREAM that was not liquidated and invested.
     */
    function balanceOf() external override view returns (uint256) {
        uint256 currentCbal = IERC20(ctoken).balanceOf(address(this));
        //The current exchange rate as an unsigned integer, scaled by 1e18.
        uint256 suppliedInUnderlying = currentCbal.mul(CTokenInterface(ctoken).exchangeRateStored()).div(1e18);

        return IERC20(underlying).balanceOf(address(this)).add(suppliedInUnderlying);
    }


    /*****
     * DEPOSIT/WITHDRAW/HARVEST EXTERNAL
     *****/

    /**
     * The strategy invests by supplying the underlying as a collateral.
     */
    function deposit() public override restricted {
        _compoundSupply();
    }


    function withdraw(uint256 amount) external override restricted {
        require(amount > 0, "Incorrect amount");
        if (harvestOnWithdraw && liquidationAllowed) {
            claimComp();
            liquidateComp();
        }

        uint256 balanceUnderlying = CTokenInterface(ctoken).balanceOfUnderlying(address(this));
        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        uint256 total = balanceUnderlying.add(looseBalance);

        if (amount > total) {
            //cant withdraw more than we own
            amount = total;
        }

        if (looseBalance >= amount) {
            IERC20(underlying).safeTransfer(vault, amount);
            return;
        }

        uint256 toWithdraw = amount.sub(looseBalance);
        _compoundRedeemUnderlying(toWithdraw);

        looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, looseBalance);
    }

    /**
     * Exits Compound and transfers everything to the vault.
     */
    function withdrawAll() external override restricted {
        if (harvestOnWithdraw && liquidationAllowed) {
            claimComp();
            liquidateComp();
        }

        _compoundRedeem(CTokenInterface(ctoken).balanceOf(address(this)));

        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(vault, looseBalance);
    }


    function emergencyExit() external onlyGovernance {
        _compoundRedeem(CTokenInterface(ctoken).balanceOf(address(this)));

        uint256 looseBalance = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeTransfer(IVault(vault).governance(), looseBalance);
    }


    /**
     * Withdraws all assets, liquidates COMP/CREAM, and invests again in the required ratio.
     */
    function earn() public restricted {
        if (liquidationAllowed) {
            claimComp();
            liquidateComp();
        }
        
        deposit();
    }

    function claimComp() public { 
        ComptrollerInterface(comptroller).updateContributorRewards(address(this));
        ComptrollerInterface(comptroller).claimComp(address(this));
    }

    function liquidateComp() public {
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        uint256 balance = IERC20(comp).balanceOf(address(this));
        if (balance < sellFloor) {
            return;
        }

        IERC20(comp).safeApprove(address(uniswapRouter), 0);
        IERC20(comp).safeApprove(address(uniswapRouter), balance);

        address[] memory path = new address[](3);
        path[0] = comp;
        path[1] = IUniswapV2Router02(uniswapRouter).WETH();
        path[2] = address(underlying);
        IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp + 10
        );

        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

        _profitSharing(balanceAfter.sub(balanceBefore));
    }

    function convert(address) external override returns(uint256){
      return 0;
    }

    function skim() external override {
      return;
    }
}
