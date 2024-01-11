// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./Ownable.sol";

error SwapNotEnabledYet();

contract BP is Ownable {
    
    // For bp (bot protection), to deter liquidity sniping, enabled during first moments of each swap liquidity (ie. Uniswap, Quickswap, etc)
    uint256 public bpAllowedNumberOfTx;     // Max allowed number of buys/sells on swap during bp per address
    uint256 public bpMaxGas;                // Max gwei per trade allowed during bot protection
    uint256 public bpMaxBuyAmount;          // Max number of tokens an address can buy during bot protection
    uint256 public bpMaxSellAmount;         // Max number of tokens an address can sell during bot protection
    bool public bpEnabled;                  // Bot protection, on or off
    bool public bpTradingEnabled;           // Enables trading during bot protection period
    bool public bpPermanentlyDisabled;      // Starts false, but when set to true, is permanently true. Let's public see that it is off forever.
    address bpSwapPairRouterPool;           // ie. Uniswap V2 ETH-REMN Pool (router) for bot protected buy/sell, add after pool established.
    mapping (address => uint256) public bpAddressTimesTransacted;   // Mapped value counts number of times transacted (2 max per address during bp)
    mapping (address => bool) public bpBlacklisted;                 // If wallet tries to trade after liquidity is added but before owner sets trading on, wallet is blacklisted

    /**
     * @dev Toggles bot protection, blocking suspicious transactions during liquidity events.
     */
    function bpToggleOnOff() external onlyOwner {
        bpEnabled = !bpEnabled;
    }

    /**
     * @dev Sets max gwei allowed in transaction when bot protection is on.
     */
    function bpSetMaxGwei(uint256 gweiAmount) external onlyOwner {
        bpMaxGas = gweiAmount;
    }

    /**
     * @dev Sets max buy value when bot protection is on.
     */
    function bpSetMaxBuyValue(uint256 val) external onlyOwner {
        bpMaxBuyAmount = val;
    }

     /**
     * @dev Sets max sell value when bot protection is on.
     */
    function bpSetMaxSellValue(uint256 val) external onlyOwner {
        bpMaxSellAmount = val;
    }

    /**
     * @dev Sets swap pair pool address (i.e. Uniswap V2 ETH-REMN pool, for bot protection)
     */
    function bpSetSwapPairPool(address addr) external onlyOwner {
        bpSwapPairRouterPool = addr;
    }

    /**
     * @dev Turns off bot protection permanently.
     */
    function bpDisablePermanently() external onlyOwner {
        bpEnabled = false;
        bpPermanentlyDisabled = true;
    }

    /**
     * @dev Toggles trading (requires bp not permanently disabled)
     */
    function bpToggleTrading() external onlyOwner {
        require(!bpPermanentlyDisabled, "Cannot toggle when bot protection is already disabled permanently");
        bpTradingEnabled = !bpTradingEnabled;
    }

}