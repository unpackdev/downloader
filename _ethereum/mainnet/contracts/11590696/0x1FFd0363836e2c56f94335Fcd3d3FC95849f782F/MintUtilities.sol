pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IFraxPool.sol";
import "./IFraxPartial.sol";
import "./IWETH.sol";


contract MintUtilities {
    using SafeMath for uint256;
    address constant private USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private FRAX_ADDRESS = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address constant private FXS_ADDRESS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address payable constant public UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant public REFERRAL_REWARD_ADDRESS = 0x234D953a9404Bf9DbC3b526271d440cD2870bCd2; // Frax main
    address public POOL_ADDRESS = 0x1864Ca3d47AaB98Ee78D11fc9DCC5E7bADdA1c0d;
    address public NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    IERC20 constant internal USDC_ERC20 = IERC20(USDC_ADDRESS);
    IERC20 constant internal WETH_ERC20 = IERC20(WETH_ADDRESS);
    IERC20 constant internal FRAX_ERC20 = IERC20(FRAX_ADDRESS);
    IERC20 constant internal FXS_ERC20 = IERC20(FXS_ADDRESS);
    IERC20 constant internal ETH_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IWETH constant internal WETH_IWETH = IWETH(WETH_ADDRESS);

    IFraxPool internal FRAX_POOL = IFraxPool(POOL_ADDRESS);
    IFraxPartial internal FRAX = IFraxPartial(FRAX_ADDRESS);

    IUniswapV2Router02 constant internal UniswapV2Router02 = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    address public owner_address;
    
    address payable public owner_address_payable;
    bool public is_paused;
    uint256 public minting_fee;
    uint256 private missing_decimals;

    // Super jank
    mapping(uint256 => address[]) PATHS; 

    struct MintFF_Params {
        uint256 fxs_price_usd; 
        uint256 col_price_usd;
        uint256 fxs_amount;
        uint256 collateral_amount;
        uint256 col_ratio;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner {
        require(msg.sender == owner_address, "Only the contract owner may perform this action");
        _;
    }

    modifier notPaused {
        require(is_paused == false, "Contract is paused");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor () public {
        owner_address = msg.sender;
        owner_address_payable = msg.sender;
        is_paused = false;
        PATHS[0] = [WETH_ADDRESS, USDC_ADDRESS];
        PATHS[1] = [WETH_ADDRESS, FRAX_ADDRESS, FXS_ADDRESS];
        minting_fee = FRAX_POOL.minting_fee();
        missing_decimals = 12; // manually set for USDC now
    }

    /* ========== VIEWS ========== */

    // Must be internal because of the struct
    function calcMintFractionalFRAX(MintFF_Params memory params) public view returns (uint256, uint256) {
        // Since solidity truncates division, every division operation must be the last operation in the equation to ensure minimum error
        // The contract must check the proper ratio was sent to mint FRAX. We do this by seeing the minimum mintable FRAX based on each amount 
        uint256 fxs_dollar_value_d18;
        uint256 c_dollar_value_d18;
        
        // Scoping for stack concerns
        {    
            // USD amounts of the collateral and the FXS
            fxs_dollar_value_d18 = params.fxs_amount.mul(params.fxs_price_usd).div(1e6);
            c_dollar_value_d18 = params.collateral_amount.mul(params.col_price_usd).div(1e6);

        }
        uint calculated_fxs_dollar_value_d18 = 
                    (c_dollar_value_d18.mul(1e6).div(params.col_ratio))
                    .sub(c_dollar_value_d18);

        uint fxs_needed = calculated_fxs_dollar_value_d18.mul(1e6).div(params.fxs_price_usd);

        uint mint_amount = c_dollar_value_d18.add(calculated_fxs_dollar_value_d18);
        mint_amount = (mint_amount.mul(uint(1e6).sub(minting_fee))).div(1e6);

        return (
            mint_amount,
            fxs_needed
        );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _swapETHForERC20(
        uint256 amountETH,
        uint256 token_out_min,
        address token_address,
        uint256 path_idx,
        uint256 last_path_idx
    ) internal notPaused returns (uint256, uint256) {

        // Do the swap
        (uint[] memory amounts) = UniswapV2Router02.swapExactETHForTokens.value(amountETH)(
            token_out_min,
            PATHS[path_idx],
            address(this),
            2105300114 // A long time from now
        );

        // Make sure enough tokens were recieved
        require(amounts[last_path_idx] >= token_out_min, "swapETHForERC20: Not enough tokens received from swap");
        
        // Approve for FraxPool
        IERC20(token_address).approve(POOL_ADDRESS, amounts[last_path_idx]);

        return (amounts[0], amounts[last_path_idx]);
    }

    function getExpectedFrax(
        uint256 input_collat,
        uint256 input_fxs
    ) public returns (uint256, uint256)
    {
        uint256 collateral_amount_d18 = input_collat * (10 ** missing_decimals);

        MintFF_Params memory input_params = MintFF_Params(
            FRAX.fxs_price(),
            FRAX_POOL.getCollateralPrice(),
            input_fxs,
            collateral_amount_d18,
            FRAX.global_collateral_ratio()
        );

        return calcMintFractionalFRAX(input_params);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function ethSwapToMintFF(
        uint256 amountETH_for_col,
        uint256 col_out_min,
        uint256 amountETH_for_fxs,
        uint256 fxs_out_min,
        uint256 frax_out_min
    ) external payable notPaused {

        // =================== ETH -> USDC via Uniswap ===================
        (uint256 usdc_eth_used, uint256 received_USDC) = _swapETHForERC20(
            amountETH_for_col, 
            col_out_min, 
            USDC_ADDRESS,
            0,
            1
        );

        // =================== ETH -> FXS via Uniswap ===================
        (uint256 fxs_eth_used, uint256 received_FXS) = _swapETHForERC20(
            amountETH_for_fxs, 
            fxs_out_min, 
            FXS_ADDRESS,
            1,
            2
        );

        (uint256 mint_amount, uint256 fxs_needed) = getExpectedFrax(received_USDC, received_FXS);

        require(received_FXS >= fxs_needed, "Not enough FXS received from swap");

        // Mint
        FRAX_POOL.mintFractionalFRAX(col_out_min, received_FXS, frax_out_min);

        // Return FRAX to sender.
        FRAX_ERC20.transfer(msg.sender, mint_amount);

        // Return unused USDC to sender.
        USDC_ERC20.transfer(msg.sender, received_USDC.sub(col_out_min));

        // Return unused FXS to sender.
        FXS_ERC20.transfer(msg.sender, received_FXS.sub(fxs_needed));

        // Return unused ETH dust to sender
        uint256 eth_refund = (msg.value).sub(usdc_eth_used).sub(fxs_eth_used);
        msg.sender.transfer(eth_refund);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // The smart contract should never end up having to need this as there should be no deposits. Just for emergency purposes
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner_address, tokenAmount);
    }

    function withdraw() external onlyOwner
    {
        msg.sender.transfer(address(this).balance);
    }

    function selfDestruct() external payable onlyOwner {
        selfdestruct(owner_address_payable);
    }

    function togglePaused() external onlyOwner {
        is_paused = !is_paused;
    } 

    function setPoolAddress(address _pool_address) external onlyOwner {
        POOL_ADDRESS = _pool_address;
        FRAX_POOL = IFraxPool(_pool_address);
    }
}