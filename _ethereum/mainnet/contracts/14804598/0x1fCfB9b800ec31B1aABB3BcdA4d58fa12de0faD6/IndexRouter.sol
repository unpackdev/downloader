// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./IAccessControl.sol";
import "./TransferHelper.sol";
import "./SafeERC20.sol";
import "./ERC165Checker.sol";
import "./IERC20Metadata.sol";
import "./draft-IERC20Permit.sol";

import "./BP.sol";
import "./IndexLibrary.sol";
import "./UniswapV2Library.sol";

import "./IIndex.sol";
import "./IvToken.sol";
import "./IFeePool.sol";
import "./IIndexRouter.sol";
import "./IvTokenFactory.sol";
import "./IIndexRegistry.sol";
import "./IWETH.sol";
import "./IPhuturePriceOracle.sol";

/// @title Index router
/// @notice Contains methods allowing to mint and redeem index tokens in exchange for various assets
contract IndexRouter is IIndexRouter {
    using FullMath for uint;
    using SafeERC20 for IERC20;
    using IndexLibrary for uint;
    using ERC165Checker for address;
    using UniswapV2Library for address;

    struct MintDetails {
        uint minAmountInBase;
        uint[] amountsInBase;
        uint[] inputAmountInToken;
        IvTokenFactory vTokenFactory;
    }

    /// @notice Index role
    bytes32 internal immutable INDEX_ROLE;
    /// @notice Asset role
    bytes32 internal immutable ASSET_ROLE;
    /// @notice Skipped asset role
    bytes32 internal immutable SKIPPED_ASSET_ROLE;
    /// @notice Exchange factory role
    bytes32 internal immutable EXCHANGE_FACTORY_ROLE;

    /// @inheritdoc IIndexRouter
    address public immutable override WETH;
    /// @inheritdoc IIndexRouter
    address public immutable override registry;

    /// @notice Checks if `_index` has INDEX_ROLE
    /// @param _index Index address
    modifier isValidIndex(address _index) {
        require(IAccessControl(registry).hasRole(INDEX_ROLE, _index), "IndexRouter: INVALID");
        _;
    }

    constructor(address _WETH, address _registry) {
        require(_WETH != address(0), "IndexRouter: ZERO");

        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "IndexRouter: INTERFACE");

        INDEX_ROLE = keccak256("INDEX_ROLE");
        ASSET_ROLE = keccak256("ASSET_ROLE");
        SKIPPED_ASSET_ROLE = keccak256("SKIPPED_ASSET_ROLE");
        EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");

        WETH = _WETH;
        registry = _registry;
    }

    /// @inheritdoc IIndexRouter
    /// @dev only accept ETH via fallback from the WETH contract
    receive() external payable override {
        require(msg.sender == WETH);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapIndexAmount(MintSwapParams calldata _params)
        external
        view
        override
        isValidIndex(_params.index)
        returns (uint val)
    {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_params.index).anatomy();

        uint assetBalanceInBase;
        uint minAmountInBase = type(uint).max;

        for (uint i; i < _weights.length; ) {
            if (_weights[i] != 0) {
                uint _amount = (_params.amountInInputToken * _weights[i]) / IndexLibrary.MAX_WEIGHT;
                if (_assets[i] != _params.inputToken) {
                    uint[] memory a = UniswapV2Library.getAmountsOut(
                        _params.swapFactories[i],
                        _amount,
                        _params.paths[i]
                    );
                    _amount = a[a.length - 1];
                }

                uint assetPerBaseInUQ = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
                    .lastAssetPerBaseInUQ(_assets[i]);
                IvToken vToken = IvToken(IvTokenFactory(IIndex(_params.index).vTokenFactory()).vTokenOf(_assets[i]));
                {
                    uint weightedPrice = assetPerBaseInUQ * _weights[i];
                    uint _minAmountInBase = _amount.mulDiv(FixedPoint112.Q112 * IndexLibrary.MAX_WEIGHT, weightedPrice);
                    if (_minAmountInBase < minAmountInBase) {
                        minAmountInBase = _minAmountInBase;
                    }
                }

                if (address(vToken) != address(0)) {
                    assetBalanceInBase += vToken.lastAssetBalanceOf(_params.index).mulDiv(
                        FixedPoint112.Q112,
                        assetPerBaseInUQ
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        IPhuturePriceOracle priceOracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());

        {
            address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

            uint inactiveAssetsCount = inactiveAssets.length;
            for (uint i; i < inactiveAssetsCount; ) {
                address inactiveAsset = inactiveAssets[i];
                if (!IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, inactiveAsset)) {
                    uint balanceInAsset = IvToken(
                        IvTokenFactory((IIndex(_params.index).vTokenFactory())).vTokenOf(inactiveAsset)
                    ).lastAssetBalanceOf(_params.index);

                    assetBalanceInBase += balanceInAsset.mulDiv(
                        FixedPoint112.Q112,
                        priceOracle.lastAssetPerBaseInUQ(inactiveAsset)
                    );
                }
                unchecked {
                    i = i + 1;
                }
            }
        }

        assert(minAmountInBase != type(uint).max);

        uint8 _indexDecimals = IERC20Metadata(_params.index).decimals();
        if (IERC20(_params.index).totalSupply() != 0) {
            require(assetBalanceInBase > 0, "Index: INSUFFICIENT_AMOUNT");

            val =
                (priceOracle.convertToIndex(minAmountInBase, _indexDecimals) * IERC20(_params.index).totalSupply()) /
                priceOracle.convertToIndex(assetBalanceInBase, _indexDecimals);
        } else {
            val = priceOracle.convertToIndex(minAmountInBase, _indexDecimals) - IndexLibrary.INITIAL_QUANTITY;
        }

        uint256 fee = (val * IFeePool(IIndexRegistry(registry).feePool()).mintingFeeInBPOf(_params.index)) /
            BP.DECIMAL_FACTOR;
        val -= fee;
    }

    /// @inheritdoc IIndexRouter
    function burnTokensAmount(address _index, uint _amount)
        public
        view
        override
        isValidIndex(_index)
        returns (uint[] memory amounts)
    {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_index).anatomy();
        address[] memory inactiveAssets = IIndex(_index).inactiveAnatomy();
        amounts = new uint[](_weights.length + inactiveAssets.length);

        uint assetsCount = _assets.length;

        bool containsBlacklistedAssets;
        for (uint i; i < assetsCount; ) {
            if (!IAccessControl(registry).hasRole(ASSET_ROLE, _assets[i])) {
                containsBlacklistedAssets = true;
                break;
            }

            unchecked {
                i = i + 1;
            }
        }

        if (!containsBlacklistedAssets) {
            _amount -=
                (_amount * IFeePool(IIndexRegistry(registry).feePool()).burningFeeInBPOf(_index)) /
                BP.DECIMAL_FACTOR;
        }

        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        for (uint i; i < totalAssetsCount; ) {
            address asset = i < assetsCount ? _assets[i] : inactiveAssets[i - assetsCount];
            if (!(containsBlacklistedAssets && IAccessControl(registry).hasRole(SKIPPED_ASSET_ROLE, asset))) {
                uint indexAssetBalance = IvToken(IvTokenFactory(IIndex(_index).vTokenFactory()).vTokenOf(asset))
                    .balanceOf(_index);

                amounts[i] = (_amount * indexAssetBalance) / IERC20(_index).totalSupply();
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndexRouter
    function burnTokenValue(BurnSwapParams calldata _params)
        external
        view
        override
        isValidIndex(_params.index)
        returns (uint value)
    {
        uint[] memory amounts = burnTokensAmount(_params.index, _params.amount);

        uint amountsCount = amounts.length;
        for (uint i; i < amountsCount; ) {
            uint amount = amounts[i];
            if (_params.paths[i][0] == _params.paths[i][_params.paths[i].length - 1]) {
                value += amount;
            } else {
                uint[] memory a = _params.swapFactories[i].getAmountsOut(amount, _params.paths[i]);
                value += a[a.length - 1];
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndexRouter
    function mint(MintParams calldata _params) external override isValidIndex(_params.index) {
        IIndex index = IIndex(_params.index);
        (address[] memory _assets, uint8[] memory _weights) = index.anatomy();

        IvTokenFactory vTokenFactory = IvTokenFactory(index.vTokenFactory());
        IPriceOracle oracle = IPriceOracle(IIndexRegistry(registry).priceOracle());

        uint assetsCount = _assets.length;
        for (uint i; i < assetsCount; ) {
            if (_weights[i] > 0) {
                address asset = _assets[i];
                IERC20(asset).safeTransferFrom(
                    msg.sender,
                    vTokenFactory.createdVTokenOf(_assets[i]),
                    oracle.refreshedAssetPerBaseInUQ(asset).amountInAsset(_weights[i], _params.amountInBase)
                );
            }

            unchecked {
                i = i + 1;
            }
        }

        index.mint(_params.recipient);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapWithPermit(
        MintSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override isValidIndex(_params.index) {
        IERC20Permit(_params.inputToken).permit(
            msg.sender,
            address(this),
            _params.amountInInputToken,
            _deadline,
            _v,
            _r,
            _s
        );
        mintSwap(_params);
    }

    /// @inheritdoc IIndexRouter
    function mintSwapValue(MintSwapValueParams calldata _params) external payable override isValidIndex(_params.index) {
        IWETH(WETH).deposit{ value: msg.value }();

        _mint(_params, WETH, msg.value, address(this));

        uint change = IERC20(WETH).balanceOf(address(this));
        if (change != 0) {
            IWETH(WETH).withdraw(change);
            TransferHelper.safeTransferETH(_params.recipient, change);
        }
    }

    /// @inheritdoc IIndexRouter
    function burnWithPermit(
        BurnParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override isValidIndex(_params.index) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        burn(_params);
    }

    /// @inheritdoc IIndexRouter
    function burnSwapWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override isValidIndex(_params.index) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        burnSwap(_params);
    }

    /// @inheritdoc IIndexRouter
    function burnSwapValueWithPermit(
        BurnSwapParams calldata _params,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override isValidIndex(_params.index) {
        IERC20Permit(_params.index).permit(msg.sender, address(this), _params.amount, _deadline, _v, _r, _s);
        burnSwapValue(_params);
    }

    /// @inheritdoc IIndexRouter
    function mintSwap(MintSwapParams calldata _params) public override isValidIndex(_params.index) {
        _mint(
            MintSwapValueParams({
                index: _params.index,
                recipient: _params.recipient,
                buyAssetMinAmounts: _params.buyAssetMinAmounts,
                paths: _params.paths,
                swapFactories: _params.swapFactories
            }),
            _params.inputToken,
            _params.amountInInputToken,
            msg.sender
        );
    }

    /// @inheritdoc IIndexRouter
    function burn(BurnParams calldata _params) public override isValidIndex(_params.index) {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);
        IIndex(_params.index).burn(_params.recipient);
    }

    /// @inheritdoc IIndexRouter
    function burnSwap(BurnSwapParams calldata _params) public override isValidIndex(_params.index) {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);
        IIndex(_params.index).burn(address(this));

        (address[] memory assets, ) = IIndex(_params.index).anatomy();
        address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

        uint assetsCount = assets.length;
        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        for (uint i; i < totalAssetsCount; ) {
            IERC20 asset = IERC20(i < assetsCount ? assets[i] : inactiveAssets[i - assetsCount]);
            uint balance = asset.balanceOf(address(this));
            if (balance > 0) {
                if (_params.paths[i][0] == _params.paths[i][_params.paths[i].length - 1]) {
                    asset.safeTransfer(_params.recipient, balance);
                } else {
                    require(
                        IAccessControl(registry).hasRole(EXCHANGE_FACTORY_ROLE, _params.swapFactories[i]),
                        "IndexRouter: INVALID_FACTORY"
                    );

                    _swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        address(this),
                        balance,
                        _params.buyAssetMinAmounts[i],
                        _params.paths[i],
                        _params.swapFactories[i],
                        _params.recipient
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc IIndexRouter
    function burnSwapValue(BurnSwapParams calldata _params) public override isValidIndex(_params.index) {
        IERC20(_params.index).safeTransferFrom(msg.sender, _params.index, _params.amount);

        IIndex(_params.index).burn(address(this));

        (address[] memory assets, ) = IIndex(_params.index).anatomy();
        address[] memory inactiveAssets = IIndex(_params.index).inactiveAnatomy();

        uint assetsCount = assets.length;
        uint totalAssetsCount = assetsCount + inactiveAssets.length;
        for (uint i; i < totalAssetsCount; ) {
            uint balance = IERC20(i < assetsCount ? assets[i] : inactiveAssets[i - assetsCount]).balanceOf(
                address(this)
            );
            if (balance > 0) {
                address outputAsset = _params.paths[i][_params.paths[i].length - 1];
                require(outputAsset == WETH, "IndexRouter: OUTPUT");

                if (_params.paths[i][0] == outputAsset) {
                    IWETH(WETH).withdraw(balance);
                    TransferHelper.safeTransferETH(_params.recipient, balance);
                } else {
                    require(
                        IAccessControl(registry).hasRole(EXCHANGE_FACTORY_ROLE, _params.swapFactories[i]),
                        "IndexRouter: INVALID_FACTORY"
                    );

                    _swapExactTokensForETHSupportingFeeOnTransferTokens(
                        balance,
                        _params.buyAssetMinAmounts[i],
                        _params.paths[i],
                        _params.swapFactories[i],
                        _params.recipient
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Swaps and sends assets in certain proportions to vTokens to mint index
    /// @param _params Mint parameters
    /// @param _inputToken Input token address
    /// @param _amountInInputToken Amount in input token
    /// @param _sender Input token sender account
    function _mint(
        MintSwapValueParams memory _params,
        address _inputToken,
        uint _amountInInputToken,
        address _sender
    ) internal {
        (address[] memory _assets, uint8[] memory _weights) = IIndex(_params.index).anatomy();

        uint assetsCount = _assets.length;

        MintDetails memory _details = MintDetails(
            type(uint).max,
            new uint[](assetsCount),
            new uint[](assetsCount),
            IvTokenFactory(IIndex(_params.index).vTokenFactory())
        );
        {
            IPriceOracle priceOracle = IPhuturePriceOracle(IIndexRegistry(registry).priceOracle());
            for (uint i; i < assetsCount; ) {
                if (_weights[i] != 0) {
                    require(_inputToken == _params.paths[i][0], "IndexRouter: INVALID_PATH");

                    address asset = _params.paths[i][_params.paths[i].length - 1];
                    require(asset == _assets[i], "IndexRouter: INVALID_PATH");

                    _details.inputAmountInToken[i] = (_amountInInputToken * _weights[i]) / IndexLibrary.MAX_WEIGHT;

                    uint amountOut;
                    if (asset == _inputToken) {
                        amountOut = _details.inputAmountInToken[i];
                    } else {
                        uint[] memory amountsOut = UniswapV2Library.getAmountsOut(
                            _params.swapFactories[i],
                            _details.inputAmountInToken[i],
                            _params.paths[i]
                        );
                        amountOut = amountsOut[amountsOut.length - 1];
                    }

                    uint amountOutInBase = amountOut.mulDiv(
                        FixedPoint112.Q112 * IndexLibrary.MAX_WEIGHT,
                        priceOracle.refreshedAssetPerBaseInUQ(asset) * _weights[i]
                    );
                    _details.amountsInBase[i] = amountOutInBase;
                    if (amountOutInBase < _details.minAmountInBase) {
                        _details.minAmountInBase = amountOutInBase;
                    }
                }

                unchecked {
                    i = i + 1;
                }
            }
        }

        for (uint i; i < assetsCount; ) {
            if (_weights[i] != 0) {
                address asset = _params.paths[i][_params.paths[i].length - 1];
                uint _amount = (_details.inputAmountInToken[i] * _details.minAmountInBase) / _details.amountsInBase[i];
                if (asset == _inputToken) {
                    IERC20(asset).safeTransferFrom(_sender, _details.vTokenFactory.createdVTokenOf(asset), _amount);
                } else {
                    require(
                        IAccessControl(registry).hasRole(EXCHANGE_FACTORY_ROLE, _params.swapFactories[i]),
                        "IndexRouter: INVALID_FACTORY"
                    );

                    _swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        _sender,
                        _amount,
                        (_params.buyAssetMinAmounts[i] * _details.minAmountInBase) / _details.amountsInBase[i],
                        _params.paths[i],
                        _params.swapFactories[i],
                        _details.vTokenFactory.createdVTokenOf(asset)
                    );
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        IIndex(_params.index).mint(_params.recipient);
    }

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible,
     * along the route determined by the path. The first element of path is the input token,
     * the last is the output token, and any intermediate elements represent intermediate
     * pairs to trade through (if, for example, a direct pair does not exist).
     */
    /// @param sender Input tokens sender account
    /// @param amountIn The amount of input tokens to send
    /// @param amountOutMin The minimum amount of output tokens that must be received
    /// @param path An array of token addresses (path.length must be >= 2)
    /// @param swapFactory Uniswap factory address
    /// @param to Token receiver account
    function _swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address sender,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address swapFactory,
        address to
    ) internal {
        if (sender == address(this)) {
            IERC20(path[0]).safeTransfer(UniswapV2Library.pairFor(swapFactory, path[0], path[1]), amountIn);
        } else {
            IERC20(path[0]).safeTransferFrom(sender, UniswapV2Library.pairFor(swapFactory, path[0], path[1]), amountIn);
        }
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, swapFactory, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    /**
     * @notice Swaps an exact amount of tokens for as much ETH as possible, along
     * the route determined by the path. The first element of path is the input token,
     * the last must be WETH, and any intermediate elements represent intermediate pairs
     * to trade through (if, for example, a direct pair does not exist).
     */
    /// @param amountIn The amount of input tokens to send
    /// @param amountOutMin The minimum amount of output tokens that must be received
    /// @param path An array of token addresses (path.length must be >= 2)
    /// @param swapFactory Uniswap factory address
    /// @param to ETH receiver account
    function _swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address swapFactory,
        address to
    ) internal {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        IERC20(path[0]).safeTransfer(UniswapV2Library.pairFor(swapFactory, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(path, swapFactory, address(this));
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address swapFactory,
        address _to
    ) internal {
        for (uint i; i < path.length - 1; ) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(swapFactory, input, output));
            uint amountInput;
            uint amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1, ) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(swapFactory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));

            unchecked {
                i = i + 1;
            }
        }
    }
}
