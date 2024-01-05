// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;


import "./OVLTokenTypes.sol";
import "./OVLVestingCalculator.sol";
import "./IOVLBalanceHandler.sol";
import "./IOVLTransferHandler.sol";
import "./IRebasingLiquidityToken.sol";
import "./IDeltaToken.sol";

contract OVLBalanceHandler is OVLVestingCalculator, IOVLBalanceHandler {
    using SafeMath for uint256;

    IDeltaToken private immutable DELTA_TOKEN;
    IERC20 private immutable DELTA_X_WETH_PAIR;
    IOVLTransferHandler private immutable TRANSFER_HANDLER;
    address private constant UNI_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    constructor(IOVLTransferHandler transactionHandler, IERC20 pair) {
        DELTA_TOKEN = IDeltaToken(msg.sender);
        TRANSFER_HANDLER = transactionHandler;
        DELTA_X_WETH_PAIR = pair;
    }

    function handleBalanceCalculations(address account, address sender) external view override returns (uint256) {
        UserInformation memory ui = DELTA_TOKEN.userInformation(account);
        // LP Removal protection
        if(sender == address(DELTA_X_WETH_PAIR) && !DELTA_TOKEN.liquidityRebasingPermitted()) { // This guaranteed liquidity rebasing is not permitted and the sender whos calling is uniswap.
            // If the sender is uniswap and is querying balanceOf, this only happens first inside the burn function
            // This means if the balance of LP tokens here went up
            // We should revert
            // LP tokens supply can raise but it can never get lower with this method, if we detect a raise here we should revert
            // Rest of this code is inside the _transfer function
            require(DELTA_X_WETH_PAIR.balanceOf(address(DELTA_X_WETH_PAIR)) == DELTA_TOKEN.lpTokensInPair(), "DELTAToken: Liquidity removal is forbidden");
            return ui.maxBalance;
        }
        // We trick the uniswap router path revert by returning the whole balance
        // As well as saving gas in noVesting callers like uniswap
        if(ui.noVestingWhitelisted || sender == UNI_ROUTER) {
            return ui.maxBalance;
        } 
        // potentially do i + 1 % epochs
        while (true) {
            uint256 mature = getMatureBalance(DELTA_TOKEN.vestingTransactions(account, ui.mostMatureTxIndex), block.timestamp); 
            ui.maturedBalance = ui.maturedBalance.add(mature);
    
            // We go until we encounter a empty above most mature tx
            if(ui.mostMatureTxIndex == ui.lastInTxIndex) { 
                break;
            }
            ui.mostMatureTxIndex++;
            if(ui.mostMatureTxIndex == QTY_EPOCHS) { ui.mostMatureTxIndex = 0; }
        }

        return ui.maturedBalance;
    }
}