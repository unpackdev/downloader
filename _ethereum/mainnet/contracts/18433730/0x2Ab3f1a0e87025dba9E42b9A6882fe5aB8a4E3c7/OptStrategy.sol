// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Clones.sol";

import "./IUniswapV3Pool.sol";
import "./INonfungiblePositionManager.sol";
import "./IVaultFacet.sol";

import "./UniV3TokenRegistry.sol";
import "./UniV3MEVProtection.sol";
import "./ProxyToken.sol";

import "./UniV3ERC20Oracle.sol";

import "./BaseStrategy.sol";

contract OptStrategy is BaseStrategy {
    error LimitOverflow();
    error ValueZero();
    error Forbidden();
    error InvalidState();

    enum State {
        UNISWAP,
        YIELD_0,
        YIELD_1,
        INVALID
    }

    struct ImmutableParams {
        address owner;
        address vault;
        UniV3Token token;
        IUniswapV3Pool pool;
        address yieldToken0;
        address yieldToken1;
        int24 lowerTick;
        int24 upperTick;
    }

    struct MutableParams {
        int24 lowerTriggerTick;
        int24 upperTriggerTick;
        uint32 timespan;
        bytes securityParams;
    }

    using SafeERC20 for IERC20;

    INonfungiblePositionManager public immutable positionManager;
    UniV3TokenRegistry public immutable registry;
    UniV3ERC20Oracle public immutable uniV3ERC20Oracle;
    UniV3MEVProtection public immutable mevProtection;

    // zk abstraction
    constructor(
        INonfungiblePositionManager positionManager_,
        UniV3TokenRegistry registry_,
        UniV3ERC20Oracle uniV3ERC20Oracle_,
        UniV3MEVProtection mevProtection_
    ) {
        positionManager = positionManager_;
        registry = registry_;
        uniV3ERC20Oracle = uniV3ERC20Oracle_;
        mevProtection = mevProtection_;
    }

    modifier onlyOwner() override {
        if (getImmutableParams().owner != msg.sender) revert Forbidden();
        _;
    }

    modifier onlyVault() override {
        if (getImmutableParams().vault != msg.sender) revert Forbidden();
        _;
    }

    modifier ensureNoMEV() override {
        mevProtection.ensureNoMEV(address(getImmutableParams().pool), getMutableParams().securityParams);
        _;
    }

    function initialize(
        ImmutableParams memory immutableParams,
        MutableParams memory mutableParams,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external {
        Storage storage s = _contractStorage();
        if (getImmutableParams().owner != address(0)) revert Forbidden();
        if (immutableParams.owner == address(0)) revert ValueZero();
        immutableParams.token = _mintTokenMEVUnsafe(
            immutableParams,
            mutableParams.securityParams,
            amount0Desired,
            amount1Desired
        );

        s.immutableParams = abi.encode(immutableParams);
        s.mutableParams = abi.encode(mutableParams);
        s.currentState = uint256(State.UNISWAP);
        s.previousState = uint256(State.UNISWAP);
    }

    function _mintTokenMEVUnsafe(
        ImmutableParams memory immutableParams,
        bytes memory securityParams,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) private returns (UniV3Token) {
        IUniswapV3Pool pool = immutableParams.pool;
        address token0 = pool.token0();
        address token1 = pool.token1();

        IERC20(token0).safeApprove(address(positionManager), type(uint256).max);
        IERC20(token1).safeApprove(address(positionManager), type(uint256).max);

        (uint256 uniV3Nft, , , ) = positionManager.mint(
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: pool.fee(),
                tickLower: immutableParams.lowerTick,
                tickUpper: immutableParams.upperTick,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: type(uint256).max
            })
        );

        positionManager.approve(address(registry), uniV3Nft);
        (, address uniV3Token) = registry.createToken(
            UniV3Token.InitParams({
                positionId: uniV3Nft,
                name: "OptStrategy UniV3Token",
                symbol: "MUT",
                admin: address(0),
                strategy: address(this),
                oracle: address(uniV3ERC20Oracle),
                securityParams: securityParams
            })
        );

        return UniV3Token(uniV3Token);
    }

    function getImmutableParams() public view returns (ImmutableParams memory) {
        bytes memory params = _contractStorage().immutableParams;
        if (params.length == 0) {
            return
                ImmutableParams({
                    owner: address(0),
                    vault: address(0),
                    token: UniV3Token(address(0)),
                    pool: IUniswapV3Pool(address(0)),
                    yieldToken0: address(0),
                    yieldToken1: address(0),
                    lowerTick: int24(0),
                    upperTick: int24(0)
                });
        }
        return abi.decode(params, (ImmutableParams));
    }

    function getMutableParams() public view returns (MutableParams memory) {
        bytes memory params = _contractStorage().mutableParams;
        if (params.length == 0) {
            return
                MutableParams({
                    lowerTriggerTick: int24(0),
                    upperTriggerTick: int24(0),
                    timespan: uint32(0),
                    securityParams: new bytes(0)
                });
        }
        return abi.decode(params, (MutableParams));
    }

    function getAverageTick() public view returns (int24 averageTick) {
        bool withFail;
        (averageTick, , withFail) = OracleLibrary.consult(
            address(getImmutableParams().pool),
            getMutableParams().timespan
        );
        if (withFail) revert("Not enough observations");
    }

    function getNextState(uint256 currentState) public view override returns (uint256 nextState) {
        int24 averageTick = getAverageTick();
        MutableParams memory mutableParams = getMutableParams();
        ImmutableParams memory immutableParams = getImmutableParams();

        if (State(currentState) == State.UNISWAP) {
            if (averageTick > immutableParams.upperTick) {
                return uint256(State.YIELD_1);
            } else if (averageTick < immutableParams.lowerTick) {
                return uint256(State.YIELD_0);
            }
        } else if (State(currentState) == State.YIELD_0) {
            if (averageTick > mutableParams.lowerTriggerTick) {
                return uint256(State.UNISWAP);
            }
        } else if (State(currentState) == State.YIELD_1) {
            if (averageTick < mutableParams.upperTriggerTick) {
                return uint256(State.UNISWAP);
            }
        }
        return currentState;
    }

    function analyzeCurrentState() public view override returns (uint256) {
        ImmutableParams memory immutableParams = getImmutableParams();
        (address[] memory tokens, uint256[] memory amounts) = IVaultFacet(immutableParams.vault).getTokensAndAmounts();
        uint256 index = tokens.length;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] == 0) continue;
            if (index != tokens.length) return uint256(State.INVALID);
            index = i;
        }
        if (index == tokens.length) return uint256(State.INVALID);
        address token = tokens[index];
        if (token == address(immutableParams.token)) return uint256(State.UNISWAP);
        if (token == immutableParams.yieldToken0) return uint256(State.YIELD_0);
        if (token == immutableParams.yieldToken1) return uint256(State.YIELD_1);
        return uint256(State.INVALID);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        Storage storage s = _contractStorage();
        ImmutableParams memory immutableParams = getImmutableParams();
        immutableParams.owner = newOwner;
        s.immutableParams = abi.encode(immutableParams);
    }

    function saveState() external override onlyVault {
        Storage storage s = _contractStorage();
        s.previousState = s.currentState;
        uint256 currentState = analyzeCurrentState();
        if (State(currentState) == State.INVALID) revert InvalidState();
        s.currentState = uint256(currentState);
    }
}
