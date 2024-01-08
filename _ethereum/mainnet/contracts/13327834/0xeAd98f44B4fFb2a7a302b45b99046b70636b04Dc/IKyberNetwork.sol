pragma solidity 0.5.17;

import "./ERC20Detailed.sol";

/**
 * @title The interface for the Kyber Network smart contract
 * @author Zefram Lou (Zebang Liu)
 */
interface IKyberNetwork {
    function getExpectedRate(
        ERC20Detailed src,
        ERC20Detailed dest,
        uint256 srcQty
    ) external view returns (uint256 expectedRate, uint256 slippageRate);

    function tradeWithHint(
        ERC20Detailed src,
        uint256 srcAmount,
        ERC20Detailed dest,
        address payable destAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint256);
}
