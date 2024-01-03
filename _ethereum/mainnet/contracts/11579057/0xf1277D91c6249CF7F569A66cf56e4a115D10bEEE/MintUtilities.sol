pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IFraxPool.sol";
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

    IERC20 constant internal USDC_ERC20 = IERC20(USDC_ADDRESS);
    IERC20 constant internal WETH_ERC20 = IERC20(WETH_ADDRESS);
    IERC20 constant internal FRAX_ERC20 = IERC20(FRAX_ADDRESS);
    IERC20 constant internal FXS_ERC20 = IERC20(FXS_ADDRESS);
    IERC20 constant internal ETH_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IWETH constant internal WETH_IWETH = IWETH(WETH_ADDRESS);

    IFraxPool internal FRAX_POOL = IFraxPool(POOL_ADDRESS);

    IUniswapV2Router02 constant internal UniswapV2Router02 = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);

    address public owner_address;
    
    address payable public owner_address_payable;
    bool public is_paused;

    modifier onlyOwner {
        require(msg.sender == owner_address, "Only the contract owner may perform this action");
        _;
    }

    modifier notPaused {
        require(is_paused == false, "Contract is paused");
        _;
    }

    constructor () public {
        owner_address = msg.sender;
        owner_address_payable = msg.sender;
        is_paused = false;
    }

    function _swapETHForERC20(
        uint256 amountETH,
        uint256 token_out_min,
        address token_address
    ) internal notPaused returns (uint256, uint256) {

        // Per Uniswap instructions, [0] must be WETH_ADDRESS
        address[] memory PATH = new address[](2);
        PATH[0] = WETH_ADDRESS;
        PATH[1] = token_address;

        // Buy some FXS with ETH
        (uint[] memory amounts) = UniswapV2Router02.swapExactETHForTokens.value(amountETH)(
            token_out_min,
            PATH,
            address(this),
            2105300114 // A long time from now
        );

        // Make sure enough tokens were recieved
        require(amounts[1] >= token_out_min, "swapETHForERC20: Not enough tokens received from swap");

        // Approve for FraxPool
        IERC20(token_address).approve(POOL_ADDRESS, amounts[1]);

        return (amounts[0], amounts[1]);
    }


    function ethSwapToMintFF(
        uint256 amountETH_for_col,
        uint256 col_out_min,
        uint256 amountETH_for_fxs,
        uint256 fxs_out_min,
        uint256 frax_out_min
    ) external payable notPaused {

        // =================== ETH -> USDC via Uniswap ===================
        (uint256 usdc_eth_used, uint256 received_USDC) = _swapETHForERC20(amountETH_for_col, col_out_min, USDC_ADDRESS);

        // =================== ETH -> FXS via Uniswap ===================
        (uint256 fxs_eth_used, uint256 received_FXS) = _swapETHForERC20(amountETH_for_fxs, fxs_out_min, FXS_ADDRESS);

        // Mint
        FRAX_POOL.mintFractionalFRAX(received_USDC, received_FXS, frax_out_min);

        // Return FRAX to sender. Note that there may be crumbs left over...
        FRAX_ERC20.transfer(msg.sender, frax_out_min);

        // Return unused ETH dust to sender
        uint256 eth_crumbs = amountETH_for_col.add(amountETH_for_fxs).sub(usdc_eth_used).sub(fxs_eth_used);
        msg.sender.transfer(eth_crumbs);
    }

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