// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./BP.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract RemnantToken is ERC20, Ownable, BP {

    // For team, staking, P2E ecosystem, other
    uint256 public constant INITIAL_AMOUNT_ECOSYSTEM = 2_500_000_000; // 25%
    uint256 public constant INITIAL_AMOUNT_BACKERS = 2_500_000_000; // 25%
    uint256 public constant INITIAL_AMOUNT_STAKING = 1_500_000_000; // 15%
    uint256 public constant INITIAL_AMOUNT_TEAM = 1_000_000_000; // 10%
    uint256 public constant INITIAL_AMOUNT_LIQUIDITY = 850_000_000; // 8.5%
    uint256 public constant INITIAL_AMOUNT_MARKETING = 700_000_000; // 7%
    uint256 public constant INITIAL_AMOUNT_TREASURY = 500_000_000; // 5%
    uint256 public constant INITIAL_AMOUNT_DEVELOPMENT = 450_000_000; // 4.5%
    
    address public constant ADDRESS_ECOSYSTEM = 0x331cEE12D7f2D86Bd971b03B1CF5621D54c5Bf88;
    address public constant ADDRESS_BACKERS = 0xf041934376DE4b89E5B68DA6A2720B132AB3a998;
    address public constant ADDRESS_STAKING = 0x5ecd185e32b478B4f58C5F3565FdceA3023884A1;
    address public constant ADDRESS_TEAM = 0xb09613A3e92971Db7a038BC5cDDd635Bd718cAC1;
    address public constant ADDRESS_LIQUIDITY = 0x9DC4632021E77fa9A28eDA25561C525e6396d4f7;
    address public constant ADDRESS_MARKETING = 0xaCe849e4E8152271a7a587Eee07256Bb15214948;
    address public constant ADDRESS_TREASURY = 0x72b082925f7e51B1Acfd34425846913Be6B043B7;
    address public constant ADDRESS_DEVELOPMENT = 0xf5634bEc8e0D7c7B565BDf433882C516f4Ea3342;

    constructor() ERC20("RemnantToken", "REMN") {
        _mint(ADDRESS_ECOSYSTEM, INITIAL_AMOUNT_ECOSYSTEM * 10 ** 18);
        _mint(ADDRESS_BACKERS, INITIAL_AMOUNT_BACKERS * 10 ** 18);
        _mint(ADDRESS_STAKING, INITIAL_AMOUNT_STAKING * 10 ** 18);
        _mint(ADDRESS_TEAM, INITIAL_AMOUNT_TEAM * 10 ** 18);
        _mint(ADDRESS_LIQUIDITY, INITIAL_AMOUNT_LIQUIDITY * 10 ** 18);
        _mint(ADDRESS_MARKETING, INITIAL_AMOUNT_MARKETING * 10 ** 18);
        _mint(ADDRESS_TREASURY, INITIAL_AMOUNT_TREASURY * 10 ** 18);
        _mint(ADDRESS_DEVELOPMENT, INITIAL_AMOUNT_DEVELOPMENT * 10 ** 18);
    }

    /**
     * @dev Check before token transfer if bot protection is on, to block suspicious transactions
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        // Bot/snipe protection requirements if bp (bot protection) is on, and is not already permanently disabled
        if (bpEnabled) {
            if (!bpPermanentlyDisabled && msg.sender != owner()) { // Save gas, don't check if don't pass bpEnabled
                require(!bpBlacklisted[from] && !bpBlacklisted[to], "BP: Account is blacklisted"); // Must not be blacklisted
                require(tx.gasprice <= bpMaxGas, "BP: Gas setting exceeds allowed limit"); // Must set gas below allowed limit
            
                // If user is buying (from swap), check that the buy amount is less than the limit (this will not block other transfers unrelated to swap liquidity)
                if (bpSwapPairRouterPool == from) {
                    require(amount <= bpMaxBuyAmount, "BP: Buy exceeds allowed limit"); // Cannot buy more than allowed limit
                    require(bpAddressTimesTransacted[to] < bpAllowedNumberOfTx, "BP: Exceeded number of allowed transactions");
                    if (!bpTradingEnabled) {
                        bpBlacklisted[to] = true; // Blacklist wallet if it tries to trade (i.e. bot automatically trying to snipe liquidity)
                        revert SwapNotEnabledYet(); // Revert with error message
                    } else {
                        bpAddressTimesTransacted[to] += 1; // User has passed transaction conditions, so add to mapping (to limit user to 2 transactions)
                    }
                // If user is selling (from swap), check that the sell amount is less than the limit. The code is mostly repeated to avoid declaring variable and wasting gas.
                } else if (bpSwapPairRouterPool == to) {
                    require(amount <= bpMaxSellAmount, "BP: Sell exceeds limit"); // Cannot sell more than allowed limit
                    require(bpAddressTimesTransacted[from] < bpAllowedNumberOfTx, "BP: Exceeded number of allowed transactions");
                    if (!bpTradingEnabled) {
                        bpBlacklisted[from] = true; // Blacklist wallet if it tries to trade (i.e. bot automatically trying to snipe liquidity)
                        revert SwapNotEnabledYet(); // Revert with error message
                    } else {
                        bpAddressTimesTransacted[from] += 1; // User has passed transaction conditions, so add to mapping (to limit user to 2 transactions)
                    }
                }
            }
        }
        super._beforeTokenTransfer(from, to, amount);
    }

}