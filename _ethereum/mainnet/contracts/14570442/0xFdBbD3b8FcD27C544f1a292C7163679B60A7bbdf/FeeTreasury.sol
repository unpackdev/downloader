// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./OwnableUninitialized.sol";
import "./SafeERC20.sol";
import "./IManagerProxy.sol";
import "./IArrakisVaultV1.sol";
import "./IFeeTreasury.sol";
import "./IFeeDistributor.sol";
import "./IUniswapV3Pool.sol";
import "./Initializable.sol";

// solhint-disable-next-line max-states-count
contract FeeTreasury is IFeeTreasury, OwnableUninitialized, Initializable {
    using SafeERC20 for IERC20;

    address private immutable _weth;

    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX
    IArrakisVaultV1 public lpToken;
    mapping(address => bool) public whitelistedRouter;
    mapping(address => bool) public whitelistedAdmin;
    address public feeDistributor;
    address public operationsCollector;
    uint32 public twapDuration;
    uint24 public maxTwapDelta;
    uint16 public protocolFeeBPS;

    // APPPEND ADDITIONAL STATE VARS BELOW:
    // XXXXXXXX DO NOT MODIFY ORDERING XXXXXXXX

    modifier onlyAdmins() {
        require(
            msg.sender == _owner || whitelistedAdmin[msg.sender],
            "FeeTreasury: onlyAdmins"
        );
        _;
    }

    constructor(address weth_) {
        _weth = weth_;
    }

    function initialize(
        IArrakisVaultV1 lpToken_,
        address owner_,
        address feeDistributor_,
        uint16 protocolFeeBPS_,
        uint24 maxTwapDelta_,
        uint32 twapDuration_,
        address[] memory routers_,
        address[] memory admins_
    ) external initializer {
        require(protocolFeeBPS_ <= 10000, "FeeTreasury: BPS");
        require(
            address(lpToken_.token0()) == _weth ||
                address(lpToken_.token1()) == _weth,
            "FeeTreasury: must include WETH"
        );
        for (uint256 i = 0; i < admins_.length; i++) {
            whitelistedAdmin[admins_[i]] = true;
        }
        for (uint256 j = 0; j < routers_.length; j++) {
            whitelistedRouter[routers_[j]] = true;
        }
        lpToken = lpToken_;
        feeDistributor = feeDistributor_;
        maxTwapDelta = maxTwapDelta_;
        twapDuration = twapDuration_;
        protocolFeeBPS = protocolFeeBPS_;
        _owner = owner_;
        operationsCollector = owner_;
    }

    // ====== PERMISSIONED OWNER FUNCTIONS ========
    function whitelistRouters(address[] memory whitelist)
        external
        override
        onlyAdmins
    {
        for (uint256 i = 0; i < whitelist.length; i++) {
            whitelistedRouter[whitelist[i]] = true;
        }
        emit AddRouters(whitelist);
    }

    function blacklistRouters(address[] memory blacklist)
        external
        override
        onlyAdmins
    {
        for (uint256 i = 0; i < blacklist.length; i++) {
            whitelistedRouter[blacklist[i]] = false;
        }
        emit RemoveRouters(blacklist);
    }

    function whitelistAdmins(address[] memory whitelist)
        external
        override
        onlyAdmins
    {
        for (uint256 i = 0; i < whitelist.length; i++) {
            whitelistedAdmin[whitelist[i]] = true;
        }
        emit AddAdmins(whitelist);
    }

    function blacklistAdmins(address[] memory blacklist)
        external
        override
        onlyAdmins
    {
        for (uint256 i = 0; i < blacklist.length; i++) {
            whitelistedAdmin[blacklist[i]] = false;
        }
        emit RemoveAdmins(blacklist);
    }

    function updateFeeDistributor(address newFeeDistributor)
        external
        override
        onlyAdmins
    {
        feeDistributor = newFeeDistributor;
        emit UpdateFeeDistributor(newFeeDistributor);
    }

    function updateProtocolFeeBPS(uint16 newProtocolFeeBPS)
        external
        override
        onlyAdmins
    {
        require(newProtocolFeeBPS <= 10000, "FeeTreasury: BPS");
        protocolFeeBPS = newProtocolFeeBPS;
        emit UpdateProtocolFeeBPS(newProtocolFeeBPS);
    }

    function updateMaxTwapDelta(uint24 newMaxTwapDelta)
        external
        override
        onlyAdmins
    {
        maxTwapDelta = newMaxTwapDelta;
        emit UpdateMaxTwapDelta(newMaxTwapDelta);
    }

    function updateTwapDuration(uint32 newTwapDuration)
        external
        override
        onlyAdmins
    {
        twapDuration = newTwapDuration;
        emit UpdateTwapDuration(newTwapDuration);
    }

    function updateLPToken(address newLPToken) external override onlyAdmins {
        IArrakisVaultV1 _newLPToken = IArrakisVaultV1(newLPToken);
        require(
            address(_newLPToken.token0()) == _weth ||
                address(_newLPToken.token1()) == _weth,
            "FeeTreasury: must include WETH"
        );
        lpToken = _newLPToken;
        emit UpdateLPToken(newLPToken);
    }

    function updateOperationsCollector(address newOperations)
        external
        override
        onlyAdmins
    {
        require(newOperations != address(0), "FeeTreasury: zero address");
        operationsCollector = newOperations;
        emit UpdateOperationsCollector(newOperations);
    }

    function multiSwapForWETH(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        address[] memory routers,
        bytes[] memory swapPayloads
    ) external override onlyAdmins {
        for (uint256 i = 0; i < swapPayloads.length; i++) {
            require(
                address(tokens[i]) != _weth,
                "FeeTreasury: cannot swap weth"
            );
            _swapForWETH(tokens[i], amounts[i], routers[i], swapPayloads[i]);
        }
    }

    function swapForWETH(
        IERC20 token,
        uint256 amount,
        address router,
        bytes memory swapPayload
    ) external override onlyAdmins {
        require(address(token) != _weth, "FeeTreasury: cannot swap weth");
        _swapForWETH(token, amount, router, swapPayload);
    }

    // solhint-disable-next-line function-max-lines
    function disperseProtocolFees(
        uint256 amount,
        address router,
        bytes memory swapPayload
    ) external override onlyAdmins {
        _checkTwap();
        IArrakisVaultV1 _lpToken = lpToken;
        IERC20 token0 = _lpToken.token0();
        IERC20 token1 = _lpToken.token1();
        uint256 balanceBefore;
        uint256 balanceAfter;
        bool isToken0 = address(token0) == _weth;
        if (isToken0) {
            balanceBefore = token1.balanceOf(address(this));
            _swap(token0, amount, router, swapPayload);
            balanceAfter = token1.balanceOf(address(this));
        } else {
            balanceBefore = token0.balanceOf(address(this));
            _swap(token1, amount, router, swapPayload);
            balanceAfter = token0.balanceOf(address(this));
        }
        require(
            balanceBefore < balanceAfter,
            "FeeTreasury: did not swap for valid output token"
        );
        uint256 wethBalance = IERC20(_weth).balanceOf(address(this));
        uint256 protocolWeth = (wethBalance * protocolFeeBPS) / 10000;
        if (wethBalance > protocolWeth) {
            IERC20(_weth).safeTransfer(
                operationsCollector,
                wethBalance - protocolWeth
            );
        }
        (uint256 deposit0, uint256 deposit1, uint256 mint) = _lpToken
            .getMintAmounts(
                isToken0 ? protocolWeth : balanceAfter - balanceBefore,
                isToken0 ? balanceAfter - balanceBefore : protocolWeth
            );
        token0.safeIncreaseAllowance(address(_lpToken), deposit0);
        token1.safeIncreaseAllowance(address(_lpToken), deposit1);
        _lpToken.mint(mint, address(this));
        uint256 lpBalance = IERC20(address(_lpToken)).balanceOf(address(this));
        IERC20(address(_lpToken)).safeIncreaseAllowance(
            feeDistributor,
            lpBalance
        );
        IFeeDistributor(feeDistributor).setReward(lpBalance);
        emit DisperseProtocolFees(deposit0, deposit1, lpBalance);
    }

    // ====== INTERNAL FUNCTIONS ========
    function _swapForWETH(
        IERC20 token,
        uint256 amount,
        address router,
        bytes memory swapPayload
    ) internal returns (uint256 balanceChange) {
        uint256 balanceBefore = IERC20(_weth).balanceOf(address(this));
        _swap(token, amount, router, swapPayload);
        balanceChange = IERC20(_weth).balanceOf(address(this)) - balanceBefore;
        require(
            balanceChange > 0,
            "FeeTreasury: did not swap for valid output token"
        );
    }

    function _swap(
        IERC20 token,
        uint256 amount,
        address router,
        bytes memory swapPayload
    ) internal {
        require(
            whitelistedRouter[router],
            "FeeTreasury: router not whitelisted"
        );
        token.safeIncreaseAllowance(router, amount);
        (bool success, ) = router.call(swapPayload);
        require(success, "FeeTreasury: swap call failed");
    }

    function _checkTwap() internal view {
        uint32 _twapDuration = twapDuration;
        IUniswapV3Pool uniPool = lpToken.pool();
        (, int24 tick, , , , , ) = uniPool.slot0();

        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = _twapDuration;
        secondsAgo[1] = 0;
        (int56[] memory tickCumulatives, ) = uniPool.observe(secondsAgo);

        int24 twap;
        unchecked {
            twap = int24(
                (tickCumulatives[1] - tickCumulatives[0]) /
                    int56(uint56(_twapDuration))
            );
        }

        int24 delta = tick > twap ? tick - twap : twap - tick;
        require(
            delta <= int24(maxTwapDelta),
            "FeeTreasury: frontrun protection"
        );
    }
}
