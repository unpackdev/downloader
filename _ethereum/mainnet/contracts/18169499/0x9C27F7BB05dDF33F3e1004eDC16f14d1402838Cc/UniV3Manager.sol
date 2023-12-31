// SPDX-License-Identifier: GPL
pragma solidity ^0.8.19;
pragma abicoder v2;


import "./ERC20.sol";
import "./SafeMath.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";

import "./INonfungiblePositionManager.sol";


contract UniV3Manager is ERC20 , AccessControl {
	using SafeERC20 for IERC20;
	using SafeMath for uint256;

    uint256 public tokenId;
    address public feeCollector;

    IERC20 public token0;
    IERC20 public token1;
    int24 public tickLower;
    int24 public tickUpper;
    uint24 public fee;

    INonfungiblePositionManager public NonfungiblePositionManager;

    constructor(string memory _name, string memory _symbol, address _admin, address positionManager) ERC20(_name, _symbol){
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        NonfungiblePositionManager = INonfungiblePositionManager(positionManager);
    }

    function setFeeCollector(address _feeCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeCollector = _feeCollector;
    }

    function mintV3NFT(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0Desired,
        uint256 _amount1Desired,
        uint256 _amount0Min,
        uint256 _amount1Min) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {

        require(tokenId == 0, "minted");
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: _token0,
            token1: _token1,
            fee: _fee,
            tickLower: _tickLower,
            tickUpper: _tickUpper,
            amount0Desired: _amount0Desired,
            amount1Desired: _amount1Desired,
            amount0Min: _amount0Min,
            amount1Min: _amount1Min,
            recipient: address(this),
            deadline: block.timestamp
            
        });
        token0 = IERC20(params.token0);
        token1 = IERC20(params.token1);
        token0.approve(address(NonfungiblePositionManager), params.amount0Desired);
        token1.approve(address(NonfungiblePositionManager), params.amount1Desired);
        token0.safeTransferFrom(msg.sender, address(this), params.amount0Desired);
        token1.safeTransferFrom(msg.sender, address(this), params.amount1Desired);

        (tokenId, liquidity, amount0, amount1) = NonfungiblePositionManager.mint(params);
        uint256 refundAmount0 = params.amount0Desired.sub(amount0);
        uint256 refundAmount1 = params.amount1Desired.sub(amount1);

        if(refundAmount0 != 0){
            token0.safeTransfer(msg.sender, refundAmount0);
        }

        if(refundAmount1 != 0){
            token1.safeTransfer(msg.sender, refundAmount1);
        }

        _mint(msg.sender, liquidity);

        tickLower = params.tickLower;
        tickUpper = params.tickLower;
        fee = params.fee;
    }

    function increaseLiquidity(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min)
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        token0.approve(address(NonfungiblePositionManager), amount0Desired);
        token1.approve(address(NonfungiblePositionManager), amount1Desired);
        token0.safeTransferFrom(msg.sender, address(this), amount0Desired);
        token1.safeTransferFrom(msg.sender, address(this), amount1Desired);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = NonfungiblePositionManager.increaseLiquidity(params);
        uint256 refundAmount0 = amount0Desired.sub(amount0);
        uint256 refundAmount1 = amount1Desired.sub(amount1);
        if(refundAmount0 != 0){
            token0.safeTransfer(msg.sender, refundAmount0);
        }

        if(refundAmount1 != 0){
            token1.safeTransfer(msg.sender, refundAmount1);
        }

        _mint(msg.sender, liquidity);
    }

    function decreaseLiquidity(uint128 liquidity, uint256 amount0Min, uint256 amount1Min)
        external
        returns (uint256 amount0, uint256 amount1)
    {
        _burn(msg.sender, liquidity);
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            deadline: block.timestamp
        });
        (amount0, amount1) = NonfungiblePositionManager.decreaseLiquidity(params);

        _collect();

        if(amount0 != 0){
            token0.safeTransfer(msg.sender, amount0);
        }

        if(amount1 != 0){
            token1.safeTransfer(msg.sender, amount1);
        }

        uint256 balanceOfToken0 = token0.balanceOf(address(this));
        if(balanceOfToken0 != 0){
            token0.safeTransfer(feeCollector, balanceOfToken0);
        }
        uint256 balanceOfToken1 = token1.balanceOf(address(this));
        if(balanceOfToken1 != 0){
            token1.safeTransfer(feeCollector, balanceOfToken1);
        }
    }

    function feeCollect() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _collect();
        uint256 balanceOfToken0 = token0.balanceOf(address(this));
        if(balanceOfToken0 != 0){
            token0.safeTransfer(feeCollector, balanceOfToken0);
        }
        uint256 balanceOfToken1 = token1.balanceOf(address(this));
        if(balanceOfToken1 != 0){
            token1.safeTransfer(feeCollector, balanceOfToken1);
        }
    }

    function _collect() internal
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        (amount0, amount1) = NonfungiblePositionManager.collect(params);
    }

    function recoverERC20(
		IERC20 tokenAddress,
		address target,
		uint256 amountToRecover
	) external onlyRole(DEFAULT_ADMIN_ROLE) {
		tokenAddress.safeTransfer(target, amountToRecover);
	}
}