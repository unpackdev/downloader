pragma solidity ^0.8.0;

import "./Address.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IRouter.sol";
import "./IStrategy.sol";

interface Iswft {
    function swap(
        address fromToken,
        string memory toToken,
        string memory destination,
        uint256 fromAmount,
        uint256 minReturnAmount
    ) external;
    // project is keccak256(STRATEGY_NAME)
    function swapEth(string memory toToken, string memory destination, uint256 minReturnAmount) external payable;
}

contract SWFT is IStrategy {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    string public constant STRATEGY_NAME = "CROSSCHAIN_SWFT";
    string public constant VERSION = "V1";
    bytes32 public constant STRATEGY_NAME_BYTES32 = keccak256("CROSSCHAIN_SWFT");

    event SwapEvent(uint256 fee);

    function getStrategyVersion() external pure override returns (string memory) {
        return string(abi.encodePacked(STRATEGY_NAME, "_", VERSION));
    }

    function swap(bytes calldata data, address to, uint256 fee) public {
        require(
            IRouter(address(this)).projectWhiteList(STRATEGY_NAME_BYTES32, to),
            "Swap ERROR: to address not in whiteList"
        );

        (
            address fromToken,
            string memory toToken,
            string memory destination,
            uint256 fromAmount,
            uint256 minReturnAmount
        ) = abi.decode(data[4:], (address, string, string, uint256, uint256));

        IERC20(fromToken).safeTransferFrom(msg.sender, address(this), fromAmount.add(fee));

        if (fee > 0) {
            IERC20(fromToken).safeTransfer(IRouter(address(this)).config().crossChainFeeTo(), fee);
        }

        IERC20(fromToken).approve(to, fromAmount);

        Iswft(to).swap(fromToken, toToken, destination, fromAmount, minReturnAmount);

        emit SwapEvent(fee);
    }

    function swapEth(bytes calldata data, address to, uint256 amount, uint256 fee) public payable {
        require(
            IRouter(address(this)).projectWhiteList(STRATEGY_NAME_BYTES32, to),
            "Swap ETH ERROR: to address not in whiteList"
        );

        require(msg.value == amount.add(fee), "Erro: value error");

        (string memory toToken, string memory destination, uint256 minReturnAmount) =
            abi.decode(data[4:], (string, string, uint256));

        if (fee > 0) payable(IRouter(address(this)).config().crossChainFeeTo()).transfer(fee);

        Iswft(to).swapEth{value: msg.value.sub(fee)}(toToken, destination, minReturnAmount);
        emit SwapEvent(fee);
    }
}
