// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV3Factory.sol";
import "./TransferHelper.sol";
import "./ISwapRouter.sol";
import "./IPeripheryPaymentsWithFee.sol";
import "./IQuoter.sol";
import "./IUniswapV3Pool.sol";
import "./TransferHelper.sol";
import "./IFiat24Account.sol";
import "./IEUROC.sol";
import "./SanctionsList.sol";

error Fiat24EurocTopUp__NotOperator();
error Fiat24EurocTopUp__CryptoTopUpSuspended();
error Fiat24EurocTopUp__NoUSDCPoolAvailable();
error Fiat24EurocTopUp__NotSufficientBalance();
error Fiat24EurocTopUp__NotSufficientAllowance();
error Fiat24EurocTopUp__ETHAmountMustNotBeZero();
error Fiat24EurocTopUp__EthRefundFailed();
error Fiat24EurocTopUp__AddressSanctioned();
error Fiat24EurocTopUp__AddressEurocBlackListed();
error Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
error Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
error Fiat24EurocTopUp__MonthlyLimitExceeded();
error Fiat24EurocTopUp__AddressHasNoToken();
error Fiat24EurocTopUp__TokenIsNotLive();

contract Fiat24EurocTopUp is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeMath for uint256;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // RINKEBY
    // address public constant WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    // address public constant USDC_ADDRESS = 0x53eFd5F117E51f891d2EC46bc92FC56A60E3D453;
    // address public constant EUROC_ADDRESS = 0xc9E42020Cae3f4994443c25da7681a54870e8E5E;

    // GOERLI
    address public constant WETH_ADDRESS = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address public constant USDC_ADDRESS = 0x4a42255E9CF5Cc3CF1189cFDF07191CEC622c86A;
    address public constant EUROC_ADDRESS = 0xee2e22fAA3f8916Ed2F835380714d87D504AC7d5;

    // MAINNET
    // address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address public constant USDC_ADDRESS = 0x3650Df787413973172284B1b534A510ff7e6128E;
    // address public constant EUROC_ADDRESS = 0x00C95eEfc60D5519d2c73e29CEe7C945df7F254E;

    IEUROC public constant EUROC = IEUROC(EUROC_ADDRESS);

    uint256 public fee;
    uint256 public slippage;
    uint256 public maxTopUpAmount;
    uint256 public minTopUpAmount;

    IUniswapV3Factory public constant uniswapFactory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPeripheryPaymentsWithFee public constant peripheryPayments = IPeripheryPaymentsWithFee(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter public constant quoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6); 

    address public eurocTreasuryAddress;
    address public eurocPLAddress;

    bool public blacklistCheck;
    bool public sanctionCheck;
    address public sanctionContractAddress;

    event EurocTopUp(address indexed sender, address indexed tokenIn, uint256 indexed blockNumber, uint256 eurcAmount);

    function initialize(address eurocTreasuryAddress_, 
                        address eurocPLAddress_,
                        address sanctionContractAddress_,
                        uint256 maxTopUpAmount_,
                        uint256 minTopUpAmount_,
                        uint256 fee_, 
                        uint256 slippage_) public initializer {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, msg.sender);
        eurocTreasuryAddress = eurocTreasuryAddress_;
        eurocPLAddress = eurocPLAddress_;
        sanctionContractAddress = sanctionContractAddress_;
        sanctionCheck = false;
        blacklistCheck = false;
        maxTopUpAmount = maxTopUpAmount_;
        minTopUpAmount = minTopUpAmount_;
        fee = fee_;
        slippage = slippage_;
    }

    function topUpEUROCWithERC20(address tokenIn, uint256 amount) external returns(uint256) {
        if(paused()) {
            revert Fiat24EurocTopUp__CryptoTopUpSuspended();
        }
        if(sanctionCheck) {
            SanctionsList sanctionsList = SanctionsList(sanctionContractAddress);
            if(sanctionsList.isSanctioned(msg.sender)) {
                revert Fiat24EurocTopUp__AddressSanctioned();
            }
        }
        if(blacklistCheck) {
            if(EUROC.isBlacklisted(msg.sender)) {
                revert Fiat24EurocTopUp__AddressEurocBlackListed();
            }
        }
        if(IERC20(tokenIn).balanceOf(msg.sender) < amount) {
            revert Fiat24EurocTopUp__NotSufficientBalance();
        }
        if(IERC20(tokenIn).allowance(msg.sender, address(this)) < amount) {
            revert Fiat24EurocTopUp__NotSufficientAllowance();
        }
        uint256 eurocAmount;
        if(tokenIn == EUROC_ADDRESS) {
            eurocAmount = amount;
            TransferHelper.safeTransferFrom(EUROC_ADDRESS, msg.sender, address(this), amount);
        } else {
            uint24 poolFee = getPoolFeeOfMostLiquidPool(tokenIn, EUROC_ADDRESS);
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amount);
            TransferHelper.safeApprove(tokenIn, address(swapRouter), amount);
            if(poolFee == 0) {
                poolFee = getPoolFeeOfMostLiquidPool(tokenIn, USDC_ADDRESS);
                if(poolFee == 0) {
                    revert Fiat24EurocTopUp__NoUSDCPoolAvailable();
                }
                uint24 usdcEurcPoolFee = getPoolFeeOfMostLiquidPool(USDC_ADDRESS, EUROC_ADDRESS);
                uint256 amountOutMinimum = getQuoteMultihop(tokenIn, USDC_ADDRESS, EUROC_ADDRESS, poolFee, usdcEurcPoolFee, amount);
                if(amountOutMinimum > maxTopUpAmount) {
                    revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
                }
                if(amountOutMinimum < minTopUpAmount) {
                    revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
                }
                amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
                ISwapRouter.ExactInputParams memory params =
                    ISwapRouter.ExactInputParams({
                        path: abi.encodePacked(tokenIn, poolFee, USDC_ADDRESS, usdcEurcPoolFee, EUROC_ADDRESS),
                        recipient: address(this),
                        deadline: block.timestamp,
                        amountIn: amount,
                        amountOutMinimum: amountOutMinimum
                    });
                eurocAmount = swapRouter.exactInput(params);
            } else {
                uint256 amountOutMinimum = getQuoteSingle(tokenIn, EUROC_ADDRESS, poolFee, amount);
                amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
                if(amountOutMinimum > maxTopUpAmount) {
                    revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
                }
                if(amountOutMinimum < minTopUpAmount) {
                    revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
                }
                ISwapRouter.ExactInputSingleParams memory params =
                    ISwapRouter.ExactInputSingleParams({
                        tokenIn: tokenIn,
                        tokenOut: EUROC_ADDRESS,
                        fee: poolFee,
                        recipient: address(this),
                        deadline: block.timestamp + 15,
                        amountIn: amount,
                        amountOutMinimum: amountOutMinimum,
                        sqrtPriceLimitX96: 0
                    });
                eurocAmount = swapRouter.exactInputSingle(params);
            }
        }
        if(eurocAmount > maxTopUpAmount) {
            revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
        }
        TransferHelper.safeTransfer(EUROC_ADDRESS, eurocTreasuryAddress, eurocAmount);
        emit EurocTopUp(msg.sender, tokenIn, block.number, eurocAmount);
        return eurocAmount;
    }

    function topUpEUROCWithETH() external payable returns(uint256) {
       if(paused()) {
            revert Fiat24EurocTopUp__CryptoTopUpSuspended();
        }
        if(msg.value == 0) {
            revert Fiat24EurocTopUp__ETHAmountMustNotBeZero();
        }
        if(sanctionCheck) {
            SanctionsList sanctionsList = SanctionsList(sanctionContractAddress);
            if(sanctionsList.isSanctioned(msg.sender)) {
                revert Fiat24EurocTopUp__AddressSanctioned();
            }
        }
        if(blacklistCheck) {
            if(EUROC.isBlacklisted(msg.sender)) {
                revert Fiat24EurocTopUp__AddressEurocBlackListed();
            }
        }
        uint24 poolFee = getPoolFeeOfMostLiquidPool(WETH_ADDRESS, EUROC_ADDRESS);
        uint256 eurocAmount;
        if(poolFee == 0) {
            poolFee = getPoolFeeOfMostLiquidPool(WETH_ADDRESS, USDC_ADDRESS);
            if(poolFee == 0) {
                revert Fiat24EurocTopUp__NoUSDCPoolAvailable();
            }
            uint24 usdcEurcPoolFee = getPoolFeeOfMostLiquidPool(USDC_ADDRESS, EUROC_ADDRESS);
            uint256 amountOutMinimum = getQuoteMultihop(WETH_ADDRESS, USDC_ADDRESS, EUROC_ADDRESS, poolFee, usdcEurcPoolFee, msg.value);
            if(amountOutMinimum > maxTopUpAmount) {
                revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
            }
            if(amountOutMinimum < minTopUpAmount) {
                revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
            }
            amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(WETH_ADDRESS, poolFee, USDC_ADDRESS, usdcEurcPoolFee, EUROC_ADDRESS),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: msg.value,
                    amountOutMinimum: amountOutMinimum
                });
            eurocAmount = swapRouter.exactInput{value: msg.value}(params);
        } else {
            uint256 amountOutMinimum = getQuoteSingle(WETH_ADDRESS, EUROC_ADDRESS, poolFee, msg.value);
            amountOutMinimum.sub(amountOutMinimum.mul(slippage).div(100));
            if(amountOutMinimum > maxTopUpAmount) {
                revert Fiat24EurocTopUp__AmountExceedsMaxTopUpAmount();
            }
            if(amountOutMinimum < minTopUpAmount) {
                revert Fiat24EurocTopUp__AmountBelowMinTopUpAmount();
            }
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: WETH_ADDRESS,
                    tokenOut: EUROC_ADDRESS,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp + 15,
                    amountIn: msg.value,
                    amountOutMinimum: amountOutMinimum,
                    sqrtPriceLimitX96: 0
                });
            eurocAmount = swapRouter.exactInputSingle{value: msg.value}(params);
        }
        TransferHelper.safeTransfer(EUROC_ADDRESS, eurocTreasuryAddress, eurocAmount);
        peripheryPayments.refundETH();
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        if(!success) {
            revert Fiat24EurocTopUp__EthRefundFailed();
        }
        emit EurocTopUp(msg.sender, WETH_ADDRESS, block.number, eurocAmount);
        return eurocAmount;
    }

    function getPoolFeeOfMostLiquidPool(address inputToken, address outputToken) public view returns(uint24) {
        uint24 feeOfMostLiquidPool = 0;
        uint128 highestLiquidity = 0;
        uint128 liquidity;
        IUniswapV3Pool pool;
        address poolAddress = uniswapFactory.getPool(inputToken, outputToken, 100);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 100;
            }
        }
        poolAddress = uniswapFactory.getPool(inputToken, outputToken, 500);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 500;
            }
        }
        poolAddress = uniswapFactory.getPool(inputToken, outputToken, 3000);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 3000;
            }
        }
        poolAddress = uniswapFactory.getPool(inputToken, outputToken, 10000);
        if(poolAddress != address(0)) {
            pool = IUniswapV3Pool(poolAddress);
            liquidity = pool.liquidity();
            if(liquidity > highestLiquidity) {
                highestLiquidity = liquidity;
                feeOfMostLiquidPool = 10000;
            }
        }
        return feeOfMostLiquidPool;
    }

    function getQuoteSingle(address tokenIn, address tokenOut, uint24 fee_, uint256 amount) public payable returns(uint256) {
        return quoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee_,
            amount,
            0
        ); 
    }

    function getQuoteMultihop(address tokenIn, address tokenHop, address tokenOut, uint24 poolFee1, uint24 poolFee2, uint256 amount) public payable returns(uint256){
        return quoter.quoteExactInput(
            abi.encodePacked(tokenIn, poolFee1, tokenHop, poolFee2, tokenOut),
            amount
        );
    }

    function changeEurocTreasuryAddress(address eurocTreasuryAddress_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        eurocTreasuryAddress = eurocTreasuryAddress_;
    }

    function changeEurocPLAddress(address eurocPLAddress_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        eurocPLAddress = eurocPLAddress_;
    }

    function changeMaxTopUpAmount(uint256 maxTopUpAmount_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        maxTopUpAmount = maxTopUpAmount_;      
    }

    function changeMinTopUpAmount(uint256 minTopUpAmount_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        minTopUpAmount = minTopUpAmount_;      
    }

    function changeFee(uint256 fee_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        fee = fee_;       
    }

    function changeSlippage(uint256 slippage_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        slippage = slippage_;
    }

    function setBlacklistCheck(bool blacklistCheck_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        blacklistCheck = blacklistCheck_;
    }

    function setSanctionCheck(bool sanctionCheck_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        sanctionCheck = sanctionCheck_;
    }

    function setSanctionCheckContract(address sanctionContractAddress_) external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        sanctionContractAddress = sanctionContractAddress_;
    }

    function pause() public {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        _pause();
    }

    function unpause() public {
        if(!hasRole(OPERATOR_ROLE, msg.sender)){
            revert Fiat24EurocTopUp__NotOperator();
        }
        _unpause();
    }

    receive() payable external {}
}