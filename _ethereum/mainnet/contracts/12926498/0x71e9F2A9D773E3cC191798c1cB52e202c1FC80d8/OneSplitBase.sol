pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapFactory.sol";
import "./IUniswapV2Factory.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";
import "./IWETH.sol";

contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}

library DisableFlags {
    function check(uint256 flags, uint256 flag) internal pure returns (bool) {
        return (flags & flag) != 0;
    }
}

contract OneSplitRoot is IOneSplitView {
    using SafeMath for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20;
    using UniversalERC20 for IWETH;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    uint256 internal constant DEXES_COUNT = 3;
    IERC20 internal constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 internal constant ZERO_ADDRESS = IERC20(0);
    IWETH internal constant weth =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapFactory internal constant uniswapFactory =
        IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IUniswapV2Factory internal constant uniswapV2 =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); //Ganache: 0x88b50446977d217Eda84F28edFC514E0e17Bf351
    IUniswapV2Factory internal constant dfynExchange =
        IUniswapV2Factory(0xE7Fb3e833eFE5F9c441105EB65Ef8b261266423B);

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;

    function _findBestDistribution(
        uint256 s, // parts
        int256[][] memory amounts // exchangesReturns
    )
        internal
        pure
        returns (int256 returnAmount, uint256[] memory distribution)
    {
        uint256 n = amounts.length;

        int256[][] memory answer = new int256[][](n); // int[n][s+1]
        uint256[][] memory parent = new uint256[][](n); // int[n][s+1]

        for (uint256 i = 0; i < n; i++) {
            answer[i] = new int256[](s + 1);
            parent[i] = new uint256[](s + 1);
        }

        for (uint256 j = 0; j <= s; j++) {
            answer[0][j] = amounts[0][j];
            for (uint256 i = 1; i < n; i++) {
                answer[i][j] = -1e72;
            }
            parent[0][j] = 0;
        }

        for (uint256 i = 1; i < n; i++) {
            for (uint256 j = 0; j <= s; j++) {
                answer[i][j] = answer[i - 1][j];
                parent[i][j] = j;

                for (uint256 k = 1; k <= j; k++) {
                    if (answer[i - 1][j - k] + amounts[i][k] > answer[i][j]) {
                        answer[i][j] = answer[i - 1][j - k] + amounts[i][k];
                        parent[i][j] = j - k;
                    }
                }
            }
        }

        distribution = new uint256[](DEXES_COUNT);

        uint256 partsLeft = s;
        for (uint256 curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] =
                partsLeft -
                parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE)
            ? 0
            : answer[n - 1][s];
    }

    function _linearInterpolation(uint256 value, uint256 parts)
        internal
        pure
        returns (uint256[] memory rets)
    {
        rets = new uint256[](parts);
        for (uint256 i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function _tokensEqual(IERC20 tokenA, IERC20 tokenB)
        internal
        pure
        returns (bool)
    {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

contract OneSplitViewWrapBase is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        (returnAmount, , distribution) = this.getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return
            _getExpectedReturnRespectingGasFloor(
                fromToken,
                destToken,
                amount,
                parts,
                flags,
                destTokenEthPriceTimesGasPrice
            );
    }

    function _getExpectedReturnRespectingGasFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        internal
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );
}

contract OneSplitView is IOneSplitView, OneSplitRoot {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        public
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT);

        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }


            function(IERC20, IERC20, uint256, uint256, uint256)
                view
                returns (uint256[] memory, uint256)[DEXES_COUNT]
                memory reserves
         = _getAllReserves(flags);

        int256[][] memory matrix = new int256[][](DEXES_COUNT);
        uint256[DEXES_COUNT] memory gases;
        bool atLeastOnePositive = false;
        for (uint256 i = 0; i < DEXES_COUNT; i++) {
            uint256[] memory rets;
            (rets, gases[i]) = reserves[i](
                fromToken,
                destToken,
                amount,
                parts,
                flags
            );

            // Prepend zero and sub gas
            int256 gas = int256(
                gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18)
            );
            matrix[i] = new int256[](parts + 1);
            for (uint256 j = 0; j < rets.length; j++) {
                matrix[i][j + 1] = int256(rets[j]) - gas;
                atLeastOnePositive =
                    atLeastOnePositive ||
                    (matrix[i][j + 1] > 0);
            }
        }

        if (!atLeastOnePositive) {
            for (uint256 i = 0; i < DEXES_COUNT; i++) {
                for (uint256 j = 1; j < parts + 1; j++) {
                    if (matrix[i][j] == 0) {
                        matrix[i][j] = VERY_NEGATIVE_VALUE;
                    }
                }
            }
        }

        (, distribution) = _findBestDistribution(parts, matrix);

        (returnAmount, estimateGasAmount) = _getReturnAndGasByDistribution(
            Args({
                fromToken: fromToken,
                destToken: destToken,
                amount: amount,
                parts: parts,
                flags: flags,
                destTokenEthPriceTimesGasPrice: destTokenEthPriceTimesGasPrice,
                distribution: distribution,
                matrix: matrix,
                gases: gases,
                reserves: reserves
            })
        );
        return (returnAmount, estimateGasAmount, distribution);
    }
 
    struct Args {
        IERC20 fromToken;
        IERC20 destToken;
        uint256 amount;
        uint256 parts;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        uint256[] distribution;
        int256[][] matrix;
        uint256[DEXES_COUNT] gases;
        function(IERC20, IERC20, uint256, uint256, uint256)
            view
            returns (uint256[] memory, uint256)[DEXES_COUNT] reserves;
    }

    function _getReturnAndGasByDistribution(Args memory args)
        internal
        view
        returns (uint256 returnAmount, uint256 estimateGasAmount)
    {
        bool[DEXES_COUNT] memory exact = [
            true, // "Uniswap",
            true, // "Uniswap V2",
            true //DFYN
        ];

        for (uint256 i = 0; i < DEXES_COUNT; i++) {
            if (args.distribution[i] > 0) {
                if (
                    args.distribution[i] == args.parts ||
                    exact[i] ||
                    args.flags.check(FLAG_DISABLE_SPLIT_RECALCULATION)
                ) {
                    estimateGasAmount = estimateGasAmount.add(args.gases[i]);
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(
                        uint256(
                            (value == VERY_NEGATIVE_VALUE ? 0 : value) +
                                int256(
                                    args
                                    .gases[i]
                                    .mul(args.destTokenEthPriceTimesGasPrice)
                                    .div(1e18)
                                )
                        )
                    );
                } else {
                    (uint256[] memory rets, uint256 gas) = args.reserves[i](
                        args.fromToken,
                        args.destToken,
                        args.amount.mul(args.distribution[i]).div(args.parts),
                        1,
                        args.flags
                    );
                    estimateGasAmount = estimateGasAmount.add(gas);
                    returnAmount = returnAmount.add(rets[0]);
                }
            }
        }
    }

    function _getAllReserves(uint256 flags)
        internal
        pure
        returns (
            function(IERC20, IERC20, uint256, uint256, uint256)
                view
                returns (uint256[] memory, uint256)[DEXES_COUNT]
                memory
        )
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            invert !=
                flags.check(FLAG_DISABLE_UNISWAP_ALL | FLAG_DISABLE_UNISWAP)
                ? _calculateNoReturn
                : calculateUniswap,
            invert !=
                flags.check(
                    FLAG_DISABLE_UNISWAP_V2_ALL | FLAG_DISABLE_UNISWAP_V2
                )
                ? _calculateNoReturn
                : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_DFYN)
                ? _calculateNoReturn
                : calculateDfyn
        ];
    }

    function _calculateUniswapFormula(
        uint256 fromBalance,
        uint256 toBalance,
        uint256 amount
    ) internal pure returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        return
            amount.mul(toBalance).mul(997).div(
                fromBalance.mul(1000).add(amount.mul(997))
            );
    }

    function _calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        rets = amounts;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(
                fromToken
            );
            if (fromExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 fromTokenBalance = fromToken.universalBalanceOf(
                address(fromExchange)
            );
            uint256 fromEtherBalance = address(fromExchange).balance;

            for (uint256 i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(
                    fromTokenBalance,
                    fromEtherBalance,
                    rets[i]
                );
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange == IUniswapExchange(0)) {
                return (new uint256[](rets.length), 0);
            }

            uint256 toEtherBalance = address(toExchange).balance;
            uint256 toTokenBalance = destToken.universalBalanceOf(
                address(toExchange)
            );

            for (uint256 i = 0; i < rets.length; i++) {
                rets[i] = _calculateUniswapFormula(
                    toEtherBalance,
                    toTokenBalance,
                    rets[i]
                );
            }
        }

        return (
            rets,
            fromToken.isETH() || destToken.isETH() ? 60_000 : 100_000
        );
    }

    function calculateUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return
            _calculateUniswap(
                fromToken,
                destToken,
                _linearInterpolation(amount, parts),
                flags
            );
    }

    function calculateDfyn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return
            _calculateDfynswap(
                fromToken,
                destToken,
                _linearInterpolation(amount, parts),
                flags
            );
    }

    function calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return
            _calculateUniswapV2(
                fromToken,
                destToken,
                _linearInterpolation(amount, parts),
                flags
            );
    }

    function _calculateDfynswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = dfynExchange.getPair(
            fromTokenReal,
            destTokenReal
        );
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(
                address(exchange)
            );
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(
                address(exchange)
            );
            for (uint256 i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(
                    fromTokenBalance,
                    destTokenBalance,
                    amounts[i]
                );
            }
            return (rets, 50_000);
        }
    }

    function _calculateUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256[] memory amounts,
        uint256 /*flags*/
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 destTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(
            fromTokenReal,
            destTokenReal
        );
        if (exchange != IUniswapV2Exchange(0)) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(
                address(exchange)
            );
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(
                address(exchange)
            );
            for (uint256 i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(
                    fromTokenBalance,
                    destTokenBalance,
                    amounts[i]
                );
            }
            return (rets, 50_000);
        }
    }

    function _calculateNoReturn(
        IERC20, /*fromToken*/
        IERC20, /*destToken*/
        uint256, /*amount*/
        uint256 parts,
        uint256 /*flags*/
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}

contract OneSplitBaseWrap is IOneSplit, OneSplitRoot {
    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags // See constants in IOneSplit.sol
    ) internal {
        if (fromToken == destToken) {
            return;
        }
        //todo: check with monice
        //fromToken.universalTransferFrom(msg.sender, address(this), amount);

        // _swapFloor(
        //     fromToken,
        //     destToken,
        //     amount,
        //     distribution,
        //     flags
        // );
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256, /*flags*/ // See constants in IOneSplit.sol,
        bool isWrapper
    ) internal;
}

contract OneSplit is IOneSplit, OneSplitRoot {
    IOneSplitView public oneSplitView;

    constructor(IOneSplitView _oneSplitView) public {
        oneSplitView = _oneSplitView;
    }

    function() external payable {
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender != tx.origin);
    }

    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    )
        public
        view
        returns (uint256 returnAmount, uint256[] memory distribution)
    {
        (returnAmount, , distribution) = getExpectedReturnWithGas(
            fromToken,
            destToken,
            amount,
            parts,
            flags,
            0
        );
    }

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        return
            oneSplitView.getExpectedReturnWithGas(
                fromToken,
                destToken,
                amount,
                parts,
                flags,
                destTokenEthPriceTimesGasPrice
            );
    }
    
    function getExpectedReturnWithGasMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        returns(
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        uint256[] memory dist;

        returnAmounts = new uint256[](tokens.length - 1);
        for (uint i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                returnAmounts[i - 1] = (i == 1) ? amount : returnAmounts[i - 2];
                continue;
            }

            IERC20[] memory _tokens = tokens;

            (
                returnAmounts[i - 1],
                amount,
                dist
            ) = getExpectedReturnWithGas(
                _tokens[i - 1],
                _tokens[i],
                (i == 1) ? amount : returnAmounts[i - 2],
                parts[i - 1],
                flags[i - 1],
                destTokenEthPriceTimesGasPrices[i - 1]
            );
            estimateGasAmount = estimateGasAmount.add(amount);

            if (distribution.length == 0) {
                distribution = new uint256[](dist.length);
            }

            for (uint j = 0; j < distribution.length; j++) {
                distribution[j] = distribution[j].add(dist[j] << (8 * (i - 1)));
            }
        }
    }
    
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags,
        bool isWrapper
    ) public payable returns (uint256 returnAmount) {
        if (!isWrapper) {
            fromToken.universalTransferFrom(msg.sender, address(this), amount);
        }

        uint256 confirmed = fromToken.universalBalanceOf(address(this));

        // _swap(fromToken, destToken, confirmed, distribution, flags);
        _swapFloor(
            fromToken,
            destToken,
            confirmed,
            distribution,
            flags,
            isWrapper
        );
        returnAmount = destToken.universalBalanceOf(address(this));
        require(
            returnAmount >= minReturn,
            "OneSplit: actual return amount is less than minReturn"
        );
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(
            msg.sender,
            fromToken.universalBalanceOf(address(this))
        );
        return returnAmount;
    }

    function swapMulti(
        IERC20[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags,
        bool isWrapper
    ) public payable returns (uint256 returnAmount) {
        if (!isWrapper) {
            tokens[0].universalTransferFrom(msg.sender, address(this), amount);
        }

        returnAmount = tokens[0].universalBalanceOf(address(this));
        for (uint256 i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                continue;
            }

            uint256[] memory dist = new uint256[](distribution.length);
            for (uint256 j = 0; j < distribution.length; j++) {
                dist[j] = distribution[j]; //>> (8 * (i - 1))) & 0xFF;
            }

            _swapFloor(
                tokens[i - 1],
                tokens[i],
                returnAmount,
                dist,
                flags[i - 1],
                isWrapper
            );
            returnAmount = tokens[i].universalBalanceOf(address(this));
            tokens[i - 1].universalTransfer(
                msg.sender,
                tokens[i - 1].universalBalanceOf(address(this))
            );
        }

        require(
            returnAmount >= minReturn,
            "OneSplit: actual return amount is less than minReturn"
        );
        tokens[tokens.length - 1].universalTransfer(msg.sender, returnAmount);
    }

    function _swapFloor(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256[] memory distribution,
        uint256 flags,
        bool isWrapper
    ) internal {
        //fromToken.universalTransferFrom(msg.sender, address(this), amount);

        // fromToken.universalApprove(address(oneSplit), amount); //todo: commented as no need of multiple contracts
        _swap(fromToken, destToken, amount, 0, distribution, flags, isWrapper);
    }

    function _swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags, // See constants in IOneSplit.sol
        bool isWrapper
    ) internal returns (uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }


        function(IERC20, IERC20, uint256, uint256)[DEXES_COUNT]
            memory reserves
        = [_swapOnUniswap, _swapOnUniswapV2, _swapOnDfyn];

        require(
            distribution.length <= reserves.length,
            "OneSplit: Distribution array should not exceed reserves array size"
        );

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        if (parts == 0) {
            if (fromToken.isETH()) {
                msg.sender.transfer(msg.value);
                return msg.value;
            }
            return amount;
        }

        // fromToken.universalTransferFrom(msg.sender, address(this), amount); //todo: removed to prevent amount doubling
        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));

        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](fromToken, destToken, swapAmount, flags);
        }

        returnAmount = destToken.universalBalanceOf(address(this));
        require(
            returnAmount >= minReturn,
            "OneSplit: Return amount was not enough"
        );
        destToken.universalTransfer(msg.sender, returnAmount);
        fromToken.universalTransfer(
            msg.sender,
            fromToken.universalBalanceOf(address(this))
        );
    }

    function _swapOnUniswap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal {
        uint256 returnAmount = amount;

        if (!fromToken.isETH()) {
            IUniswapExchange fromExchange = uniswapFactory.getExchange(
                fromToken
            );
            if (fromExchange != IUniswapExchange(0)) {
                fromToken.universalApprove(address(fromExchange), returnAmount);
                returnAmount = fromExchange.tokenToEthSwapInput(
                    returnAmount,
                    1,
                    now
                );
            }
        }

        if (!destToken.isETH()) {
            IUniswapExchange toExchange = uniswapFactory.getExchange(destToken);
            if (toExchange != IUniswapExchange(0)) {
                returnAmount = toExchange.ethToTokenSwapInput.value(
                    returnAmount
                )(1, now);
            }
        }
    }

    function _swapOnDfynInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal returns (uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = dfynExchange.getPair(
            fromTokenReal,
            toTokenReal
        );
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(
            fromTokenReal,
            toTokenReal,
            amount
        );
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2Internal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 /*flags*/
    ) internal returns (uint256 returnAmount) {
        if (fromToken.isETH()) {
            weth.deposit.value(amount)();
        }

        IERC20 fromTokenReal = fromToken.isETH() ? weth : fromToken;
        IERC20 toTokenReal = destToken.isETH() ? weth : destToken;
        IUniswapV2Exchange exchange = uniswapV2.getPair(
            fromTokenReal,
            toTokenReal
        );
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(
            fromTokenReal,
            toTokenReal,
            amount
        );
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(0x68a17B587CAF4f9329f0e372e3A78D23A46De6b5);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(address(fromTokenReal)) < uint256(address(toTokenReal))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnUniswapV2(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnUniswapV2Internal(fromToken, destToken, amount, flags);
    }

    function _swapOnDfyn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 flags
    ) internal {
        _swapOnDfynInternal(fromToken, destToken, amount, flags);
    }
}
