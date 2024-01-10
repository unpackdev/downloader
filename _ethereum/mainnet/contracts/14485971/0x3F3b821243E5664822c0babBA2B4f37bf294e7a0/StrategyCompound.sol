// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./SafeERC20.sol";

import "./ICErc20.sol";
import "./ICEth.sol";
import "./IWrappedToken.sol";
import "./IUniswapV2Router02.sol";
import "./IStrategyPool.sol";

/**
 * @title Compound pool
 */
contract StrategyCompound is IStrategyPool, Ownable {
    using SafeERC20 for IERC20;

    address public broker;
    modifier onlyBroker() {
        require(msg.sender == broker, "caller is not broker");
        _;
    }

    address public immutable comp; // compound comp token
    address public immutable uniswap; // The address of the Uniswap V2 router
    address public immutable weth; // The address of WETH token

    event BrokerUpdated(address broker);
    event WrapTokenUpdated(address wrapToken, bool enabled);

    mapping(address => bool) public supportedWrapTokens; //wrappedtoken => true

    constructor(
        address _broker,
        address _comp,
        address _uniswap,
        address _weth
    ) {
        broker = _broker;
        comp = _comp;
        uniswap = _uniswap;
        weth = _weth;
    }

    function sellErc(address inputToken, address outputToken, uint256 inputAmt) external onlyBroker returns (uint256 outputAmt) {
        bool toBuy = supportedWrapTokens[outputToken];
        bool toSell = supportedWrapTokens[inputToken];

        require(toBuy || toSell, "not supported tokens!");

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmt);
        if (toBuy) { // to buy a wrapped token
            address cToken = IWrappedToken(outputToken).underlyingCToken();
            IERC20(inputToken).safeIncreaseAllowance(cToken, inputAmt);
            uint256 mintResult = ICErc20(cToken).mint(inputAmt);
            require(mintResult == 0, "Couldn't mint cToken");
            outputAmt = ICErc20(cToken).balanceOf(address(this));
            
            // transfer cToken into wrapped token contract and mint equal wrapped tokens 
            IERC20(cToken).safeIncreaseAllowance(outputToken, outputAmt);
            IWrappedToken(outputToken).mint(outputAmt);

            IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
        } else { // to sell a wrapped token
            address cToken = IWrappedToken(inputToken).underlyingCToken();
            
            // transfer cToken/comp from wrapped token contract and burn the wrapped tokens 
            IWrappedToken(inputToken).burn(inputAmt);
            uint256 redeemResult = ICErc20(cToken).redeem(inputAmt);
            require(redeemResult == 0, "Couldn't redeem cToken");

            if (outputToken != address(0) /*ERC20*/) {
                sellCompForErc(outputToken);
                outputAmt = IERC20(outputToken).balanceOf(address(this));
                IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
            } else /*ETH*/ {
                sellCompForEth();
                outputAmt = address(this).balance;
                (bool success, ) = msg.sender.call{value: outputAmt}(""); // NOLINT: low-level-calls.
                require(success, "eth transfer failed");
            }
        }
    }

    function sellCompForErc(address target) private {
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            // Sell COMP token for obtain more supplying token(e.g. DAI, USDT)
            IERC20(comp).safeIncreaseAllowance(uniswap, compBalance);

            address[] memory paths = new address[](3);
            paths[0] = comp;
            paths[1] = weth;
            paths[2] = target;

            IUniswapV2Router02(uniswap).swapExactTokensForTokens(
                compBalance,
                uint256(0),
                paths,
                address(this),
                block.timestamp + 1800
            );
        }
    }

    function sellCompForEth() private {
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            // Sell COMP token for obtain more ETH
            IERC20(comp).safeIncreaseAllowance(uniswap, compBalance);

            address[] memory paths = new address[](2);
            paths[0] = comp;
            paths[1] = weth;

            IUniswapV2Router02(uniswap).swapExactTokensForETH(
                compBalance,
                uint256(0),
                paths,
                address(this),
                block.timestamp + 1800
            );
        }
    }

    function sellEth(address outputToken) external onlyBroker payable returns (uint256 outputAmt) {
        require(supportedWrapTokens[outputToken], "not supported tokens!");
        
        address cToken = IWrappedToken(outputToken).underlyingCToken();
        ICEth(cToken).mint{value: msg.value}();
        outputAmt = ICEth(cToken).balanceOf(address(this));

        // transfer cToken into wrapped token contract and mint equal wrapped tokens 
        IERC20(cToken).safeIncreaseAllowance(outputToken, outputAmt);
        IWrappedToken(outputToken).mint(outputAmt);

        IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
    }

    function updateBroker(address _broker) external onlyOwner {
        broker = _broker;
        emit BrokerUpdated(broker);
    }

    function setSupportedWrapToken(address _wrapToken, bool _enabled) external onlyOwner {
        supportedWrapTokens[_wrapToken] = _enabled;
        emit WrapTokenUpdated(_wrapToken, _enabled);
    }

    receive() external payable {}
    fallback() external payable {}
}
