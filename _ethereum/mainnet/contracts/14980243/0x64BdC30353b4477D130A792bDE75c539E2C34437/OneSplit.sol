// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IUniswapFactory.sol";
import "./IUniswapV2Factory.sol";
import "./IHandlerReserve.sol";
import "./IEthHandler.sol";
import "./IBridge.sol";
import "./IOneSplit.sol";
import "./UniversalERC20.sol";
import "./IWETH.sol";
import "./TransferHelper.sol";

import "./console.sol";

abstract contract IOneSplitView is IOneSplitConsts {
    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view virtual returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        virtual
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

contract OneSplitRoot {
    using SafeMathUpgradeable for uint256;
    using DisableFlags for uint256;

    using UniversalERC20 for IERC20Upgradeable;
    using UniversalERC20 for IWETH;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;

    uint256 internal constant DEXES_COUNT = 4;
    uint256 internal constant DEXES_COUNT_UPDATED = 6;
    IERC20Upgradeable internal constant ZERO_ADDRESS = IERC20Upgradeable(0x0000000000000000000000000000000000000000);

    IUniswapV2Factory internal constant uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Factory internal constant dfynExchange = IUniswapV2Factory(0xefa94DE7a4656D787667C749f7E1223D71E9FD88);
    IUniswapV2Factory internal constant pancakeSwap = IUniswapV2Factory(0xEF45d134b73241eDa7703fa787148D9C9F4950b0);
    IUniswapV2Factory internal constant quickSwap = IUniswapV2Factory(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10);
    IUniswapV2Factory internal constant sushiSwap = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    address internal constant oneInchSwap = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    IERC20Upgradeable internal constant NATIVE_ADDRESS = IERC20Upgradeable(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IWETH internal constant wnative = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;
    address internal constant skimAddress = 0xb599a1e294Ec6608d68987fC9A2d4d155eEd9160;

    function _findBestDistribution(
        uint256 s, // parts
        int256[][] memory amounts // exchangesReturns
    ) internal pure returns (int256 returnAmount, uint256[] memory distribution) {
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

        distribution = new uint256[](DEXES_COUNT_UPDATED);

        uint256 partsLeft = s;
        for (uint256 curExchange = n - 1; partsLeft > 0; curExchange--) {
            distribution[curExchange] = partsLeft - parent[curExchange][partsLeft];
            partsLeft = parent[curExchange][partsLeft];
        }

        returnAmount = (answer[n - 1][s] == VERY_NEGATIVE_VALUE) ? int256(0) : answer[n - 1][s];
    }

    function _linearInterpolation(uint256 value, uint256 parts) internal pure returns (uint256[] memory rets) {
        rets = new uint256[](parts);
        for (uint256 i = 0; i < parts; i++) {
            rets[i] = value.mul(i + 1).div(parts);
        }
    }

    function _tokensEqual(IERC20Upgradeable tokenA, IERC20Upgradeable tokenB) internal pure returns (bool) {
        return ((tokenA.isETH() && tokenB.isETH()) || tokenA == tokenB);
    }
}

contract OneSplitView is Initializable, IOneSplitView, OneSplitRoot, UUPSUpgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;
    using DisableFlags for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using UniversalERC20 for IERC20Upgradeable;

    function initialize() public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    ) public view override returns (uint256 returnAmount, uint256[] memory distribution) {
        (returnAmount, , distribution) = getExpectedReturnWithGas(fromToken, destToken, amount, parts, flags, 0);
    }

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        override
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        distribution = new uint256[](DEXES_COUNT_UPDATED);

        if (fromToken == destToken) {
            return (amount, 0, distribution);
        }

        function(IERC20Upgradeable, IERC20Upgradeable, uint256, uint256)
            view
            returns (uint256[] memory, uint256)[DEXES_COUNT_UPDATED]
            memory reserves = _getAllReserves(flags);

        int256[][] memory matrix = new int256[][](DEXES_COUNT_UPDATED);
        uint256[DEXES_COUNT_UPDATED] memory gases;
        bool atLeastOnePositive = false;
        for (uint256 i = 0; i < DEXES_COUNT_UPDATED; i++) {
            uint256[] memory rets;
            (rets, gases[i]) = reserves[i](fromToken, destToken, amount, parts);

            // Prepend zero and sub gas
            int256 gas = int256(gases[i].mul(destTokenEthPriceTimesGasPrice).div(1e18));
            matrix[i] = new int256[](parts + 1);
            for (uint256 j = 0; j < rets.length; j++) {
                matrix[i][j + 1] = int256(rets[j]) - gas;
                atLeastOnePositive = atLeastOnePositive || (matrix[i][j + 1] > 0);
            }
        }

        if (!atLeastOnePositive) {
            for (uint256 i = 0; i < DEXES_COUNT_UPDATED; i++) {
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
        IERC20Upgradeable fromToken;
        IERC20Upgradeable destToken;
        uint256 amount;
        uint256 parts;
        uint256 flags;
        uint256 destTokenEthPriceTimesGasPrice;
        uint256[] distribution;
        int256[][] matrix;
        uint256[DEXES_COUNT_UPDATED] gases;
        function(IERC20Upgradeable, IERC20Upgradeable, uint256, uint256)
            view
            returns (uint256[] memory, uint256)[DEXES_COUNT_UPDATED] reserves;
    }

    function _getReturnAndGasByDistribution(Args memory args)
        internal
        view
        returns (uint256 returnAmount, uint256 estimateGasAmount)
    {
        bool[DEXES_COUNT_UPDATED] memory exact = [
            true, //empty
            true, // "Uniswap V2",
            true, // DFYN
            true, // pancake swap
            true, // quickswap
            true // sushi
        ];

        for (uint256 i = 0; i < DEXES_COUNT_UPDATED; i++) {
            if (args.distribution[i] > 0) {
                if (
                    args.distribution[i] == args.parts || exact[i] || args.flags.check(FLAG_DISABLE_SPLIT_RECALCULATION)
                ) {
                    estimateGasAmount = estimateGasAmount.add(args.gases[i]);
                    int256 value = args.matrix[i][args.distribution[i]];
                    returnAmount = returnAmount.add(
                        uint256(
                            (value == VERY_NEGATIVE_VALUE ? int256(0) : value) +
                                int256(args.gases[i].mul(args.destTokenEthPriceTimesGasPrice).div(1e18))
                        )
                    );
                } else {
                    (uint256[] memory rets, uint256 gas) = args.reserves[i](
                        args.fromToken,
                        args.destToken,
                        args.amount.mul(args.distribution[i]).div(args.parts),
                        1
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
            function(IERC20Upgradeable, IERC20Upgradeable, uint256, uint256)
                view
                returns (uint256[] memory, uint256)[DEXES_COUNT_UPDATED]
                memory
        )
    {
        bool invert = flags.check(FLAG_DISABLE_ALL_SPLIT_SOURCES);
        return [
            _calculateNoReturn,
            invert != flags.check(FLAG_DISABLE_UNISWAP_V2_ALL) ? _calculateNoReturn : calculateUniswapV2,
            invert != flags.check(FLAG_DISABLE_DFYN) ? _calculateNoReturn : calculateDfyn,
            invert != flags.check(FLAG_DISABLE_PANCAKESWAP) ? _calculateNoReturn : calculatePancakeSwap,
            invert != flags.check(FLAG_DISABLE_QUICKSWAP) ? _calculateNoReturn : calculateQuickSwap,
            invert != flags.check(FLAG_DISABLE_SUSHISWAP) ? _calculateNoReturn : calculateSushiSwap
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
        return amount.mul(toBalance).mul(997).div(fromBalance.mul(1000).add(amount.mul(997)));
    }

    function calculateDfyn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return _calculateSwap(fromToken, destToken, _linearInterpolation(amount, parts), dfynExchange);
    }

    function calculatePancakeSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return _calculateSwap(fromToken, destToken, _linearInterpolation(amount, parts), pancakeSwap);
    }

    function calculateQuickSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return _calculateSwap(fromToken, destToken, _linearInterpolation(amount, parts), quickSwap);
    }

    function calculateSushiSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return _calculateSwap(fromToken, destToken, _linearInterpolation(amount, parts), sushiSwap);
    }

    function calculateUniswapV2(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        return _calculateSwap(fromToken, destToken, _linearInterpolation(amount, parts), uniswapV2);
    }

    function _calculateSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256[] memory amounts,
        IUniswapV2Factory exchangeInstance
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        rets = new uint256[](amounts.length);

        IERC20Upgradeable fromTokenReal = fromToken.isETH() ? wnative : fromToken;
        IERC20Upgradeable destTokenReal = destToken.isETH() ? wnative : destToken;
        IUniswapV2Exchange exchange = exchangeInstance.getPair(fromTokenReal, destTokenReal);
        if (exchange != IUniswapV2Exchange(address(0))) {
            uint256 fromTokenBalance = fromTokenReal.universalBalanceOf(address(exchange));
            uint256 destTokenBalance = destTokenReal.universalBalanceOf(address(exchange));
            for (uint256 i = 0; i < amounts.length; i++) {
                rets[i] = _calculateUniswapFormula(fromTokenBalance, destTokenBalance, amounts[i]);
            }
            return (rets, 50_000);
        }
    }

    function _calculateNoReturn(
        IERC20Upgradeable, /*fromToken*/
        IERC20Upgradeable, /*destToken*/
        uint256, /*amount*/
        uint256 parts
    ) internal view returns (uint256[] memory rets, uint256 gas) {
        this;
        return (new uint256[](parts), 0);
    }
}

contract OneSplit is Initializable, IOneSplit, OneSplitRoot, UUPSUpgradeable, AccessControlUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using DisableFlags for uint256;
    using UniswapV2ExchangeLib for IUniswapV2Exchange;
    IOneSplitView public oneSplitView;
    address public handlerAddress;
    IHandlerReserve public reserveInstance;
    IBridge public bridgeInstance;
    IEthHandler public _ethHandler;


    //Alternative for constructor in upgradable contract

    function initialize(
        IOneSplitView _oneSplitView,
        address _handlerAddress,
        address _reserveAddress,
        address _bridgeAddress,
        IEthHandler ethHandler
    ) public initializer {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        oneSplitView = _oneSplitView;
        handlerAddress = _handlerAddress;
        reserveInstance = IHandlerReserve(_reserveAddress);
        bridgeInstance = IBridge(_bridgeAddress);
        _ethHandler = ethHandler;
    }

    modifier onlyHandler() {
        require(msg.sender == handlerAddress, "sender must be handler contract");
        _;
    }

    //Function that authorize upgrade caller
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function getExpectedReturn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags
    ) public view override returns (uint256 returnAmount, uint256[] memory distribution) {
        (returnAmount, , distribution) = getExpectedReturnWithGas(fromToken, destToken, amount, parts, flags, 0);
    }

    function getExpectedReturnETH(
        IERC20Upgradeable srcStableFromToken,
        uint256 srcStableFromTokenAmount,
        uint256 parts,
        uint256 flags
    ) public view override returns (uint256 returnAmount) {
        if (address(srcStableFromToken) == address(NATIVE_ADDRESS)) {
            srcStableFromToken = wnative;
        }
        (returnAmount, ) = getExpectedReturn(srcStableFromToken, wnative, srcStableFromTokenAmount, parts, flags);
        return returnAmount;
    }

    function getExpectedReturnWithGas(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags,
        uint256 destTokenEthPriceTimesGasPrice
    )
        public
        view
        override
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
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        public
        view
        override
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        )
    {
        uint256[] memory dist;

        returnAmounts = new uint256[](tokens.length - 1);
        for (uint256 i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                returnAmounts[i - 1] = (i == 1) ? amount : returnAmounts[i - 2];
                continue;
            }

            IERC20Upgradeable[] memory _tokens = tokens;

            (returnAmounts[i - 1], amount, dist) = getExpectedReturnWithGas(
                _tokens[i - 1],
                _tokens[i],
                (i == 1) ? amount : returnAmounts[i - 2],
                parts[i - 1],
                flags[i - 1],
                destTokenEthPriceTimesGasPrices[i - 1]
            );
            estimateGasAmount = estimateGasAmount + amount;

            if (distribution.length == 0) {
                distribution = new uint256[](dist.length);
            }

            for (uint256 j = 0; j < distribution.length; j++) {
                distribution[j] = (distribution[j] + dist[j]) << (8 * (i - 1));
            }
        }
    }

    function setHandlerAddress(address _handlerAddress) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_handlerAddress != address(0), "Recipient can't be null");
        handlerAddress = _handlerAddress;
        return true;
    }

    function setReserveAddress(address _reserveAddress) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_reserveAddress != address(0), "Address can't be null");
        reserveInstance = IHandlerReserve(_reserveAddress);
        return true;
    }

    function setBridgeAddress(address _bridgeAddress) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(_bridgeAddress != address(0), "Address can't be null");
        bridgeInstance = IBridge(_bridgeAddress);
        return true;
    }

    function setEthHandler(IEthHandler ethHandler) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _ethHandler = ethHandler;
    }

    function setGetViewAddress(IOneSplitView _oneSplitView) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(address(_oneSplitView) != address(0), "Address can't be null");
        oneSplitView = _oneSplitView;
        return true;
    }

    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public payable override onlyHandler returns (bool) {
        require(tokenAddress != address(0), "Token address can't be null");
        require(recipient != address(0), "Recipient can't be null");

        TransferHelper.safeTransfer(tokenAddress, recipient, amount);
        return true;
    }

    function swap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper
    ) public payable override returns (uint256 returnAmount) {
        returnAmount = _swapInternal(
            fromToken,
            destToken,
            amount,
            minReturn,
            flags,
            dataTx,
            isWrapper,
            msg.sender
        );
    }

    function swapWithRecipient(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper,
        address recipient
    ) public payable override returns (uint256 returnAmount) {
        require(recipient != address(0), "Recipient Address cannot be null");
        returnAmount = _swapInternal(
            fromToken,
            destToken,
            amount,
            minReturn,
            flags,
            dataTx,
            isWrapper,
            recipient
        );
    }

    function _swapInternal(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory dataTx,
        bool isWrapper,
        address recipient
    ) internal returns (uint256 returnAmount) {
        if (!isWrapper) {
            fromToken.universalTransferFrom(msg.sender, address(this), amount);
        }

        if (destToken.isETH() && msg.sender == address(reserveInstance)) {
            require(false, "OneSplit: Native transfer not allowed");
        }

        uint256 confirmed = fromToken.universalBalanceOf(address(this));
        _swapFloor(fromToken, destToken, confirmed, flags, dataTx);
        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "RA: actual return amount is less than minReturn");

        uint256 userBalanceOld = destToken.universalBalanceOf(recipient);
        destToken.universalTransfer(recipient, returnAmount);
        uint256 userBalanceNew = destToken.universalBalanceOf(recipient);
        require(userBalanceNew - userBalanceOld >= minReturn, "ERROR:1003");

        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));
        return userBalanceNew - userBalanceOld;
    }

    function swapMulti(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper
    ) public payable override returns (uint256 returnAmount) {
        returnAmount = _swapMultiInternal(tokens, amount, minReturn, flags, dataTx, isWrapper, msg.sender);
    }

    function swapMultiWithRecipient(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper,
        address recipient
    ) public payable override returns (uint256 returnAmount) {
        require(recipient != address(0), "Recipient Address cannot be null");
        returnAmount = _swapMultiInternal(tokens, amount, minReturn, flags, dataTx, isWrapper, recipient);
    }

    function _swapMultiInternal(
        IERC20Upgradeable[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory flags,
        bytes[] memory dataTx,
        bool isWrapper,
        address recipient
    ) internal returns (uint256 returnAmount) {
        if (!isWrapper) {
            tokens[0].universalTransferFrom(msg.sender, address(this), amount);
        }

        if (tokens[tokens.length - 1].isETH() && msg.sender == address(reserveInstance)) {
            require(false, "OneSplit: Native transfer not allowed");
        }

        returnAmount = tokens[0].universalBalanceOf(address(this));
        for (uint256 i = 1; i < tokens.length; i++) {
            if (tokens[i - 1] == tokens[i]) {
                continue;
            }
            _swapFloor(tokens[i - 1], tokens[i], returnAmount, flags[i - 1], dataTx[i-1]);
            returnAmount = tokens[i].universalBalanceOf(address(this));
            tokens[i - 1].universalTransfer(msg.sender, tokens[i - 1].universalBalanceOf(address(this)));
        }

        require(returnAmount >= minReturn, "RA: actual return amount is less than minReturn");

        uint256 userBalanceOld = tokens[tokens.length - 1].universalBalanceOf(recipient);
        tokens[tokens.length - 1].universalTransfer(recipient, returnAmount);
        uint256 userBalanceNew = tokens[tokens.length - 1].universalBalanceOf(recipient);
        require(userBalanceNew - userBalanceOld >= minReturn, "ERROR:1003");
        returnAmount = userBalanceNew - userBalanceOld;
    }

    function _swapFloor(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 flags,
        bytes memory _data
    ) internal {
        _swap(fromToken, destToken, amount, 0, flags, _data);
    }

    function _getReserveExchange(uint256 flag)
        internal
        pure
        returns (function(IERC20Upgradeable, IERC20Upgradeable, uint256, bytes memory))
    {
        if (flag.check(FLAG_DISABLE_UNISWAP_V2_ALL)) {
            return _swapOnUniswapV2;
        } else if (flag.check(FLAG_DISABLE_DFYN)) {
            return _swapOnDfyn;
        } else if (flag.check(FLAG_DISABLE_PANCAKESWAP)) {
            return _swapOnPancakeSwap;
        } else if (flag.check(FLAG_DISABLE_QUICKSWAP)) {
            return _swapOnQuickSwap;
        } else if (flag.check(FLAG_DISABLE_SUSHISWAP)) {
            return _swapOnSushiSwap;
        } else if (flag.check(FLAG_DISABLE_ONEINCH)) {
            return _swapOnOneInch;
        }
        revert("RA: Exchange not found");
    }

    function _swap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        uint256 minReturn,
        uint256 flags,
        bytes memory _data
    ) internal returns (uint256 returnAmount) {
        if (fromToken == destToken) {
            return amount;
        }

        if (
            (reserveInstance._contractToLP(address(destToken)) == address(fromToken)) &&
            (destToken.universalBalanceOf(address(reserveInstance)) > amount)
        ) {
            bridgeInstance.unstake(handlerAddress, address(destToken), amount);
            return amount;
        }

        if (reserveInstance._lpToContract(address(destToken)) == address(fromToken)) {
            fromToken.universalApprove(address(reserveInstance), amount);
            bridgeInstance.stake(handlerAddress, address(fromToken), amount);
            return amount;
        }

        function(IERC20Upgradeable, IERC20Upgradeable, uint256, bytes memory) reserve = _getReserveExchange(flags);

        uint256 remainingAmount = fromToken.universalBalanceOf(address(this));
        reserve(fromToken, destToken, remainingAmount, _data);

        returnAmount = destToken.universalBalanceOf(address(this));
        require(returnAmount >= minReturn, "Return amount was not enough");
    }

    receive() external payable {}

    function _swapOnExchangeInternal(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        IUniswapV2Factory exchangeInstance
    ) internal returns (uint256 returnAmount) {
        if (fromToken.isETH()) {
            wnative.deposit{ value: amount }();
        }

        IERC20Upgradeable fromTokenReal = fromToken.isETH() ? wnative : fromToken;
        IERC20Upgradeable toTokenReal = destToken.isETH() ? wnative : destToken;
        IUniswapV2Exchange exchange = exchangeInstance.getPair(fromTokenReal, toTokenReal);
        bool needSync;
        bool needSkim;
        (returnAmount, needSync, needSkim) = exchange.getReturn(fromTokenReal, toTokenReal, amount);
        if (needSync) {
            exchange.sync();
        } else if (needSkim) {
            exchange.skim(skimAddress);
        }

        fromTokenReal.universalTransfer(address(exchange), amount);
        if (uint256(uint160(address(fromTokenReal))) < uint256(uint160(address(toTokenReal)))) {
            exchange.swap(0, returnAmount, address(this), "");
        } else {
            exchange.swap(returnAmount, 0, address(this), "");
        }

        if (destToken.isETH()) {
            // wnative.withdraw(wnative.balanceOf(address(this)));
            uint256 balanceThis = wnative.balanceOf(address(this));
            wnative.transfer(address(_ethHandler), wnative.balanceOf(address(this)));
            _ethHandler.withdraw(address(wnative), balanceThis);
        }
    }

    function _swapOnUniswapV2(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data
    ) internal {
        _swapOnExchangeInternal(fromToken, destToken, amount, uniswapV2);
    }

    function _swapOnOneInch(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data) internal {
        require(_data.length > 0, "data should not be empty");
        fromToken.universalApprove(address(oneInchSwap), type(uint256).max);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(oneInchSwap).call{value: msg.value}(_data);
    }

    function _swapOnDfyn(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data
    ) internal {
        _swapOnExchangeInternal(fromToken, destToken, amount, dfynExchange);
    }

    function _swapOnPancakeSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data
    ) internal {
        _swapOnExchangeInternal(fromToken, destToken, amount, pancakeSwap);
    }

    function _swapOnQuickSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data
    ) internal {
        _swapOnExchangeInternal(fromToken, destToken, amount, quickSwap);
    }

    function _swapOnSushiSwap(
        IERC20Upgradeable fromToken,
        IERC20Upgradeable destToken,
        uint256 amount,
        bytes memory _data
    ) internal {
        _swapOnExchangeInternal(fromToken, destToken, amount, sushiSwap);
    }
}
