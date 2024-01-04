pragma experimental ABIEncoderV2;
pragma solidity 0.6.4;

import "./UniswapV2BalRecipe.sol";

import "./IAaveLendingPool.sol";
import "./IAaveLendingPoolAddressProvider.sol";
import "./ICompoundCToken.sol";
import "./IERC20.sol";
import "./ILendingRegistry.sol";
import "./ILendingLogic.sol";

import "./SafeMath.sol";

contract InterestingRecipe is UniswapV2BalRecipe {
    using SafeMath for uint256;

    ILendingRegistry public lendingRegistry;

    constructor(address _lendingRegistry) public {
        lendingRegistry = ILendingRegistry(_lendingRegistry);
    }

    function _swapToToken(
        address _wrapped,
        uint256 _amount,
        address _pie
    ) internal override {
        address underlying = lendingRegistry.wrappedToUnderlying(_wrapped);

        if (underlying != address(0)) {
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_wrapped);
            uint256 exchangeRate = lendingLogic.exchangeRate(_wrapped); // wrapped to underlying
            uint256 underlyingAmount = _amount.mul(exchangeRate).div(10**18).add(1);

            super._swapToToken(underlying, underlyingAmount, _pie);

            (address[] memory targets, bytes[] memory data) = lendingLogic.lend(underlying, underlyingAmount);

            // Do lend txs
            for(uint256 i = 0; i < targets.length; i ++) {
                (bool success, ) = targets[i].call{ value: 0 }(data[i]);
                require(success, "CALL_FAILED");
            }

            IERC20(_wrapped).safeApprove(_pie, _amount);
        } else {
            super._swapToToken(_wrapped, _amount, _pie);
        }
    }

    function calcEthAmount(address _wrapped, uint256 _buyAmount)
        internal
        override
        returns (uint256)
    {
        address underlying = lendingRegistry.wrappedToUnderlying(_wrapped);

        if (underlying != address(0)) {
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_wrapped);
            uint256 exchangeRate = lendingLogic.exchangeRate(_wrapped); // wrapped to underlying
            uint256 underlyingAmount = _buyAmount.mul(exchangeRate).div(10**18).add(1);
            return super.calcEthAmount(underlying, underlyingAmount);

        } else if (registry.inRegistry(_wrapped)) {
            return calcToPie(_wrapped, _buyAmount);
        } else {
            return super.calcEthAmount(_wrapped, _buyAmount);
        }
    }
    function calcToPie(address _pie, uint256 _poolAmount)
        public
        override
        returns (uint256)
    {
        (address[] memory tokens, uint256[] memory amounts) = IPSmartPool(_pie)
            .calcTokensForAmount(_poolAmount);

        uint256 totalEth = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (lendingRegistry.wrappedToUnderlying(tokens[i]) != address(0)) {
                totalEth += calcEthAmount(tokens[i], amounts[i]);
            } else if (registry.inRegistry(tokens[i])) {
                totalEth += calcToPie(tokens[i], amounts[i]);
            } else {
                // (uint256 reserveA, uint256 reserveB) = UniLib.getReserves(
                //     address(uniswapFactory),
                //     address(WETH),
                //     tokens[i]
                // );
                // totalEth += UniLib.getAmountIn(amounts[i], reserveA, reserveB);
                totalEth += super.calcEthAmount(tokens[i], amounts[i]);
            }
        }
        return totalEth;
    }

    function getLendingLogicFromWrapped(address _wrapped) internal view returns(ILendingLogic) {
        return ILendingLogic(
                lendingRegistry.protocolToLogic(
                    lendingRegistry.wrappedToProtocol(
                        _wrapped
                    )
                )
        );
    }
}
