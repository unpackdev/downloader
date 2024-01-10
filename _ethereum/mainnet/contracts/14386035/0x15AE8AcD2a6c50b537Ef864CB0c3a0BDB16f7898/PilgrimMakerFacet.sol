// SPDX-License-Identifier: BUSL-1.1
// Note: The majority part of this code has been derived from the Sushiswap SushiMaker code (MIT).
pragma solidity ^0.8.9;
pragma abicoder v2;

import "./IERC20Minimal.sol";
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";

import "./ISwapRouter.sol";
import "./TransferHelper.sol";

import "./LibAppStorage.sol";
import "./Modifiers.sol";
import "./LibDiamond.sol";
import "./IPilgrimTreasury.sol";

/// @title This contract handles rewards for xPIL holders by swapping tokens collected from fees to PILs.
///
/// @author rn.ermaid
///
contract PilgrimMakerFacet is Modifiers {
    AppStorage internal s;

    IUniswapV3Factory public immutable factory;
    ISwapRouter public immutable swapRouter;

    address private immutable pil;

    event LogBridgeSet(address indexed from, address indexed to, uint24 fee);

    event LogConvert(
        address indexed server,
        address indexed token,
        uint256 amount,
        uint256 amountPIL,
        uint256 subsidization
    );

    constructor(
        address _factory,
        address _pil,
        ISwapRouter _swapRouter
    ) {
        factory = IUniswapV3Factory(_factory);
        pil = _pil;
        swapRouter = _swapRouter;
    }

    function bridgeFor(address token) external view returns (address from, address to, uint24 fee) {
        Bridge storage bridge = s.bridges[token];
        (from, to, fee) = (bridge.from, bridge.to, bridge.fee);
    }

    /// @notice  Set bridge token used to swap to PIL
    ///
    function setBridge(address from, address to, uint24 fee) external {
        LibDiamond.enforceIsContractOwner();

        // Checks
        require(from != pil && from != to, "PilgrimMaker: Invalid bridge");

        // Validate pool
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(from, to, fee));
        require(address(pool) != address(0), "PilgrimMaker: Invalid bridge, no Uniswap pool found");

        // Effects, Optimistically set bridge
        s.bridges[from] = Bridge({ from: from, to: to, fee: fee });
        emit LogBridgeSet(from, to, fee);

        // Check no cycle
        Bridge storage bridge = s.bridges[from];
        while (bridge.to != pil) {
            bridge = s.bridges[bridge.to];
            // Bridges must end up with PIL
            require(bridge.to != address(0), "PilgrimMaker: Invalid bridge, no route to PIL found");
            require(bridge.to != from, "PilgrimMaker: Invalid bridge, cycle detected");
        }
    }

    function convertToPIL(address token) external onlyOneBlock {
        _convertToPIL(token);
    }

    function convertMultipleTokensToPIL(address[] calldata tokens) external onlyOneBlock {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; i++) {
            _convertToPIL(tokens[i]);
        }
    }

    function _convertToPIL(address from) internal returns (uint256 amountOut) {
        Bridge storage bridge = s.bridges[from];
        require(bridge.to != address(0), "PilgrimMaker: Invalid token, no bridge found");

        uint amountIn = IERC20Minimal(from).balanceOf(address(this));
        if (amountIn == 0) {
            return 0;
        }

        amountOut = amountIn;
        while (bridge.to != pil) {
            amountOut = _swap(bridge, amountOut, address(this));
            bridge = s.bridges[bridge.to];
            // TODO: Route existence is already ensured in setBridge. Do we need this validation?
            require(bridge.to != address(0), "PilgrimMaker: Invalid token, no route to PIL found");
        }
        amountOut = _swap(bridge, amountOut, address(this));
        uint256 subsidization = amountOut * s.subsidizationNumerator / s.subsidizationDenominator;
        IPilgrimTreasury(s.treasury).withdraw(address(this), subsidization);
        emit LogConvert(
            msg.sender,
            from,
            amountIn,
            amountOut,
            subsidization
        );
    }

    function _swap(Bridge memory bridge, uint256 amountIn, address to) internal returns (uint256 amountOut) {
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(bridge.from, bridge.to, bridge.fee));
        require(address(pool) != address(0), "PilgrimMaker: Invalid pair, cannot convert");

        // Approve the router to spend token.
        TransferHelper.safeApprove(bridge.from, address(swapRouter), amountIn);

        // Naively set amountOutMinimum to 0.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: bridge.from,
            tokenOut: bridge.to,
            fee: bridge.fee,
            recipient: to,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }

    function setTreasury(address _treasury) external {
        LibDiamond.enforceIsContractOwner();
        s.treasury = _treasury;
    }

    function getSubsidizationRatio() external view returns (uint32 _numerator, uint32 _denominator) {
        _numerator = s.subsidizationNumerator;
        _denominator = s.subsidizationDenominator;
    }

    function setSubsidizationRatio(uint32 _numerator, uint32 _denominator) external {
        LibDiamond.enforceIsContractOwner();
        require(_denominator > 0);
        s.subsidizationNumerator = _numerator;
        s.subsidizationDenominator = _denominator;
    }

}
