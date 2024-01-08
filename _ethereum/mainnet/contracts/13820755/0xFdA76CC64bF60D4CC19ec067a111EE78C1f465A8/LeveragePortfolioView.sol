// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";

import "./ILeveragePortfolioView.sol";
import "./IPolicyBookFacade.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./IPolicyQuote.sol";

import "./AbstractDependant.sol";
import "./Globals.sol";

contract LeveragePortfolioView is ILeveragePortfolioView, AbstractDependant {
    using SafeMath for uint256;

    uint256 public constant SAFE_MIN_UR = 16 * PRECISION; // 16%

    uint256 public constant RISKY_MIN_UR = 64 * 10**24; //6.4%

    IPolicyBookRegistry public policyBookRegistry;

    //new state post v2 deployment
    IPolicyQuote public policyQuote;

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );

        policyQuote = IPolicyQuote(_contractsRegistry.getPolicyQuoteContract());
    }

    /// @notice calc M factor by formual M = min( abs((1/ (Tur-UR))*d) /a, max)
    /// @param poolUR uint256 utitilization ratio for a coverage pool
    /// @return uint256 M facotr
    function calcM(uint256 poolUR, address leveragePoolAddress)
        external
        view
        override
        returns (uint256)
    {
        ILeveragePortfolio leveragePool = ILeveragePortfolio(leveragePoolAddress);
        uint256 _targetUR = leveragePool.targetUR();

        uint256 _PRECISION = 10**27;
        uint256 _ur;
        if (_targetUR > poolUR) {
            _ur = _targetUR.sub(poolUR);
        } else {
            _ur = poolUR.sub(_targetUR);
        }

        uint256 _multiplier =
            Math.min(
                leveragePool.d_ProtocolConstant().mul(_PRECISION).div(_ur).mul(_PRECISION).div(
                    leveragePool.a_ProtocolConstant()
                ),
                leveragePool.max_ProtocolConstant()
            );

        return _multiplier;
    }

    /// @dev If Formula 1 < 0 or Formula 1 causes dividing by 0, then the system will use Formula 2.
    /// Otherwise, it is always the lowest amount calculated by Formula1 or Formula2.
    function calcMaxLevFunds(ILeveragePortfolio.LevFundsFactors memory factors)
        public
        view
        override
        returns (uint256)
    {
        IPolicyBook _coveragepool = IPolicyBook(factors.policyBookAddr);

        uint256 _poolTotalLiquidity = _coveragepool.totalLiquidity();
        uint256 _totalCoverTokens = _coveragepool.totalCoverTokens();
        uint256 _poolUR;
        if (_poolTotalLiquidity > 0) {
            _poolUR = _totalCoverTokens.mul(PERCENTAGE_100).div(_poolTotalLiquidity);
        }
        uint256 _minUR = _getPoolMINUR(factors.policyBookAddr);

        uint256 _formula2;

        uint256 _ur = Math.max(_poolUR, _minUR);

        uint256 _res1 = _poolUR.mul(_poolTotalLiquidity).div(PERCENTAGE_100);
        uint256 _res2 = _ur.mul(_poolTotalLiquidity).div(_minUR);

        if (_res2 > _poolTotalLiquidity && factors.netMPL > 0) {
            _formula2 = (_res2.sub(_poolTotalLiquidity)).mul(factors.netMPL).div(
                factors.netMPL.add(factors.netMPLn)
            );
        }

        if (_res1 > factors.netMPL) {
            uint256 _formula1 = _res1.sub(factors.netMPL);
            _formula1 = factors.netMPL.mul(_poolTotalLiquidity).div(_formula1);

            return Math.min(_formula1, _formula2);
        } else {
            return _formula2;
        }
    }

    function calcvStableFormulaforAllPools() internal view returns (uint256) {
        uint256 _coveragePoolCount = policyBookRegistry.count();
        address[] memory _policyBooksArr = policyBookRegistry.list(0, _coveragePoolCount);

        uint256 sum;
        for (uint256 i = 0; i < _policyBooksArr.length; i++) {
            if (policyBookRegistry.isUserLeveragePool(_policyBooksArr[i])) continue;
            sum += calcvStableFormulaforOnePool(_policyBooksArr[i]);
        }
        return sum;
    }

    function calcvStableFormulaforOnePool(address _policybookAddress)
        internal
        view
        returns (uint256)
    {
        uint256 res;

        IPolicyBook _policyBook = IPolicyBook(_policybookAddress);

        uint256 _poolTotalLiquidity = _policyBook.totalLiquidity();
        uint256 _poolCoverToken = _policyBook.totalCoverTokens();

        if (
            _poolTotalLiquidity == 0 ||
            _poolCoverToken == 0 ||
            getPolicyBookFacade(_policybookAddress).reinsurancePoolMPL() == 0
        ) return res;

        uint256 _poolUR = _poolCoverToken.mul(PERCENTAGE_100).div(_poolTotalLiquidity);
        res = (_poolUR).mul(_poolTotalLiquidity).div(PERCENTAGE_100).mul(_poolUR).div(
            PERCENTAGE_100
        );

        return res;
    }

    function calcBMIMultiplier(IUserLeveragePool.BMIMultiplierFactors memory factors)
        external
        view
        override
        returns (uint256)
    {
        return
            factors
                .poolMultiplier
                .mul(factors.leverageProvided)
                .mul(factors.multiplier)
                .div(PERCENTAGE_100)
                .mul(ILeveragePortfolio(msg.sender).a_ProtocolConstant())
                .div(PERCENTAGE_100)
                .div(10**3);
    }

    /// @notice Returns the policybook facade that stores the leverage storage from a policybook
    /// @param _policybookAddress address of the policybook
    /// @return _coveragePool
    function getPolicyBookFacade(address _policybookAddress)
        public
        view
        override
        returns (IPolicyBookFacade _coveragePool)
    {
        IPolicyBook _policyBook = IPolicyBook(_policybookAddress);
        _coveragePool = IPolicyBookFacade(_policyBook.policyBookFacade());
    }

    function calcNetMPLn(
        ILeveragePortfolio.LeveragePortfolio leveragePoolType,
        address _policyBookFacade
    ) public view override returns (uint256 _netMPLn) {
        address[] memory _userLeverageArr =
            policyBookRegistry.listByType(
                IPolicyBookFabric.ContractType.VARIOUS,
                0,
                policyBookRegistry.countByType(IPolicyBookFabric.ContractType.VARIOUS)
            );

        for (uint256 i = 0; i < _userLeverageArr.length; i++) {
            if (leveragePoolType == ILeveragePortfolio.LeveragePortfolio.USERLEVERAGEPOOL) {
                if (_userLeverageArr[i] == address(msg.sender)) continue;
            }
            _netMPLn += ILeveragePortfolio(_userLeverageArr[i])
                .totalLiquidity()
                .mul(IPolicyBookFacade(_policyBookFacade).userleveragedMPL())
                .div(PERCENTAGE_100);
        }
    }

    function calcMaxVirtualFunds(address policyBookAddress)
        external
        view
        override
        returns (uint256 _amountToDeploy, uint256 _maxAmount)
    {
        IPolicyBookFacade _policyBookFacade = getPolicyBookFacade(policyBookAddress);
        uint256 _mpl = _policyBookFacade.reinsurancePoolMPL();

        uint256 _netMPL =
            _mpl.mul(ILeveragePortfolio(msg.sender).totalLiquidity()).div(PERCENTAGE_100);

        uint256 _netMPLn =
            calcNetMPLn(
                ILeveragePortfolio.LeveragePortfolio.REINSURANCEPOOL,
                address(_policyBookFacade)
            );

        _maxAmount = calcMaxLevFunds(
            ILeveragePortfolio.LevFundsFactors(_netMPL, _netMPLn, policyBookAddress)
        );

        uint256 result1 = calcvStableFormulaforOnePool(policyBookAddress);

        uint256 result2 = calcvStableFormulaforAllPools();

        if (result2 != 0) {
            _amountToDeploy = result1.mul(ILeveragePortfolio(msg.sender).totalLiquidity()).div(
                result2
            );
        }
    }

    function _getPoolMINUR(address policyBookAddr) internal view returns (uint256 _minUR) {
        IPolicyBookFacade _policyBookFacade = getPolicyBookFacade(policyBookAddr);
        _minUR = policyQuote.getMINUR(_policyBookFacade.safePricingModel());
    }
}
