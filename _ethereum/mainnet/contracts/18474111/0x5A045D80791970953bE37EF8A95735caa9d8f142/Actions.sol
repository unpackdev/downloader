// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;
import "./RightsManager.sol";
import "./SmartPoolManager.sol";
import "./DesynSafeMath.sol";

import "./SafeERC20.sol";
import "./IWETH.sol";
import "./DesynReentrancyGuard.sol";

abstract contract IAggregator {
    enum SwapType {
        UNISWAPV2,
        UNISWAPV3,
        ONEINCH,
        CURVE
    }

    struct SwapInfoBase {
        address aggregator; // the swap router to use
        address rebalanceAdapter;
        SwapType swapType;
    }

    struct SwapData {
        uint256 quantity;
        bytes data; // v3: (uint,uint256[]) v2: (uint256,address[])
    }

    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external virtual;

    function uniswapV3Swap(uint256, uint256, uint256[] calldata) external virtual;
}

abstract contract DesynOwnable {
    function setController(address controller) external virtual;
    function setManagersInfo(address[] memory _owners, uint[] memory _ownerPercentage) external virtual;
}

abstract contract AbstractPool is IERC20, DesynOwnable {
    function setPublicSwap(bool public_) external virtual;

    function joinPool(
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        address kol,
        address user
    ) external virtual;

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut, address user) external virtual;
}

abstract contract LiquidityPoolActions is AbstractPool {
    function finalize() external virtual;

    function bind(
        address token,
        uint balance,
        uint denorm
    ) external virtual;

    function rebind(
        address token,
        uint balance,
        uint denorm
    ) external virtual;

    function unbind(address token) external virtual;

    function isBound(address t) external view virtual returns (bool);

    function getCurrentTokens() external view virtual returns (address[] memory);

    function getFinalTokens() external view virtual returns (address[] memory);

    function getBalance(address token) external view virtual returns (uint);
}

abstract contract FactoryActions {
    function newLiquidityPool() external virtual returns (LiquidityPoolActions);
    function getModuleStatus(address etf, address module) external view virtual returns (bool);
    function isTokenWhitelistedForVerify(address token) external view virtual returns (bool);
}

abstract contract RebalaceAdapter {
    enum SwapType {
        UNISWAPV2,
        UNISWAPV3,
        ONEINCH
    }

    struct RebalanceInfo {
        address etf; // etf address
        address token0;
        address token1;
        address aggregator; // the swap router to use
        SwapType swapType;
        uint256 quantity;
        bytes data; // v3: (uint,uint256[]) v2: (uint256,address[])
    }
    function rebalance(RebalanceInfo calldata rebalanceInfo) external virtual;
    function approve(address etf, address token, address spender, uint256 amount) external virtual;
    function isRouterApproved(address router) external virtual returns (bool);
}

abstract contract IConfigurableRightsPool is AbstractPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        SmartPoolManager.Etypes etype;
    }

    struct CrpParams {
        uint initialSupply;
        uint collectPeriod;
        SmartPoolManager.Period period;
    }

    function createPool(
        address creator,
        uint initialSupply,
        uint collectPeriod,
        SmartPoolManager.Period period,
        SmartPoolManager.PoolTokenRange memory tokenRange
    ) external virtual;

    function createPool(uint initialSupply) external virtual;

    function setCap(uint newCap) external virtual;

    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    ) external virtual;

    function applyAddToken() external virtual;

    function whitelistLiquidityProvider(address provider) external virtual;

    function removeWhitelistedLiquidityProvider(address provider) external virtual;

    function bPool() external view virtual returns (LiquidityPoolActions);

    function addTokenToWhitelist(uint[] memory sort, address[] memory token) external virtual;
    function claimManagerFee() external virtual;

    function etype() external virtual returns(SmartPoolManager.Etypes);

    function vaultAddress() external virtual view returns(address);

    function snapshotBeginAssets() external virtual;

    function snapshotEndAssets() external virtual;

    function etfStatus() external virtual returns(SmartPoolManager.Status memory);
}

abstract contract ICRPFactory {
    function newCrp(
        address factoryAddress,
        IConfigurableRightsPool.PoolParams calldata params,
        RightsManager.Rights calldata rights,
        SmartPoolManager.KolPoolParams calldata kolPoolParams,
        address[] memory owners,
        uint[] memory ownerPercentage
    ) external virtual returns (IConfigurableRightsPool);
}

abstract contract IVault {
    function userVault() external virtual returns(address);
}

abstract contract IUserVault {
    function kolClaim(address pool) external virtual;

    function managerClaim(address pool) external virtual;

    function getManagerClaimBool(address pool) external view virtual returns(bool);
}

interface ICurve {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function coins(uint i) external view returns(address);    
}

/********************************** WARNING **********************************/
//                                                                           //
// This contract is only meant to be used in conjunction with ds-proxy.      //
// Calling this contract directly will lead to loss of funds.                //
//                                                                           //
/********************************** WARNING **********************************/

contract Actions is DesynReentrancyGuard {
    using SafeERC20 for IERC20;
    using DesynSafeMath for uint256;
    
    IERC20 public constant STBT = IERC20(0x530824DA86689C9C17CdC2871Ff29B058345b44a);
    address public constant FACTORY = 0x01a38B39BEddCD6bFEedBA14057E053cBF529cD2;
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event SmartJoinPool(address caller, address token, uint amount, address shareReturn, uint amountReturn);
    event SmartExitPool(address caller, address share, uint shareAmount, address tokenReturn, uint amountReturn);
    
    // --- Pool Creation ---

    function create(
        FactoryActions factory,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata weights,
        bool finalize
    ) external returns (LiquidityPoolActions pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == weights.length, "ERR_LENGTH_MISMATCH");

        pool = factory.newLiquidityPool();

        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransferFrom(msg.sender, address(this), balances[i]);
            token.safeApprove(address(pool), 0);
            token.safeApprove(address(pool), balances[i]);

            pool.bind(tokens[i], balances[i], weights[i]);
        }

        if (finalize) {
            pool.finalize();
            require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        } else {
            pool.setPublicSwap(true);
        }
    }

    function createSmartPool(
        ICRPFactory factory,
        FactoryActions coreFactory,
        IConfigurableRightsPool.PoolParams calldata poolParams,
        IConfigurableRightsPool.CrpParams calldata crpParams,
        RightsManager.Rights calldata rights,
        SmartPoolManager.KolPoolParams calldata kolPoolParams,
        address[] memory owners,
        uint[] memory ownerPercentage,
        SmartPoolManager.PoolTokenRange memory tokenRange
    ) external returns (IConfigurableRightsPool crp) {
        require(poolParams.constituentTokens.length == poolParams.tokenBalances.length, "ERR_LENGTH_MISMATCH");
        require(poolParams.constituentTokens.length == poolParams.tokenWeights.length, "ERR_LENGTH_MISMATCH");

        crp = factory.newCrp(address(coreFactory), poolParams, rights, kolPoolParams, owners, ownerPercentage);

        for (uint i = 0; i < poolParams.constituentTokens.length; i++) {
            IERC20 token = IERC20(poolParams.constituentTokens[i]);
            token.safeTransferFrom(msg.sender, address(this), poolParams.tokenBalances[i]);
            token.safeApprove(address(crp), 0);
            token.safeApprove(address(crp), poolParams.tokenBalances[i]);
        }

        crp.createPool(msg.sender,crpParams.initialSupply, crpParams.collectPeriod, crpParams.period, tokenRange);
        require(crp.transfer(msg.sender, crpParams.initialSupply), "ERR_TRANSFER_FAILED");
        crp.setController(msg.sender);
        // DSProxy instance keeps pool ownership to enable management
    }

    // --- Joins ---

    function joinPool(
        LiquidityPoolActions pool,
        uint poolAmountOut,   
        uint[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = pool.getFinalTokens();
        _join(pool, tokens, poolAmountOut, maxAmountsIn, msg.sender);
    }

    function autoExitSmartPool(
        IConfigurableRightsPool pool,
        uint poolAmountIn,
        uint[] memory minAmountsOut,
        uint minSwapReturn,
        address handleToken,
        IAggregator.SwapInfoBase calldata swapBase,
        IAggregator.SwapData[] memory swapDatas) external payable lock {
        address[] memory tokens = pool.bPool().getCurrentTokens();
        uint len = swapDatas.length;
        require(FactoryActions(FACTORY).isTokenWhitelistedForVerify(handleToken),"ERR_TOKEN_NOT_WHITELISTED");
        require(tokens.length == swapDatas.length,"ERR_TOKENLENGTH_MISMATCH");
        require(tokens.length == minAmountsOut.length,"ERR_TOKENLENGTH_MISMATCH");

        IERC20 receiveToken = IERC20(handleToken);
        if (handleToken == NATIVE_TOKEN) {
            receiveToken = IERC20(WETH);
        }
        uint preReceiveAmount = receiveToken.balanceOf(address(this));
        uint[] memory initialAmounts = new uint[](len);
        for(uint i = 0; i < len; i++){
            initialAmounts[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        _exit(pool, poolAmountIn, minAmountsOut, tokens, true);

        for(uint j = 0; j < len; j++) {
            IAggregator.SwapData memory swapData = swapDatas[j];
            IERC20 swapToken = IERC20(tokens[j]);
            if(tokens[j] != address(receiveToken)){
                swapData.quantity = SafeMath.sub(swapToken.balanceOf(address(this)), initialAmounts[j]);
                swapToken.safeApprove(swapBase.aggregator, 0);
                swapToken.safeApprove(swapBase.aggregator, swapData.quantity);
                _makeSwap(swapBase, swapData, receiveToken);
            }
        }
        uint receiveAmount = SafeMath.sub(receiveToken.balanceOf(address(this)), preReceiveAmount);
        require(minSwapReturn <= receiveAmount,"ERR_RECEIVE_AMOUNT_TO_SMALL");
        if (handleToken == NATIVE_TOKEN) {
            IWETH(WETH).withdraw(receiveAmount);
            msg.sender.transfer(receiveAmount);
        } else {
            receiveToken.safeTransfer(msg.sender, receiveAmount);
        }

        emit SmartExitPool(msg.sender, address(pool) ,poolAmountIn, handleToken, receiveAmount);
    }

    function joinSmartPool(
        IConfigurableRightsPool pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        address kol
    ) external {
        address[] memory tokens = pool.bPool().getCurrentTokens();
        _join(pool, tokens, poolAmountOut, maxAmountsIn, kol);
    }

    struct JoinVar {
        uint actualShareAmountOut;
        uint issueFee;
        uint totalPoolShares;
        LiquidityPoolActions bPool;
    }

    function autoJoinSmartPool(
        IConfigurableRightsPool pool,
        address kol,
        uint issueAmount,
        uint minPoolAmountOut,
        address handleToken,
        IAggregator.SwapInfoBase calldata swapBase,
        IAggregator.SwapData[] memory swapDatas
    ) external payable lock {
        require(FactoryActions(FACTORY).isTokenWhitelistedForVerify(handleToken), "ERR_TOKEN_NOT_WHITELISTED");
        address[] memory poolTokens = pool.bPool().getCurrentTokens();
        require(poolTokens.length == swapDatas.length,"ERR_TOKENLENGTH_MISMATCH");
        uint[] memory maxAmountsIn = new uint[](poolTokens.length);
        address user = msg.sender;

        // Transfer ETH into the contract and authorize the aggregator to operate
        IERC20 issueToken;
        if (handleToken == NATIVE_TOKEN) {
            require(msg.value > 0 && msg.value == issueAmount, 'ERROR_ETH');
            IWETH(WETH).deposit{value: msg.value}();

            issueToken = IERC20(WETH);
        } else {
            issueToken = IERC20(handleToken);
            issueToken.safeTransferFrom(user, address(this), issueAmount);
        }
   
        issueToken.safeApprove(swapBase.aggregator, 0);
        issueToken.safeApprove(swapBase.aggregator, issueAmount);

        JoinVar memory joinVar = JoinVar({
            actualShareAmountOut: type(uint).max,
            issueFee:pool.etfStatus().issueFee,
            totalPoolShares:pool.totalSupply(),
            bPool:pool.bPool()
        });

        // Perform a swap and authorize the pool call
        for (uint i; i < poolTokens.length; i++) {
            IAggregator.SwapData memory swapData = swapDatas[i];
        
            poolTokens[i] == address(issueToken)
                ? maxAmountsIn[i] = swapData.quantity
                : maxAmountsIn[i] = _makeSwap(swapBase, swapData, IERC20(poolTokens[i]));

            uint shareAmountOutPerToken = _calculateShare(joinVar.bPool,joinVar.totalPoolShares,joinVar.issueFee, poolTokens[i], maxAmountsIn[i]);
            if(shareAmountOutPerToken < joinVar.actualShareAmountOut) joinVar.actualShareAmountOut = shareAmountOutPerToken;
        
            IERC20(poolTokens[i]).safeApprove(address(pool), 0);
            IERC20(poolTokens[i]).safeApprove(address(pool), maxAmountsIn[i]);
        }

        // Adding Tokens to a Pool
        require(minPoolAmountOut <= joinVar.actualShareAmountOut,"ERR_SHARE_AMOUNT_TO_SMALL");
        pool.joinPool(joinVar.actualShareAmountOut, maxAmountsIn, kol, user); 

        // Return excess funds to users
        for (uint i; i < poolTokens.length; i++) {
            IERC20 token = IERC20(poolTokens[i]);
            if (token.balanceOf(address(this)) > 0 && token != STBT) token.safeTransfer(user, token.balanceOf(address(this)));
        }

        issueToken.safeTransfer(user, issueToken.balanceOf(address(this)));
        require(pool.transfer(user, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        
        emit SmartJoinPool(msg.sender, handleToken, issueAmount, address(pool), joinVar.actualShareAmountOut);    
    }

    function exitPool(
        IConfigurableRightsPool pool,
        uint poolAmountIn,
        uint[] memory minAmountsOut
    ) external {
        address[] memory tokens = pool.bPool().getCurrentTokens();
        _exit(pool, poolAmountIn, minAmountsOut, tokens, false);
    }

    // --- Pool management (common) ---
    function setPublicSwap(AbstractPool pool, bool publicSwap) external {
        pool.setPublicSwap(publicSwap);
    }

    function setController(AbstractPool pool, address newController) external {
        _beforeOwnerChange(address(pool));
        pool.setController(newController);
    }

    function setManagersInfo(AbstractPool pool ,address[] memory _owners, uint[] memory _ownerPercentage) public {
        _beforeOwnerChange(address(pool));
        pool.setManagersInfo(_owners, _ownerPercentage);
    }

    function _beforeOwnerChange(address pool) internal {
        claimManagementFee(IConfigurableRightsPool(pool));
        _claimManagersReward(pool);
    }

    function snapshotBeginAssets(IConfigurableRightsPool pool) external virtual {
        pool.snapshotBeginAssets();
    }

    function snapshotEndAssets(IConfigurableRightsPool pool) external virtual {
        pool.snapshotEndAssets();
    }

    function approveUnderlying(RebalaceAdapter rebalanceAdapter, address etf, address token, address spender, uint amount) external {
        rebalanceAdapter.approve(etf, token, spender, amount);
    }

    function rebalance(RebalaceAdapter rebalanceAdapter, RebalaceAdapter.RebalanceInfo calldata rebalanceInfo) external {
        rebalanceAdapter.rebalance(rebalanceInfo);
    }

    // --- Private pool management ---

    function finalize(LiquidityPoolActions pool) external {
        pool.finalize();
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    // --- Smart pool management ---
    function setCap(IConfigurableRightsPool crp, uint newCap) external {
        crp.setCap(newCap);
    }

    function whitelistLiquidityProvider(IConfigurableRightsPool crp, address provider) external {
        crp.whitelistLiquidityProvider(provider);
    }

    function removeWhitelistedLiquidityProvider(IConfigurableRightsPool crp, address provider) external {
        crp.removeWhitelistedLiquidityProvider(provider);
    }

    function addTokenToWhitelist(IConfigurableRightsPool crp, uint[] memory sort, address[] memory token) public {
        crp.addTokenToWhitelist(sort, token);
    }

    function claimManagementFee(IConfigurableRightsPool crp) public {
         crp.claimManagerFee();
    }
    // --- Internals ---

    function _safeApprove(
        IERC20 token,
        address spender,
        uint amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.approve(spender, 0);
        }
        token.approve(spender, amount);
    }

    function _join(
        AbstractPool pool,
        address[] memory tokens,
        uint poolAmountOut,
        uint[] memory maxAmountsIn,
        address kol
    ) internal {
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransferFrom(msg.sender, address(this), maxAmountsIn[i]);

            token.safeApprove(address(pool), 0);
            token.safeApprove(address(pool), maxAmountsIn[i]);
        }

        pool.joinPool(poolAmountOut, maxAmountsIn, kol, msg.sender);

        for (uint i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                token.safeTransfer(msg.sender, token.balanceOf(address(this)));
            }
        }
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function _exit(
        IConfigurableRightsPool pool,
        uint poolAmountIn,
        uint[] memory minAmountsOut,
        address[] memory tokens,
        bool isSmartMode
    ) internal {
        uint shareToBurn = poolAmountIn;

        if (pool.etype() == SmartPoolManager.Etypes.CLOSED) {
            shareToBurn = pool.balanceOf(msg.sender);
        }

        require(pool.transferFrom(msg.sender, address(this), shareToBurn), "ERR_TRANSFER_FAILED");
        // _safeApprove(pool, address(pool), shareToBurn);
        pool.exitPool(shareToBurn, minAmountsOut, msg.sender);
        if(!isSmartMode){
            for (uint i = 0; i < tokens.length; i++) {
                IERC20 token = IERC20(tokens[i]);
                if (token.balanceOf(address(this)) > 0) {
                    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
                }
            }
        }
    }

    function claimKolReward(address pool) public {
        address uservault = _getUserVault(pool);
        IUserVault(uservault).kolClaim(pool);
    }

    function claimManagersReward(address vault_,address pool) external {
        IUserVault(vault_).managerClaim(pool);
    }

    function _claimManagersReward(address pool) internal {
        address vault = _getVault(pool);
        address uservault = _getUserVault(pool);

        bool vaultCanClaim = IUserVault(vault).getManagerClaimBool(pool);
        bool uservaultCanClaim = IUserVault(uservault).getManagerClaimBool(pool);
        SmartPoolManager.Etypes type_ = IConfigurableRightsPool(pool).etype();

        if(type_ == SmartPoolManager.Etypes.OPENED && vaultCanClaim) IUserVault(vault).managerClaim(pool);
        if(type_ == SmartPoolManager.Etypes.CLOSED && uservaultCanClaim) IUserVault(uservault).managerClaim(pool);
    }
    
    function _makeSwap(IAggregator.SwapInfoBase calldata swapBase, IAggregator.SwapData memory swapData, IERC20 swapAcceptToken) internal returns (uint256 postSwap) {
        require(FactoryActions(FACTORY).getModuleStatus(address(0), swapBase.rebalanceAdapter), 'MODULE_ILLEGAL');
        require(RebalaceAdapter(swapBase.rebalanceAdapter).isRouterApproved(swapBase.aggregator), 'ROUTER_ILLEGAL');

        uint preSwap = swapAcceptToken.balanceOf(address(this));

        if (swapBase.swapType == IAggregator.SwapType.UNISWAPV3) {
            (uint256 minReturn, uint256[] memory pools) = abi.decode(swapData.data, (uint256, uint256[]));
            IAggregator(swapBase.aggregator).uniswapV3Swap(swapData.quantity, minReturn, pools);
        } else if (swapBase.swapType == IAggregator.SwapType.UNISWAPV2) {
            (uint256 minReturn, address[] memory paths) = abi.decode(swapData.data, (uint256, address[]));
            IAggregator(swapBase.aggregator).swapExactTokensForTokens(swapData.quantity, minReturn, paths, address(this), SafeMath.add(block.timestamp, 1800));
        } else if (swapBase.swapType == IAggregator.SwapType.ONEINCH){
            Address.functionCallWithValue(swapBase.aggregator, swapData.data, 0);
            // _validateData(swapBase.quantity, swapBase.data, address(this));
        } else if (swapBase.swapType == IAggregator.SwapType.CURVE){
            // only supports stbt/usdc/usdt/dai curve pool
            (int128 i, int128 j, uint256 dx, uint256 minDy) = abi.decode(swapData.data, (int128, int128, uint256, uint256));
            ICurve(swapBase.aggregator).exchange_underlying(i, j, dx, minDy);
        } else {
            revert("ERR_INVALID_SWAP_TYPE");
        }
        
        postSwap = SafeMath.sub(swapAcceptToken.balanceOf(address(this)), preSwap);
    }

    function _getVault(address pool) internal view  returns(address){
        return IConfigurableRightsPool(pool).vaultAddress();
    }
    function _getUserVault(address pool) internal  returns(address){
        address vault = _getVault(pool);
        return IVault(vault).userVault();
    }

    function _calculateShare(LiquidityPoolActions bPool,uint totalPoolShares, uint issueFee, address t, uint actualTokenAmountIn) internal view returns(uint) {
        uint totalTokenBalance = bPool.getBalance(t);
        uint issueFeeRate = issueFee.bmul(1000);
        uint share = (totalPoolShares.bsub(1).bmul(actualTokenAmountIn) * (uint(1000).bsub(issueFeeRate))).bdiv((1000 * totalTokenBalance.badd(1)));
        return share;
    }

    receive() external payable {}
}
