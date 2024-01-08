//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";


interface ClipperPoolInterface {
    function exchangeInterfaceContract() external returns (address exchangeInterfaceAddress);
}

interface PLPAPIInterface {
    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount) external view returns (uint256 outputTokenAmount);
    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount);
    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external payable returns (uint256 boughtAmount);
    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount);
}

interface WrapperContractInterface {
  function withdraw(uint wad) external;
}

contract WrappedEthRouter {
    using SafeERC20 for IERC20;
    address public immutable CLIPPER_POOL_ADDRESS;
    address public immutable WRAPPED_ETH_CONTRACT_ADDRESS;
    address public exchangeAddress;
    address constant CLIPPER_ETH_SIGIL = address(0);
    bytes constant AUXILIARY_BYTES = "0x VIP PLP Router";

    receive() external payable {
    }

    constructor(address poolAddress, address wrappedEthContract) {
        CLIPPER_POOL_ADDRESS = poolAddress;
        WRAPPED_ETH_CONTRACT_ADDRESS = wrappedEthContract;
        exchangeAddress = ClipperPoolInterface(poolAddress).exchangeInterfaceContract();
    }

    function refreshExchangeContract() external {
        exchangeAddress = ClipperPoolInterface(CLIPPER_POOL_ADDRESS).exchangeInterfaceContract();
    }

    function safeEthSend(address recipient, uint256 howMuch) internal {
        (bool success, ) = payable(recipient).call{value: howMuch}("");
        require(success, "Eth send failed");
    }

    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount) {
        IERC20 _input = IERC20(inputToken);
        uint256 totalAmount = _input.balanceOf(address(this));
        if (inputToken == WRAPPED_ETH_CONTRACT_ADDRESS) { 
            WrapperContractInterface(WRAPPED_ETH_CONTRACT_ADDRESS).withdraw(totalAmount);
            safeEthSend(CLIPPER_POOL_ADDRESS, totalAmount);
            boughtAmount = PLPAPIInterface(exchangeAddress).sellEthForToken(outputToken, recipient, minBuyAmount, AUXILIARY_BYTES);
        } else {
            _input.safeTransfer(CLIPPER_POOL_ADDRESS, totalAmount);
            if (outputToken == WRAPPED_ETH_CONTRACT_ADDRESS) { 
                boughtAmount = PLPAPIInterface(exchangeAddress).sellTokenForEth(inputToken, payable(address(this)), minBuyAmount, AUXILIARY_BYTES);
                safeEthSend(payable(WRAPPED_ETH_CONTRACT_ADDRESS), boughtAmount);
                IERC20(WRAPPED_ETH_CONTRACT_ADDRESS).safeTransferFrom(address(this), recipient, boughtAmount);
            } else {
                boughtAmount = PLPAPIInterface(exchangeAddress).sellTokenForToken(inputToken, outputToken, recipient, minBuyAmount, AUXILIARY_BYTES);
            }
        }
    }

    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external payable returns (uint256 boughtAmount) {
        safeEthSend(CLIPPER_POOL_ADDRESS, address(this).balance);
        boughtAmount = PLPAPIInterface(exchangeAddress).sellEthForToken(outputToken, recipient, minBuyAmount, AUXILIARY_BYTES);
    }

    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount) {
        IERC20 _input = IERC20(inputToken);
        _input.safeTransfer(CLIPPER_POOL_ADDRESS, _input.balanceOf(address(this)));
        boughtAmount = PLPAPIInterface(exchangeAddress).sellTokenForEth(inputToken, recipient, minBuyAmount, AUXILIARY_BYTES);
    }

    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount) external view returns (uint256) {
        return PLPAPIInterface(exchangeAddress).getSellQuote(inputToken == WRAPPED_ETH_CONTRACT_ADDRESS ? CLIPPER_ETH_SIGIL : inputToken, outputToken == WRAPPED_ETH_CONTRACT_ADDRESS ? CLIPPER_ETH_SIGIL : outputToken, sellAmount);
    }
}