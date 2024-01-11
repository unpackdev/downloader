// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "./Math.sol";
import "./IAccessControl.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./UUPSUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./ERC165CheckerUpgradeable.sol";

import "./BP.sol";
import "./FullMath.sol";
import "./UniswapV2PriceImpactLibrary.sol";

import "./IvToken.sol";
import "./IIndex.sol";
import "./IOrderer.sol";
import "./IvTokenFactory.sol";
import "./IIndexRegistry.sol";
import "./IReweightableIndex.sol";
import "./IPhuturePriceOracle.sol";

/// @title Orderer
/// @notice Contains logic for reweigh execution, order creation and execution
contract Orderer is IOrderer, UUPSUpgradeable, ERC165Upgradeable {
    using FullMath for uint;
    using ERC165CheckerUpgradeable for address;

    /// @notice Order details structure containing assets list, creator address, creation timestamp and assetDetails
    struct OrderDetails {
        uint creationTimestamp;
        address creator;
        address[] assets;
        mapping(address => AssetDetails) assetDetails;
    }

    /// @notice Asset details structure containing order side (buy/sell) and order shares amount
    struct AssetDetails {
        OrderSide side;
        uint248 shares;
    }

    struct SwapDetails {
        address sellAsset;
        address buyAsset;
        IvToken sellVToken;
        IvToken buyVToken;
        IPhuturePriceOracle priceOracle;
    }

    struct InternalSwapVaultsInfo {
        address sellAccount;
        address buyAccount;
        uint maxSellShares;
        IvToken buyVTokenSellAccount;
        IvToken buyVTokenBuyAccount;
        SwapDetails details;
    }

    /// @notice Index role
    bytes32 internal constant INDEX_ROLE = keccak256("INDEX_ROLE");
    /// @notice Keeper job role
    bytes32 internal constant KEEPER_JOB_ROLE = keccak256("KEEPER_JOB_ROLE");
    /// @notice Exchange factory role
    bytes32 internal constant EXCHANGE_FACTORY_ROLE = keccak256("EXCHANGE_FACTORY_ROLE");
    /// @notice Role allows configure ordering related data/components
    bytes32 internal constant ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

    /// @notice Last placed order id
    uint internal _lastOrderId;

    /// @notice Index registry address
    address internal registry;

    /// @inheritdoc IOrderer
    uint64 public override orderLifetime;

    /// @inheritdoc IOrderer
    uint16 public override maxAllowedPriceImpactInBP;

    /// @inheritdoc IOrderer
    mapping(address => uint) public override lastOrderIdOf;

    /// @notice Mapping of order id to order details
    mapping(uint => OrderDetails) internal orderDetailsOf;

    /// @notice Requires msg.sender to have `_role` role
    /// @param _role Required role
    modifier onlyRole(bytes32 _role) {
        require(IAccessControl(registry).hasRole(_role, msg.sender), "Orderer: FORBIDDEN");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IOrderer
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxAllowedPriceImpactInBP
    ) external override initializer {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "Orderer: INTERFACE");

        __ERC165_init();
        __UUPSUpgradeable_init();

        registry = _registry;
        orderLifetime = _orderLifetime;
        maxAllowedPriceImpactInBP = _maxAllowedPriceImpactInBP;
    }

    /// @inheritdoc IOrderer
    function setMaxAllowedPriceImpactInBP(uint16 _maxAllowedPriceImpactInBP)
        external
        override
        onlyRole(ORDERING_MANAGER_ROLE)
    {
        require(_maxAllowedPriceImpactInBP != 0 && _maxAllowedPriceImpactInBP <= BP.DECIMAL_FACTOR, "Orderer: INVALID");

        maxAllowedPriceImpactInBP = _maxAllowedPriceImpactInBP;
    }

    /// @inheritdoc IOrderer
    function setOrderLifetime(uint64 _orderLifetime) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_orderLifetime != 0, "Orderer: INVALID");

        orderLifetime = _orderLifetime;
    }

    /// @inheritdoc IOrderer
    function placeOrder() external override onlyRole(INDEX_ROLE) returns (uint _orderId) {
        delete orderDetailsOf[lastOrderIdOf[msg.sender]];
        unchecked {
            ++_lastOrderId;
        }
        _orderId = _lastOrderId;
        OrderDetails storage order = orderDetailsOf[_orderId];
        order.creationTimestamp = block.timestamp;
        lastOrderIdOf[msg.sender] = _orderId;
        emit PlaceOrder(msg.sender, _orderId);
    }

    /// @inheritdoc IOrderer
    function addOrderDetails(
        uint _orderId,
        address _asset,
        uint _shares,
        OrderSide _side
    ) external override onlyRole(INDEX_ROLE) {
        if (_asset != address(0) && _shares != 0) {
            OrderDetails storage order = orderDetailsOf[_orderId];
            order.assets.push(_asset);
            order.assetDetails[_asset] = AssetDetails({ side: _side, shares: _toUint248(_shares) });
            emit UpdateOrder(_orderId, _asset, _shares, _side == OrderSide.Sell);
        }
    }

    /// @inheritdoc IOrderer
    function reduceOrderAsset(
        address _asset,
        uint _newTotalSupply,
        uint _oldTotalSupply
    ) external override onlyRole(INDEX_ROLE) {
        uint lastOrderId = lastOrderIdOf[msg.sender];
        if (lastOrderId != 0) {
            OrderDetails storage order = orderDetailsOf[lastOrderId];
            uint shares = order.assetDetails[_asset].shares;
            if (shares != 0) {
                uint248 newShares = _toUint248((shares * _newTotalSupply) / _oldTotalSupply);
                order.assetDetails[_asset].shares = newShares;
                emit UpdateOrder(lastOrderId, _asset, newShares, order.assetDetails[_asset].side == OrderSide.Sell);
            }
        }
    }

    /// @inheritdoc IOrderer
    function reweight(address _index) external override onlyRole(KEEPER_JOB_ROLE) {
        IReweightableIndex(_index).reweight();
    }

    /// @inheritdoc IOrderer
    function internalSwap(InternalSwap calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.buyPath.length == 2, "Orderer: LENGTH");
        require(_info.maxSellShares != 0 && _info.buyAccount != _info.sellAccount, "Orderer: INVALID");
        require(
            IAccessControl(registry).hasRole(INDEX_ROLE, _info.buyAccount) &&
                IAccessControl(registry).hasRole(INDEX_ROLE, _info.sellAccount),
            "Orderer: INDEX"
        );

        address sellVTokenFactory = IIndex(_info.sellAccount).vTokenFactory();
        address buyVTokenFactory = IIndex(_info.buyAccount).vTokenFactory();
        SwapDetails memory _details = _swapDetails(sellVTokenFactory, buyVTokenFactory, _info.buyPath);

        if (sellVTokenFactory == buyVTokenFactory) {
            _internalWithinVaultSwap(_info, _details);
        } else {
            _internalBetweenVaultsSwap(
                InternalSwapVaultsInfo(
                    _info.sellAccount,
                    _info.buyAccount,
                    _info.maxSellShares,
                    IvToken(IvTokenFactory(sellVTokenFactory).vTokenOf(_details.buyAsset)),
                    IvToken(IvTokenFactory(buyVTokenFactory).vTokenOf(_details.sellAsset)),
                    _details
                )
            );
        }
    }

    /// @inheritdoc IOrderer
    function externalSwap(ExternalSwap calldata _info) external override onlyRole(KEEPER_JOB_ROLE) {
        require(_info.maxSellShares != 0, "Orderer: ZERO");
        require(_info.buyPath.length >= 2, "Orderer: LENGTH");
        require(
            IAccessControl(registry).hasRole(INDEX_ROLE, _info.account) &&
                IAccessControl(registry).hasRole(EXCHANGE_FACTORY_ROLE, _info.factory),
            "Orderer: INVALID"
        );

        SwapDetails memory _details = _swapDetails(IIndex(_info.account).vTokenFactory(), address(0), _info.buyPath);

        (uint lastOrderId, AssetDetails storage orderSellAsset, AssetDetails storage orderBuyAsset) = _validatedOrder(
            _info.account,
            _details.sellAsset,
            _details.buyAsset
        );

        (uint248 _sellShares, uint _minSwapOutputAmount) = _calculateExternalSwapShares(
            _info,
            _details,
            Math.min(_info.maxSellShares, orderSellAsset.shares),
            orderBuyAsset.shares
        );
        if (_sellShares != 0) {
            _details.sellVToken.transferFrom(_info.account, address(_details.sellVToken), _sellShares);
            _details.sellVToken.burnFor(UniswapV2Library.pairFor(_info.factory, _info.buyPath[0], _info.buyPath[1]));

            uint balanceBefore = IERC20(_info.buyPath[_info.buyPath.length - 1]).balanceOf(address(_details.buyVToken));
            _swapSupportingFeeOnTransferTokens(_info.buyPath, _info.factory, address(_details.buyVToken));
            require(
                IERC20(_info.buyPath[_info.buyPath.length - 1]).balanceOf(address(_details.buyVToken)) -
                    balanceBefore >=
                    _minSwapOutputAmount,
                "Orderer: SLIPPAGE"
            );

            uint248 _buyShares = _toUint248(Math.min(_details.buyVToken.mintFor(_info.account), orderBuyAsset.shares));

            orderSellAsset.shares -= _sellShares;
            orderBuyAsset.shares -= _buyShares;

            emit CompleteOrder(lastOrderId, _details.sellAsset, _sellShares, _details.buyAsset, _buyShares);
        }
    }

    /// @inheritdoc IOrderer
    function orderOf(address _account) external view override returns (Order memory order) {
        OrderDetails storage _order = orderDetailsOf[lastOrderIdOf[_account]];
        order = Order({ creationTimestamp: _order.creationTimestamp, assets: new OrderAsset[](_order.assets.length) });

        uint assetsCount = _order.assets.length;
        for (uint i; i < assetsCount; ) {
            address asset = _order.assets[i];
            order.assets[i] = OrderAsset({
                asset: asset,
                side: _order.assetDetails[asset].side,
                shares: _order.assetDetails[asset].shares
            });

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IOrderer).interfaceId || super.supportsInterface(_interfaceId);
    }

    /// @notice Executes internal swap within single vault
    function _internalWithinVaultSwap(InternalSwap calldata _info, SwapDetails memory _details) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _details.sellAsset, _details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _details.buyAsset, _details.sellAsset);

        uint248 sellShares;
        uint248 buyShares;
        {
            uint _sellShares = Math.min(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares
            );
            uint _buyShares = Math.min(sellOrderBuyAsset.shares, buyOrderSellAsset.shares);
            (sellShares, buyShares) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _details,
                _sellShares,
                _buyShares
            );
        }

        if (sellShares != 0 && buyShares != 0) {
            _details.sellVToken.transferFrom(_info.sellAccount, _info.buyAccount, sellShares);
            _details.buyVToken.transferFrom(_info.buyAccount, _info.sellAccount, buyShares);

            sellOrderSellAsset.shares -= sellShares;
            sellOrderBuyAsset.shares -= buyShares;
            buyOrderSellAsset.shares -= buyShares;
            buyOrderBuyAsset.shares -= sellShares;

            emit CompleteOrder(lastSellOrderId, _details.sellAsset, sellShares, _details.buyAsset, buyShares);
            emit CompleteOrder(lastBuyOrderId, _details.buyAsset, buyShares, _details.sellAsset, sellShares);
        }
    }

    /// @notice Executes internal swap between different vaults
    function _internalBetweenVaultsSwap(InternalSwapVaultsInfo memory _info) internal {
        (
            uint lastSellOrderId,
            AssetDetails storage sellOrderSellAsset,
            AssetDetails storage sellOrderBuyAsset
        ) = _validatedOrder(_info.sellAccount, _info.details.sellAsset, _info.details.buyAsset);
        (
            uint lastBuyOrderId,
            AssetDetails storage buyOrderSellAsset,
            AssetDetails storage buyOrderBuyAsset
        ) = _validatedOrder(_info.buyAccount, _info.details.buyAsset, _info.details.sellAsset);

        uint248 sellSharesSellAccount;
        uint248 sellSharesBuyAccount;
        {
            uint _sellSharesSellAccount = _scaleShares(
                Math.min(_info.maxSellShares, sellOrderSellAsset.shares),
                buyOrderBuyAsset.shares,
                _info.sellAccount,
                _info.details.sellVToken,
                _info.buyVTokenBuyAccount
            );
            uint _buySharesBuyAccount = _scaleShares(
                buyOrderSellAsset.shares,
                sellOrderBuyAsset.shares,
                _info.buyAccount,
                _info.details.buyVToken,
                _info.buyVTokenSellAccount
            );

            (sellSharesSellAccount, sellSharesBuyAccount) = _calculateInternalSwapShares(
                _info.sellAccount,
                _info.buyAccount,
                _info.details,
                _sellSharesSellAccount,
                _buySharesBuyAccount
            );
        }

        _info.details.sellVToken.transferFrom(
            _info.sellAccount,
            address(_info.details.sellVToken),
            sellSharesSellAccount
        );
        _info.details.sellVToken.burnFor(address(_info.buyVTokenBuyAccount));
        uint248 buySharesBuyAccount = _toUint248(_info.buyVTokenBuyAccount.mintFor(_info.buyAccount));

        _info.details.buyVToken.transferFrom(_info.buyAccount, address(_info.details.buyVToken), sellSharesBuyAccount);
        _info.details.buyVToken.burnFor(address(_info.buyVTokenSellAccount));
        uint248 buySharesSellAccount = _toUint248(_info.buyVTokenSellAccount.mintFor(_info.sellAccount));

        sellOrderSellAsset.shares -= sellSharesSellAccount;
        sellOrderBuyAsset.shares -= buySharesSellAccount;
        buyOrderSellAsset.shares -= sellSharesBuyAccount;
        buyOrderBuyAsset.shares -= buySharesBuyAccount;

        emit CompleteOrder(
            lastSellOrderId,
            _info.details.sellAsset,
            sellSharesSellAccount,
            _info.details.buyAsset,
            buySharesSellAccount
        );
        emit CompleteOrder(
            lastBuyOrderId,
            _info.details.buyAsset,
            sellSharesBuyAccount,
            _info.details.sellAsset,
            buySharesBuyAccount
        );
    }

    /// @notice Returns validated order's info
    /// @param _index Index address
    /// @param _sellAsset Sell asset address
    /// @param _buyAsset Buy asset address
    /// @return lastOrderId Id of last order
    /// @return orderSellAsset Order's details for sell asset
    /// @return orderBuyAsset Order's details for buy asset
    function _validatedOrder(
        address _index,
        address _sellAsset,
        address _buyAsset
    )
        internal
        view
        returns (
            uint lastOrderId,
            AssetDetails storage orderSellAsset,
            AssetDetails storage orderBuyAsset
        )
    {
        lastOrderId = lastOrderIdOf[_index];
        OrderDetails storage order = orderDetailsOf[lastOrderId];

        orderSellAsset = order.assetDetails[_sellAsset];
        orderBuyAsset = order.assetDetails[_buyAsset];

        require(order.creationTimestamp + orderLifetime > block.timestamp, "Orderer: EXPIRED");
        require(orderSellAsset.side == OrderSide.Sell && orderBuyAsset.side == OrderSide.Buy, "Orderer: SIDE");
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_newImpl.supportsInterface(type(IOrderer).interfaceId), "Orderer: INTERFACE");
    }

    /// @notice Scales down shares
    function _scaleShares(
        uint _sellShares,
        uint _buyShares,
        address _sellAccount,
        IvToken _sellVToken,
        IvToken _buyVToken
    ) internal view returns (uint) {
        uint sharesInAsset = _sellVToken.assetDataOf(_sellAccount, _sellShares).amountInAsset;
        uint mintableShares = _buyVToken.mintableShares(sharesInAsset);
        return Math.min(_sellShares, (_sellShares * _buyShares) / mintableShares);
    }

    /// @notice Calculates internal swap shares (buy and sell) for the given swap details
    function _calculateInternalSwapShares(
        address sellAccount,
        address buyAccount,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) internal returns (uint248 _sellShares, uint248 _buyShares) {
        uint sellAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset);
        uint buyAssetPerBaseInUQ = _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset);
        {
            uint buyAmountInBuyAsset = _details.buyVToken.assetDataOf(buyAccount, _buyOrderShares).amountInAsset;
            uint buyAmountInSellAsset = buyAmountInBuyAsset.mulDiv(sellAssetPerBaseInUQ, buyAssetPerBaseInUQ);
            _sellOrderShares = Math.min(_sellOrderShares, _details.sellVToken.mintableShares(buyAmountInSellAsset));
        }
        {
            uint sellAmountInSellAsset = _details.sellVToken.assetDataOf(sellAccount, _sellOrderShares).amountInAsset;
            uint sellAmountInBuyAsset = sellAmountInSellAsset.mulDiv(buyAssetPerBaseInUQ, sellAssetPerBaseInUQ);
            _buyOrderShares = Math.min(_buyOrderShares, _details.buyVToken.mintableShares(sellAmountInBuyAsset));
        }
        _sellShares = _toUint248(_sellOrderShares);
        _buyShares = _toUint248(_buyOrderShares);
    }

    /// @notice Calculates external swap shares for the given swap details
    function _calculateExternalSwapShares(
        ExternalSwap calldata _swapInfo,
        SwapDetails memory _details,
        uint _sellOrderShares,
        uint _buyOrderShares
    ) internal returns (uint248 sellShares, uint minSwapOutputAmount) {
        minSwapOutputAmount = _swapInfo.minSwapOutputAmount;
        uint buyAmountInBuyAsset = _details.buyVToken.assetDataOf(_swapInfo.account, _buyOrderShares).amountInAsset;
        {
            uint buyAmountInSellAsset = buyAmountInBuyAsset.mulDiv(
                _details.priceOracle.refreshedAssetPerBaseInUQ(_details.sellAsset),
                _details.priceOracle.refreshedAssetPerBaseInUQ(_details.buyAsset)
            );
            uint mintableShares = _details.sellVToken.mintableShares(buyAmountInSellAsset);
            if (_sellOrderShares > mintableShares) {
                minSwapOutputAmount = (minSwapOutputAmount * mintableShares) / _sellOrderShares;
                _sellOrderShares = mintableShares;
            }
        }

        IvToken.AssetData memory assetData = _details.sellVToken.assetDataOf(_swapInfo.account, _sellOrderShares);
        {
            uint priceImpactInBP = UniswapV2PriceImpactLibrary.calculatePriceImpactInBP(
                _swapInfo.factory,
                assetData.amountInAsset,
                _swapInfo.buyPath
            );
            uint changeInBP = (Math.max(maxAllowedPriceImpactInBP, priceImpactInBP) * BP.DECIMAL_FACTOR) /
                maxAllowedPriceImpactInBP;
            if (changeInBP > BP.DECIMAL_FACTOR) {
                _sellOrderShares = (assetData.maxShares * BP.DECIMAL_FACTOR) / changeInBP;
                minSwapOutputAmount = (minSwapOutputAmount * BP.DECIMAL_FACTOR) / changeInBP;
                assetData = _details.sellVToken.assetDataOf(_swapInfo.account, _sellOrderShares);
            }
        }
        {
            uint[] memory amounts = UniswapV2Library.getAmountsOut(
                _swapInfo.factory,
                assetData.amountInAsset,
                _swapInfo.buyPath
            );
            if (amounts[amounts.length - 1] > buyAmountInBuyAsset) {
                amounts = UniswapV2Library.getAmountsIn(_swapInfo.factory, buyAmountInBuyAsset, _swapInfo.buyPath);
                _sellOrderShares = _details.sellVToken.mintableShares(amounts[0]);
                minSwapOutputAmount = (minSwapOutputAmount * amounts[0]) / assetData.amountInAsset;
            }
        }

        sellShares = _toUint248(_sellOrderShares);
    }

    /// @notice Swaps tokens along the list pairs determined by the path
    /// @param _path An array of token addresses (path.length must be >= 2)
    /// @param _factory Uniswap factory address
    /// @param _to Output tokens receiver account
    function _swapSupportingFeeOnTransferTokens(
        address[] memory _path,
        address _factory,
        address _to
    ) internal {
        for (uint i; i < _path.length - 1; ) {
            (address input, address output) = (_path[i], _path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(_factory, input, output));
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
            address to = i < _path.length - 2 ? UniswapV2Library.pairFor(_factory, output, _path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Returns swap details for the provided buy path
    /// @param _sellVTokenFactory vTokenFactory address of sell account
    /// @param _buyVTokenFactory vTokenFactory address of buy account
    /// @param _buyPath Buy path, where the first element is input token and the last element is output token
    /// @return Swap details
    function _swapDetails(
        address _sellVTokenFactory,
        address _buyVTokenFactory,
        address[] calldata _buyPath
    ) internal view returns (SwapDetails memory) {
        (address sellAsset, address buyAsset) = (_buyPath[0], _buyPath[_buyPath.length - 1]);
        require(sellAsset != address(0) && buyAsset != address(0), "Orderer: ZERO");
        require(sellAsset != buyAsset, "Orderer: INVALID");

        address buyVToken = IvTokenFactory(
            (_sellVTokenFactory == _buyVTokenFactory || _buyVTokenFactory == address(0))
                ? _sellVTokenFactory
                : _buyVTokenFactory
        ).vTokenOf(buyAsset);

        return
            SwapDetails({
                sellAsset: sellAsset,
                buyAsset: buyAsset,
                sellVToken: IvToken(IvTokenFactory(_sellVTokenFactory).vTokenOf(sellAsset)),
                buyVToken: IvToken(buyVToken),
                priceOracle: IPhuturePriceOracle(IIndexRegistry(registry).priceOracle())
            });
    }

    /// @notice Casts uint to uint248
    /// @param _value Value to convert
    /// @return Casted to uint248 value
    function _toUint248(uint _value) internal pure returns (uint248) {
        require(_value <= type(uint248).max, "Orderer: OVERFLOW");
        return uint248(_value);
    }

    uint256[46] private __gap;
}
