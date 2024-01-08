//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "./console.sol";

import "./IPie.sol";
import "./IPieRegistry.sol";
import "./ILendingRegistry.sol";
import "./ILendingLogic.sol";

contract PieAssetGetter {
    address[] private tokens;
    uint256[] private amounts;

    uint256[] private indexesSmartPools;
    uint256[] private indexesExperiPies;

    address[] private assetsSmartPools;
    address[] private assetsExperiPies;
    uint256[] private amountsSmartPools;
    uint256[] private amountsExperiPies;

    IPieRegistry public globalRegistry;
    IPieRegistry public experiPieRegistry;
    IPieRegistry public smartPoolsRegistry;

    ILendingRegistry public lendingRegistry;

    enum PieType {SMART_POOL, EXPERIPIE, NONE}

    constructor(
        address _globalRegistry,
        address _experiPieRegistry,
        address _smartPoolsRegistry,
        address _lendingRegistry
    ) {
        globalRegistry = IPieRegistry(_globalRegistry);
        experiPieRegistry = IPieRegistry(_experiPieRegistry);
        smartPoolsRegistry = IPieRegistry(_smartPoolsRegistry);

        lendingRegistry = ILendingRegistry(_lendingRegistry);
    }

    function getAssetsAndAmounts(address _pie)
        external
        returns (address[] memory, uint256[] memory)
    {
        return getAssetsAndAmountsForAmount(_pie, 10e18);
    }

    function getAssetsAndAmountsForAmount(address _pie, uint256 amount)
        public
        returns (address[] memory, uint256[] memory)
    {
        require(
            globalRegistry.inRegistry(_pie),
            "PieAssetGetter: Pie not in registry"
        );

        PieType pieType = _pieType(_pie);

        (address[] memory _tokens, uint256[] memory _amounts) =
            IPie(_pie).calcTokensForAmount(amount);

        if (pieType == PieType.SMART_POOL) {
            _calcAssetsAndAmountsSmartPools(_tokens, _amounts);
        } else if (pieType == PieType.EXPERIPIE) {
            _calcAssetsAndAmountsExperiPies(_tokens, _amounts);
        }

        return (tokens, amounts);
    }

    struct TokensAndAmounts {
        address[] _tokensSmartPools;
        uint256[] _amountsSmartPools;
        address[] _tokensExperiPies;
        uint256[] _amountsExperiPies;
    }

    function _calcAssetsAndAmountsSmartPools(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        if (_tokens.length == 0) {
            return;
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            PieType pieType = _pieType(_tokens[i]);

            if (pieType == PieType.NONE) {
                tokens.push(_tokens[i]);
                amounts.push(_amounts[i]);
            } else if (pieType == PieType.SMART_POOL) {
                indexesSmartPools.push(i);
            } else {
                indexesExperiPies.push(i);
            }
        }

        TokensAndAmounts memory tokensAndAmounts =
            _tokensAndAmounts(_tokens, _amounts);

        _calcAssetsAndAmountsSmartPools(
            tokensAndAmounts._tokensSmartPools,
            tokensAndAmounts._amountsSmartPools
        );
        _calcAssetsAndAmountsExperiPies(
            tokensAndAmounts._tokensExperiPies,
            tokensAndAmounts._amountsExperiPies
        );
    }

    function _calcAssetsAndAmountsExperiPies(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal {
        if (_tokens.length == 0) {
            return;
        }

        for (uint256 i = 0; i < _tokens.length; i++) {
            PieType pieType = _pieType(_tokens[i]);

            if (pieType == PieType.NONE) {
                (address _t, uint256 _a) =
                    _getUnderlyingAssetAndAmount(_tokens[i], _amounts[i]);

                tokens.push(_t);
                amounts.push(_a);
            } else if (pieType == PieType.SMART_POOL) {
                indexesSmartPools.push(i);
            } else {
                indexesExperiPies.push(i);
            }
        }

        TokensAndAmounts memory tokensAndAmounts =
            _tokensAndAmounts(_tokens, _amounts);

        _calcAssetsAndAmountsSmartPools(
            tokensAndAmounts._tokensSmartPools,
            tokensAndAmounts._amountsSmartPools
        );
        _calcAssetsAndAmountsExperiPies(
            tokensAndAmounts._tokensExperiPies,
            tokensAndAmounts._amountsExperiPies
        );
    }

    function _tokensAndAmounts(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal returns (TokensAndAmounts memory tokensAndAmounts) {
        for (uint256 i = 0; i < indexesSmartPools.length; i++) {
            (address[] memory _t, uint256[] memory _a) =
                IPie(_tokens[indexesSmartPools[i]]).calcTokensForAmount(
                    _amounts[indexesSmartPools[i]]
                );

            for (uint256 j = 0; j < _t.length; j++) {
                assetsSmartPools.push(_t[j]);
                amountsSmartPools.push(_a[j]);
            }
        }

        for (uint256 i = 0; i < indexesExperiPies.length; i++) {
            (address[] memory _t, uint256[] memory _a) =
                IPie(_tokens[indexesExperiPies[i]]).calcTokensForAmount(
                    _amounts[indexesExperiPies[i]]
                );

            for (uint256 j = 0; j < _t.length; j++) {
                assetsExperiPies.push(_t[j]);
                amountsExperiPies.push(_a[j]);
            }
        }

        tokensAndAmounts._tokensSmartPools = assetsSmartPools;
        tokensAndAmounts._amountsSmartPools = amountsSmartPools;
        tokensAndAmounts._tokensExperiPies = assetsExperiPies;
        tokensAndAmounts._amountsExperiPies = amountsExperiPies;

        delete indexesExperiPies;
        delete indexesSmartPools;
        delete assetsExperiPies;
        delete assetsSmartPools;
        delete amountsExperiPies;
        delete assetsSmartPools;
    }

    function _getUnderlyingAssetAndAmount(address _wrapped, uint256 _amount)
        internal
        returns (address token, uint256 amount)
    {
        token = lendingRegistry.wrappedToUnderlying(_wrapped);

        if (token == address(0)) {
            token = _wrapped;
            amount = _amount;
        } else {
            ILendingLogic lendingLogic = getLendingLogicFromWrapped(_wrapped);
            amount = (_amount * lendingLogic.exchangeRate(_wrapped)) / 1e18;
        }
    }

    function _pieType(address _pie) internal view returns (PieType) {
        if (smartPoolsRegistry.inRegistry(_pie)) {
            return PieType.SMART_POOL;
        } else if (experiPieRegistry.inRegistry(_pie)) {
            return PieType.EXPERIPIE;
        } else {
            return PieType.NONE;
        }
    }

    function getLendingLogicFromWrapped(address _wrapped)
        internal
        view
        returns (ILendingLogic)
    {
        return
            ILendingLogic(
                lendingRegistry.protocolToLogic(
                    lendingRegistry.wrappedToProtocol(_wrapped)
                )
            );
    }
}
