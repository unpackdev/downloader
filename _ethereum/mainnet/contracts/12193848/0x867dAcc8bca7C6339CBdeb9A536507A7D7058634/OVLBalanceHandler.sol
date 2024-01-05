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

    IDeltaToken public constant DELTA_TOKEN = IDeltaToken(0x9EA3b5b4EC044b70375236A281986106457b20EF);
    IERC20 public constant SUSHI_DELTA_X_WETH_PAIR = IERC20(0x1498bd576454159Bb81B5Ce532692a8752D163e8);
    IOVLTransferHandler public immutable TRANSFER_HANDLER;
    address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;


    constructor(IOVLTransferHandler transactionHandler, IERC20) {
        TRANSFER_HANDLER = transactionHandler;
    }

    function handleBalanceCalculations(address account, address sender) external view override returns (uint256) {
        UserInformation memory ui = DELTA_TOKEN.userInformation(account);
        // LP Removal protection
        if(sender == address(SUSHI_DELTA_X_WETH_PAIR) && !DELTA_TOKEN.liquidityRebasingPermitted()) { // This guaranteed liquidity rebasing is not permitted and the sender whos calling is uniswap.
            // If the sender is uniswap and is querying balanceOf, this only happens first inside the burn function
            // This means if the balance of LP tokens here went up
            // We should revert
            // LP tokens supply can raise but it can never get lower with this method, if we detect a raise here we should revert
            // Rest of this code is inside the _transfer function
            require(SUSHI_DELTA_X_WETH_PAIR.balanceOf(address(SUSHI_DELTA_X_WETH_PAIR)) == DELTA_TOKEN.lpTokensInPair(), "DELTAToken: Liquidity removal is forbidden");
            return ui.maxBalance;
        }
        // We trick the uniswap router path revert by returning the whole balance
        // As well as saving gas in noVesting callers like uniswap
        if(ui.noVestingWhitelisted || sender == SUSHI_ROUTER) {
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