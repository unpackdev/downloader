// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseBurner.sol";
import "./ReentrancyGuard.sol";

interface ISNX {
    function exchange(
        bytes32 sourceCurrencyKey,
        uint256 sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint256 amountReceived);

    function settle(bytes32 currencyKey) external returns (uint256[3] calldata);
}

interface ISynth {
    function currencyKey() external returns (bytes32);

    function transferAndSettle(address to, uint256 amount)
        external
        returns (bool);
}

contract SynthetixBurner is BaseBurner, ReentrancyGuard {
    address public SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;

    constructor(address _receiver, address _snx) BaseBurner(_receiver) {
        SNX = _snx;
    }

    /* User functions */
    function burn(address token)
        external
        onlyBurnableToken(token)
        nonReentrant
        returns (uint256)
    {
        require(receiver != address(0), "receiver not set");
        address targetToken = burnableTokens[token];
        uint256 initialTargetTokenBalance = IERC20(targetToken).balanceOf(
            address(this)
        );
        if (initialTargetTokenBalance > 0) {
            // Synthetix imposes a waiting period on any action of exchange(10 min)
            // https://blog.synthetix.io/how-fee-reclamation-rebates-work/
            ISynth(targetToken).transferAndSettle(
                receiver,
                initialTargetTokenBalance
            );
        }
        bytes32 burnableTokenCurrencyKey = ISynth(token).currencyKey();
        uint256 msgSenderBalance = IERC20(token).balanceOf(msg.sender);
        if (msgSenderBalance != 0) {
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                msgSenderBalance
            );
        }
        uint256 amountToBurn = IERC20(token).balanceOf(address(this));
        if (amountToBurn != 0) {
            // Due to Synthetix's waiting period, Do nothing after exchanging for target token;
            ISNX(SNX).exchange(
                burnableTokenCurrencyKey,
                amountToBurn,
                ISynth(targetToken).currencyKey()
            );
        }
        return msgSenderBalance;
    }
}
