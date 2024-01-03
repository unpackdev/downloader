pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./OneSplitAudit.sol";
import "./IFraxPool.sol";
import "./IWETH.sol";

// 1inch stuff here
// https://github.com/1inch-exchange/1inchProtocol/tree/master/contracts/interface
// https://github.com/1inch-exchange/1inchProtocol/blob/master/contracts/IOneSplit.sol
// https://github.com/1inch-exchange/1inchProtocol

contract MintUtilities {
    using SafeMath for uint256;
    address constant private USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant private WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant private FRAX_ADDRESS = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address constant private FXS_ADDRESS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address payable constant public ONE_SPLIT_AUDIT_ADDRESS = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

    IERC20 constant internal USDC_ERC20 = IERC20(USDC_ADDRESS);
    IERC20 constant internal WETH_ERC20 = IERC20(WETH_ADDRESS);
    IERC20 constant internal FRAX_ERC20 = IERC20(FRAX_ADDRESS);
    IERC20 constant internal FXS_ERC20 = IERC20(FXS_ADDRESS);
    IERC20 constant internal ETH_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IWETH constant internal WETH_IWETH = IWETH(WETH_ADDRESS);

    OneSplitAudit constant internal OneSplit_Inst = OneSplitAudit(ONE_SPLIT_AUDIT_ADDRESS);

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

    function _swapETHForUSDC(
        uint256 amountETH,
        uint256 usdc_out_min,
        uint256[] memory distribution_ETH_USDC
    ) internal notPaused returns (uint256) {
        // Swap some ETH for USDC
        (uint256 received_USDC) = OneSplit_Inst.swap(
            ETH_ERC20,
            USDC_ERC20,
            amountETH,
            usdc_out_min,
            distribution_ETH_USDC,
            0
        );
        
        // Make sure enough USDC was recieved
        require(received_USDC >= usdc_out_min, "[_swapETHForUSDC]: Not enough USDC received from swap");

        return received_USDC;
    }

    function _swapUSDCForFXS(
        uint256 received_USDC,
        uint256 fxs_out_min,
        uint256[] memory distribution_USDC_FXS
    ) internal notPaused returns (uint256) {
        // Approve the USDC for 1inch
        USDC_ERC20.approve(address(this), received_USDC);

        // Swap some USDC for FXS
        (uint256 received_FXS) = OneSplit_Inst.swap(
            USDC_ERC20,
            FXS_ERC20,
            received_USDC,
            fxs_out_min,
            distribution_USDC_FXS,
            0
        );

        // Make sure enough FXS was recieved
        require(received_FXS >= fxs_out_min, "[_swapUSDCForFXS]: Not enough FXS received from swap");

        return received_FXS;
    }

    function ethSwapToMintFF(
        uint256 amountETH,
        uint256 usdc_out_min,
        uint256[] calldata distribution_ETH_USDC,
        uint256 fxs_out_min,
        uint256[] calldata distribution_USDC_FXS,
        uint256 usdc_for_mint,
        uint256 frax_out_min,
        address _pool_address
    ) external payable notPaused {
        require(msg.value == amountETH, "msg.value doesn't match amountETH");
        // =================== ETH -> USDC via 1inch ===================
        (uint256 received_USDC) = _swapETHForUSDC(amountETH, usdc_out_min, distribution_ETH_USDC);

        // =================== USDC -> FXS via 1inch ===================
        (uint256 received_FXS) = _swapUSDCForFXS(received_USDC, fxs_out_min, distribution_USDC_FXS);

        // =================== USDC + FXS -> FRAX via FraxPool mint ===================

        // Approve the Collat for the FraxPool
        USDC_ERC20.approve(_pool_address, (usdc_for_mint).mul(105).div(100));

        // Approve the FXS for the FraxPool
        FXS_ERC20.approve(_pool_address, (received_FXS).mul(105).div(100));

        // Mint
        IFraxPool(_pool_address).mintFractionalFRAX(usdc_for_mint, received_FXS, frax_out_min);

        // Return FRAX to owner. Note that there may be crumbs left over...
        FRAX_ERC20.transfer(msg.sender, frax_out_min);
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
}