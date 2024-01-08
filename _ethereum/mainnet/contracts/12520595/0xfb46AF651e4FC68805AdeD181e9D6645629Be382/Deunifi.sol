//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Callee.sol";

import "./ILendingPool.sol";
import "./IFlashLoanReceiver.sol";

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

import "./IFeeManager.sol";

uint256 constant MAX_UINT256 = ~uint256(0);


// // TODO Remove 
// import "./console.sol";

interface IDSProxy{

    function execute(address _target, bytes calldata _data)
        external
        payable;

    function setOwner(address owner_)
        external;

}

interface IWeth{
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IPsm{
    function buyGem(address usr, uint256 gemAmt) external;
    function sellGem(address usr, uint256 gemAmt) external;
}

contract Deunifi is IFlashLoanReceiver, Ownable {

    event LockAndDraw(address sender, uint cdp, uint collateral, uint debt);
    event WipeAndFree(address sender, uint cdp, uint collateral, uint debt);

    address public feeManager;

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint8 public constant WIPE_AND_FREE = 1;
    uint8 public constant LOCK_AND_DRAW = 2;

    fallback () external payable {}

    function setFeeManager(address _feeManager) public onlyOwner{
        feeManager = _feeManager;
    }

    struct PayBackParameters {
        address sender;
        address debtToken;
        uint debtToPay;
        address tokenA;
        address tokenB;
        address pairToken;
        uint collateralAmountToFree;
        uint collateralAmountToUseToPayDebt;
        uint debtToCoverWithTokenA;
        uint debtToCoverWithTokenB;
        address[] pathTokenAToDebtToken;
        address[] pathTokenBToDebtToken;
        uint minTokenAToRecive;
        uint minTokenBToRecive;
        uint deadline;
        address dsProxy;
        address dsProxyActions;
        address manager;
        address gemJoin;
        address daiJoin;
        uint cdp;
        address router02;
        address weth;

        // PSM swap parameters
        address tokenToSwapWithPsm;
        address tokenJoinForSwapWithPsm;
        address psm;
        uint256 psmSellGemAmount;
        uint256 expectedDebtTokenFromPsmSellGemOperation;

        address lendingPool;
    }
    
    function lockGemAndDraw(
        address gemToken,
        address dsProxy,
        address dsProxyActions,
        address manager,
        address jug,
        address gemJoin,
        address daiJoin, 
        uint cdp,
        uint collateralToLock,
        uint daiToBorrow,
        bool transferFrom
        ) internal {

        safeIncreaseMaxUint(gemToken, dsProxy, collateralToLock);

        IDSProxy(dsProxy).execute(
            dsProxyActions,
            abi.encodeWithSignature("lockGemAndDraw(address,address,address,address,uint256,uint256,uint256,bool)",
                manager, jug, gemJoin, daiJoin, cdp, collateralToLock, daiToBorrow, transferFrom)
        );

    }

    struct LockAndDrawParameters{

        address sender;

        address debtToken;

        address router02;
        address psm;

        address token0;
        uint256 debtTokenForToken0;
        uint256 token0FromDebtToken;
        address[] pathFromDebtTokenToToken0;
        bool usePsmForToken0;

        address token1;
        uint256 debtTokenForToken1;
        uint256 token1FromDebtToken;
        address[] pathFromDebtTokenToToken1;
        bool usePsmForToken1;

        uint256 token0FromUser;
        uint256 token1FromUser;

        uint256 minCollateralToBuy;
        uint256 collateralFromUser;

        address gemToken;
        address dsProxy;
        address dsProxyActions;
        address manager;
        address jug;
        address gemJoin;
        address daiJoin;
        uint256 cdp;
        uint256 debtTokenToDraw;
        bool transferFrom;

        uint256 deadline;

        address lendingPool;

    }

    function approveDebtToken(uint256 pathFromDebtTokenToToken0Length, uint256 pathFromDebtTokenToToken1Length,
        address debtToken, address router02, address psm,
        uint256 debtTokenForToken0, uint256 debtTokenForToken1,
        bool usePsmForToken0, bool usePsmForToken1) internal {
        
        uint256 amountToApproveRouter02 = 0;
        uint256 amountToApprovePsm = 0;

        if (pathFromDebtTokenToToken0Length > 0){
            if (usePsmForToken0)
                amountToApprovePsm = amountToApprovePsm.add(debtTokenForToken0);
            else
                amountToApproveRouter02 = amountToApproveRouter02.add(debtTokenForToken0);
        }

        if (pathFromDebtTokenToToken1Length > 0){
            if (usePsmForToken1)
                amountToApprovePsm = amountToApprovePsm.add(debtTokenForToken1);
            else
                amountToApproveRouter02 = amountToApproveRouter02.add(debtTokenForToken1);
        }

        if (amountToApproveRouter02 > 0){
            safeIncreaseMaxUint(debtToken, router02, 
                amountToApproveRouter02);
        }

        if (amountToApprovePsm > 0){
            safeIncreaseMaxUint(debtToken, psm, 
                amountToApprovePsm);
        }

    }

    function lockAndDrawOperation(bytes memory params) internal{

        ( LockAndDrawParameters memory parameters) = abi.decode(params, (LockAndDrawParameters));
        
        approveDebtToken(parameters.pathFromDebtTokenToToken0.length, parameters.pathFromDebtTokenToToken1.length,
            parameters.debtToken, parameters.router02, parameters.psm,
            parameters.debtTokenForToken0, parameters.debtTokenForToken1,
            parameters.usePsmForToken0, parameters.usePsmForToken1);

        uint token0FromDebtToken = 0;
        uint token1FromDebtToken = 0;
        uint boughtCollateral;

        // Swap debt token for gems or one of tokens that compose gems.
        if (parameters.debtTokenForToken0 > 0){

            if (parameters.debtToken == parameters.token0){

                token0FromDebtToken = parameters.debtTokenForToken0;

            } else {

                if (parameters.usePsmForToken0){

                    token0FromDebtToken = parameters.token0FromDebtToken;
                    
                    IPsm(parameters.psm).buyGem(address(this), token0FromDebtToken);

                }else{

                    token0FromDebtToken = IUniswapV2Router02(parameters.router02).swapExactTokensForTokens(
                        parameters.debtTokenForToken0, // exact amount for token 'from'
                        0, // min amount to recive for token 'to'
                        parameters.pathFromDebtTokenToToken0, // path of swap
                        address(this), // reciver
                        parameters.deadline
                        )[parameters.pathFromDebtTokenToToken0.length-1];

                }

            }

            boughtCollateral = token0FromDebtToken;

        }

        // Swap debt token the other token that compose gems.
        if (parameters.debtTokenForToken1 > 0){

            if (parameters.debtToken == parameters.token1){

                token1FromDebtToken = parameters.debtTokenForToken1;

            } else {

                if (parameters.usePsmForToken1){

                    token1FromDebtToken = parameters.token1FromDebtToken;
                    
                    IPsm(parameters.psm).buyGem(address(this), token1FromDebtToken);

                }else{

                    token1FromDebtToken = IUniswapV2Router02(parameters.router02).swapExactTokensForTokens(
                        parameters.debtTokenForToken1, // exact amount for token 'from'
                        0, // min amount to recive for token 'to'
                        parameters.pathFromDebtTokenToToken1, // path of swap
                        address(this), // reciver
                        parameters.deadline
                        )[parameters.pathFromDebtTokenToToken1.length-1];

                }

            }

        }

        if (parameters.token1FromUser.add(token1FromDebtToken) > 0){

            safeIncreaseMaxUint(parameters.token0, parameters.router02,
                parameters.token0FromUser.add(token0FromDebtToken));
            safeIncreaseMaxUint(parameters.token1, parameters.router02,
                parameters.token1FromUser.add(token1FromDebtToken));

            ( uint token0Used, uint token1Used, uint addedLiquidity) = IUniswapV2Router02(parameters.router02).addLiquidity(
                parameters.token0,
                parameters.token1,
                parameters.token0FromUser.add(token0FromDebtToken),
                parameters.token1FromUser.add(token1FromDebtToken),
                0,
                0,
                address(this), // reciver
                parameters.deadline
            );

            boughtCollateral = addedLiquidity;

            // Remaining tokens are returned to user.

            if (parameters.token0FromUser.add(token0FromDebtToken).sub(token0Used) > 0)
                IERC20(parameters.token0).safeTransfer(
                    parameters.sender,
                    parameters.token0FromUser.add(token0FromDebtToken).sub(token0Used));

            if (parameters.token1FromUser.add(token1FromDebtToken).sub(token1Used) > 0)
                IERC20(parameters.token1).safeTransfer(
                    parameters.sender,
                    parameters.token1FromUser.add(token1FromDebtToken).sub(token1Used));

        }

        require(boughtCollateral >= parameters.minCollateralToBuy, "Deunifi: Bought collateral lower than expected collateral to buy.");

        uint collateralToLock = parameters.collateralFromUser.add(boughtCollateral);

        lockGemAndDraw(
            parameters.gemToken,
            parameters.dsProxy,
            parameters.dsProxyActions,
            parameters.manager, 
            parameters.jug,
            parameters.gemJoin,
            parameters.daiJoin, 
            parameters.cdp,
            collateralToLock,
            parameters.debtTokenToDraw,
            parameters.transferFrom
        );

        // Fee Service Payment
        safeIncreaseMaxUint(parameters.debtToken, feeManager, 
            parameters.debtTokenToDraw); // We are passing an amount higher so it is not necessary to calculate the fee.

        if (feeManager!=address(0))
            // TODO parameters.sender
            IFeeManager(feeManager).collectFee(parameters.sender, parameters.debtToken, parameters.debtTokenToDraw);

        // Approve lending pool to collect flash loan + fees.
        safeIncreaseMaxUint(parameters.debtToken, parameters.lendingPool,
            parameters.debtTokenToDraw); // We are passing an amount higher so it is not necessary to calculate the fee.

        emit LockAndDraw(parameters.sender, parameters.cdp, collateralToLock, parameters.debtTokenToDraw);
        
    }

    function paybackDebt(PayBackParameters memory parameters) internal
        returns (uint freeTokenA, uint freeTokenB, uint freePairToken){

        parameters.debtToPay;

        wipeAndFreeGem(
            parameters.dsProxy,
            parameters.dsProxyActions,
            parameters.manager,
            parameters.gemJoin,
            parameters.daiJoin,
            parameters.cdp,
            parameters.collateralAmountToFree,
            parameters.debtToPay,
            parameters.debtToken
        );

        (uint remainingTokenA, uint remainingTokenB) = swapCollateralForTokens(
            SwapCollateralForTokensParameters(
                parameters.router02,
                parameters.tokenA,
                parameters.tokenB, // Optional in case of Uniswap Pair Collateral
                parameters.pairToken,
                parameters.collateralAmountToUseToPayDebt, // Amount of tokenA or liquidity to remove 
                                    // of pair(tokenA, tokenB)
                parameters.minTokenAToRecive, // Min amount remaining after swap tokenA for debtToken
                            // (this has more sense when we are working with pairs)
                parameters.minTokenBToRecive, // Optional in case of Uniswap Pair Collateral
                parameters.deadline,
                parameters.debtToCoverWithTokenA, // amount in debt token
                parameters.debtToCoverWithTokenB, // Optional in case of Uniswap Pair Collateral
                parameters.pathTokenAToDebtToken, // Path to perform the swap.
                parameters.pathTokenBToDebtToken, // Optional in case of Uniswap Pair Collateral
                parameters.tokenToSwapWithPsm,
                parameters.tokenJoinForSwapWithPsm,
                parameters.psm,
                parameters.psmSellGemAmount,
                parameters.expectedDebtTokenFromPsmSellGemOperation
            )
        );

        uint pairRemaining = 0;

        if (parameters.pairToken != address(0)){
            pairRemaining = parameters.collateralAmountToFree
                .sub(parameters.collateralAmountToUseToPayDebt);
        }

        return (remainingTokenA, remainingTokenB, pairRemaining);

    }

    function safeIncreaseMaxUint(address token, address spender, uint amount) internal {
        if (IERC20(token).allowance(address(this), spender) < amount){
            IERC20(token).safeApprove(spender, 0);
            IERC20(token).safeApprove(spender, MAX_UINT256);
        } 
    }

    /**
    Preconditions:
    - this should have enough `wadD` DAI.
    - DAI.allowance(this, daiJoin) >= wadD
    - All addresses should correspond with the expected contracts.
    */
    function wipeAndFreeGem(
        address dsProxy,
        address dsProxyActions,
        address manager,
        address gemJoin,
        address daiJoin,
        uint256 cdp,
        uint256 wadC,
        uint256 wadD,
        address daiToken
    ) internal {

        safeIncreaseMaxUint(daiToken, dsProxy, wadD);

        IDSProxy(dsProxy).execute(
            dsProxyActions,
            abi.encodeWithSignature("wipeAndFreeGem(address,address,address,uint256,uint256,uint256)",
                manager, gemJoin, daiJoin, cdp, wadC, wadD)
        );

    }
    
    struct SwapCollateralForTokensParameters{
        address router02; // Uniswap V2 Router
        address tokenA; // Token to be swap for debtToken
        address tokenB; // Optional in case of Uniswap Pair Collateral
        address pairToken;
        uint amountToUseToPayDebt; // Amount of tokenA or liquidity to remove 
                                   // of pair(tokenA, tokenB)
        uint amountAMin; // Min amount remaining after swap tokenA for debtToken
                         // (this has more sense when we are working with pairs)
        uint amountBMin; // Optional in case of Uniswap Pair Collateral
        uint deadline;
        uint debtToCoverWithTokenA; // amount in debt token
        uint debtToCoverWithTokenB; // Optional in case of Uniswap Pair Collateral
        address[] pathTokenAToDebtToken; // Path to perform the swap.
        address[] pathTokenBToDebtToken; // Optional in case of Uniswap Pair Collateral

        address tokenToSwapWithPsm;
        address tokenJoinForSwapWithPsm;
        address psm;
        uint256 psmSellGemAmount;
        uint256 expectedDebtTokenFromPsmSellGemOperation;
    }

    /**
    Preconditions:
    - this should have enough amountToUseToPayDebt, 
        tokenA for debtToCoverWithTokenA and 
        tokenb for debtToCoverWithTokenB and 
    - pair(tokenA, tokenB).allowance(this, router02) >= amountToUseToPayDebt.
    - tokenA.allowance(this, router02) >= (debtToCoverWithTokenA in token A)
    - tokenB.allowance(this, router02) >= (debtToCoverWithTokenB in token B)
    - All addresses should correspond with the expected contracts.
    - pair(tokenA, tokenB) should be a valid Uniswap V2 pair.
    */
    function swapCollateralForTokens(
        SwapCollateralForTokensParameters memory parameters
    ) internal returns (uint remainingTokenA, uint remainingTokenB) {
        
        uint amountA = 0;
        uint amountB = 0;
        uint amountACoveringDebt = 0;
        uint amountBCoveringDebt = 0;

        if (parameters.tokenB!=address(0)){

            safeIncreaseMaxUint(parameters.pairToken, parameters.router02, parameters.amountToUseToPayDebt);

            (amountA, amountB) = IUniswapV2Router02(parameters.router02).removeLiquidity(      
                parameters.tokenA,
                parameters.tokenB,
                parameters.amountToUseToPayDebt,
                0, // Min amount of token A to recive
                0, // Min amount of token B to recive
                address(this),
                parameters.deadline
            );

            if (parameters.debtToCoverWithTokenB > 0){
                
                if (parameters.pathTokenBToDebtToken.length == 0){

                    amountBCoveringDebt = parameters.debtToCoverWithTokenB;

                } else {

                    if (parameters.tokenToSwapWithPsm == parameters.tokenB){

                        safeIncreaseMaxUint(parameters.tokenB, parameters.tokenJoinForSwapWithPsm, 
                            parameters.psmSellGemAmount);

                        IPsm(parameters.psm).sellGem(address(this), parameters.psmSellGemAmount);

                        amountBCoveringDebt = parameters.psmSellGemAmount;

                    }else{

                        // IERC20(parameters.tokenB).safeIncreaseAllowance(parameters.router02, amountB.sub(parameters.amountBMin));
                        safeIncreaseMaxUint(parameters.tokenB, parameters.router02, 
                            amountB.mul(2));  // We are passing an amount higher because we do not know how much is going to be spent.
                        
                        amountBCoveringDebt = IUniswapV2Router02(parameters.router02).swapTokensForExactTokens(
                            parameters.debtToCoverWithTokenB,
                            amountB.sub(parameters.amountBMin), // amountInMax (Here we validate amountBMin)
                            parameters.pathTokenBToDebtToken,
                            address(this),
                            parameters.deadline
                        )[0];

                    }

                }

            }

        }else{

            // In case we are not dealing with a pair, we need 
            amountA = parameters.amountToUseToPayDebt;

        }

        if (parameters.debtToCoverWithTokenA > 0){

                if (parameters.pathTokenAToDebtToken.length == 0){

                    amountACoveringDebt = parameters.debtToCoverWithTokenA;

                } else {

                    if (parameters.tokenToSwapWithPsm == parameters.tokenA){

                        safeIncreaseMaxUint(parameters.tokenA, parameters.tokenJoinForSwapWithPsm, 
                            parameters.psmSellGemAmount);

                        IPsm(parameters.psm).sellGem(address(this), parameters.psmSellGemAmount);

                        amountACoveringDebt = parameters.psmSellGemAmount;

                    }else{

                        // IERC20(parameters.tokenA).safeIncreaseAllowance(parameters.router02, amountA.sub(parameters.amountAMin));
                        safeIncreaseMaxUint(parameters.tokenA, parameters.router02,
                            amountA.mul(2)); // We are passing an amount higher because we do not know how much is going to be spent.

                        amountACoveringDebt = IUniswapV2Router02(parameters.router02).swapTokensForExactTokens(
                            parameters.debtToCoverWithTokenA,
                            amountA.sub(parameters.amountAMin), // amountInMax (Here we validate amountAMin)
                            parameters.pathTokenAToDebtToken,
                            address(this),
                            parameters.deadline
                        )[0];

                    }

                }

        }

        return (
            amountA.sub(amountACoveringDebt),
            amountB.sub(amountBCoveringDebt)
            );

    }

    function wipeAndFreeOperation(bytes memory params) internal{

        ( PayBackParameters memory decodedData ) = abi.decode(params, (PayBackParameters));

        (uint remainingTokenA, uint remainingTokenB, uint pairRemaining) = paybackDebt(decodedData);

        require(remainingTokenA >= decodedData.minTokenAToRecive, "Deunifi: Remaining token lower than expected.");
        require(remainingTokenB >= decodedData.minTokenBToRecive, "Deunifi: Remaining token lower than expected.");

        // Fee Service Payment
        safeIncreaseMaxUint(decodedData.debtToken, feeManager, 
            decodedData.debtToPay); // We are passing an amount higher so it is not necessary to calculate the fee.

        if (feeManager!=address(0))
            IFeeManager(feeManager).collectFee(decodedData.sender, decodedData.debtToken, decodedData.debtToPay);

        // Conversion from WETH to ETH when needed.
        if (decodedData.weth != address(0)){

            uint wethBalance = 0;

            if (decodedData.tokenA == decodedData.weth){
                wethBalance = remainingTokenA;
                remainingTokenA = 0;
            }

            if (decodedData.tokenB == decodedData.weth){
                wethBalance = remainingTokenB;
                remainingTokenB = 0;
            }

            if (wethBalance>0){
                IWeth(decodedData.weth).withdraw(wethBalance);
                decodedData.sender.call{value: wethBalance}("");
            }
        }

        if (remainingTokenA > 0 || decodedData.minTokenAToRecive > 0){
            IERC20(decodedData.tokenA).safeTransfer(decodedData.sender, remainingTokenA);
        }

        if (remainingTokenB > 0 || decodedData.minTokenBToRecive > 0){
            IERC20(decodedData.tokenB).safeTransfer(decodedData.sender, remainingTokenB);
        }

        if (pairRemaining > 0){
            // We do not verify because pairRemaining because the contract should have only
            // the exact amount to transfer.
            IERC20(decodedData.pairToken).safeTransfer(decodedData.sender, pairRemaining);
        }

        safeIncreaseMaxUint(decodedData.debtToken, decodedData.lendingPool,
            decodedData.debtToPay.mul(2)); // We are passing an amount higher so it is not necessary to calculate the fee.

        emit WipeAndFree(decodedData.sender, decodedData.cdp, decodedData.collateralAmountToFree, decodedData.debtToPay);

    }

    struct Operation{
        uint8 operation;
        bytes data;
    }

    /**
        This function is called after your contract has received the flash loan amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {

        ( Operation memory operation ) = abi.decode(params, (Operation));

        if (operation.operation == WIPE_AND_FREE)
            wipeAndFreeOperation(operation.data);
        else if(operation.operation == LOCK_AND_DRAW)
            lockAndDrawOperation(operation.data);
        else
            revert('Easy Vault: Invalid operation.');

        return true;
    }

    /**
    Executed as DSProxy.
     */
    function flashLoanFromDSProxy(
        address owner, // Owner of DSProxy calling this function.
        address target, // Target contract that will resolve the flash loan.
        address[] memory ownerTokens, // owner tokens to transfer to target
        uint[] memory ownerAmounts, // owner token amounts to transfer to target
        address lendingPool,
        address[] memory loanTokens,
        uint[] memory loanAmounts,
        uint[] memory modes,
        bytes memory data,
        address weth // When has to use or recive ETH, else should be address(0)
        ) public payable{

        if (msg.value > 0){
            IWeth(weth).deposit{value: msg.value}();
            IERC20(weth).safeTransfer(
                target, msg.value
            );
        }

        IDSProxy(address(this)).setOwner(target);

        for (uint i=0; i<ownerTokens.length; i=i.add(1)){
            IERC20(ownerTokens[i]).safeTransferFrom(
                owner, target, ownerAmounts[i]
            );
        }

        ILendingPool(lendingPool).flashLoan(
            target,
            loanTokens,
            loanAmounts,
            modes, // modes: 0 = no debt, 1 = stable, 2 = variable
            target, // onBehalfOf
            data,
            0 // referralCode
        );

        IDSProxy(address(this)).setOwner(owner);
        
    }

}
