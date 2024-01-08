// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IYieldTokenCompounding.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";

/// @notice Yield token compounding without having to swap to basetokens from ETH manually
/// This contract was intended to be used for simulation purposes only
contract YTCZap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct YTCInputs {
        IYieldTokenCompounding ytcContract;
        uint8 n;
        address trancheAddress;
        bytes32 balancerPoolId;
        uint256 amount;
        uint256 expectedYtOutput;
        uint256 expectedBaseTokensSpent;
        address baseToken;
        address yieldToken;
    }

    struct SwapInputs {
        uint256 deadline;
        address payable uniswapContract;
        bytes zapperCallData;
        address payable zapperContract;
    }

    function compoundUniswap(
        address _ytcContractAddress,
        uint8 _n,
        address _trancheAddress,
        bytes32 _balancerPoolId,
        uint256 _amount,
        uint256 _expectedYtOutput,
        uint256 _expectedBaseTokensSpent,
        address _baseToken,
        address _yieldToken,
        uint256 _deadline,
        address payable _uniswapContract
    ) external payable returns (uint256, uint256) {
        YTCInputs memory ytcInputs = _initYTCInputs(
            _ytcContractAddress,
            _n,
            _trancheAddress,
            _balancerPoolId,
            _amount,
            _expectedYtOutput,
            _expectedBaseTokensSpent,
            _baseToken,
            _yieldToken
        );

        SwapInputs memory swapInputs;
        {
            swapInputs.deadline = _deadline;
            swapInputs.uniswapContract = _uniswapContract;
        }

        return _compound(
            ytcInputs,
            swapInputs,
            1
        );
    }
    
    function compoundZapper(
        address _ytcContractAddress,
        uint8 _n,
        address _trancheAddress,
        bytes32 _balancerPoolId,
        uint256 _amount,
        uint256 _expectedYtOutput,
        uint256 _expectedBaseTokensSpent,
        address _baseToken,
        address _yieldToken,
        bytes calldata _zapperCallData,
        address payable _zapperContract
    ) external payable returns (uint256, uint256) {

        YTCInputs memory ytcInputs = _initYTCInputs(
            _ytcContractAddress,
            _n,
            _trancheAddress,
            _balancerPoolId,
            _amount,
            _expectedYtOutput,
            _expectedBaseTokensSpent,
            _baseToken,
            _yieldToken
        );

        SwapInputs memory swapInputs;
        {
            swapInputs.zapperCallData = _zapperCallData;
            swapInputs.zapperContract = _zapperContract;
        }

        return _compound(
            ytcInputs,
            swapInputs,
            0
        );
    }

    function _initYTCInputs(
        address _ytcContractAddress,
        uint8 _n,
        address _trancheAddress,
        bytes32 _balancerPoolId,
        uint256 _amount,
        uint256 _expectedYtOutput,
        uint256 _expectedBaseTokensSpent,
        address _baseToken,
        address _yieldToken
    ) internal pure returns (YTCInputs memory){
        YTCInputs memory ytcInputs;

        // We need to do this in two separate blocks due to local variable limits
        {
            ytcInputs.ytcContract = IYieldTokenCompounding(_ytcContractAddress);
            ytcInputs.n = _n;
            ytcInputs.trancheAddress = _trancheAddress;
            ytcInputs.balancerPoolId = _balancerPoolId;
            ytcInputs.expectedYtOutput = _expectedYtOutput;
        }
        {
            ytcInputs.amount = _amount;
            ytcInputs.expectedBaseTokensSpent = _expectedBaseTokensSpent;
            ytcInputs.baseToken = _baseToken;
            ytcInputs.yieldToken = _yieldToken;
        }

        return ytcInputs;
    }
    
    // Requires all the same inputs as YieldTokenCompoundingSwap + the address of the base token, the yield token, and the zapper information
    function _compound(
        YTCInputs memory ytcInputs,
        SwapInputs memory swapInputs,
        uint256 _type
    ) internal returns (uint256, uint256) {


        uint256 swappedAmount;
        {
            // get the initial balance of the base tokens
            uint256 initialBalance = _getBalance(ytcInputs.baseToken);

            // execute the correct swap based on the type
            if (_type == 0){
                _executeCurveSwap(msg.value, swapInputs.zapperContract, swapInputs.zapperCallData);
            } else if (_type == 1){
                _executeUniswapSwap(msg.value, ytcInputs.baseToken, ytcInputs.amount, swapInputs.deadline, swapInputs.uniswapContract);
            }

            // calculate the amount that was received in the swap
            swappedAmount = _getBalance(ytcInputs.baseToken).sub(initialBalance);

            // if the swappedAmount isn't greater than 0, something went wrong
            require (swappedAmount > 0, "Swapped to Invalid Token"); 
            // if the swappedAmount isn't greater than the compounding amount, the compounding will fail
            require(swappedAmount >= ytcInputs.amount, "Not enough tokens received in swap");
        }

        // approve the ytc contract to spend the base token
        IERC20(ytcInputs.baseToken).approve(address(ytcInputs.ytcContract), ytcInputs.amount);

        // Run the ytc contract
        uint256 yieldTokensReceived;
        uint256 baseTokensSpent;
        {
            (yieldTokensReceived, baseTokensSpent ) = ytcInputs.ytcContract.compound(ytcInputs.n, ytcInputs.trancheAddress, ytcInputs.balancerPoolId, ytcInputs.amount, ytcInputs.expectedYtOutput, ytcInputs.expectedBaseTokensSpent);
        }

        // transfer the received yield tokens, and the remaining baseTokens
        IERC20(ytcInputs.baseToken).safeTransfer(msg.sender, swappedAmount - baseTokensSpent);
        IERC20(ytcInputs.yieldToken).safeTransfer(msg.sender, yieldTokensReceived);

        return (yieldTokensReceived, baseTokensSpent);
    }
    
    function _executeCurveSwap(uint256 _value, address payable _zapperContract, bytes memory _zapperCallData) private {
        (bool success, ) = _zapperContract.call{value: _value}(_zapperCallData);

        require(success, "Zap Failed");
    }

    function _executeUniswapSwap(uint256 _value, address _baseToken, uint256 _amount, uint256 _deadline, address _uniswapRouterAddress) private{
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = _baseToken;

        uniswapRouter.swapExactETHForTokens{value: _value}(_amount, path, address(this), _deadline);
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }
}
