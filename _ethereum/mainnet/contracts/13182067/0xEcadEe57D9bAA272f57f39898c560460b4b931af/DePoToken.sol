// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./UsingLiquidityProtectionService.sol";

contract DePoToken is Ownable, ERC20, UsingLiquidityProtectionService {
    // Mandatory overrides.
    function LPS_isAdmin() internal view override returns(bool) {
        return _msgSender() == owner();
    }
    function liquidityProtectionService() internal pure override returns(address) {
        return 0xaabAe39230233d4FaFf04111EF08665880BD6dFb;
    }
    // Expose balanceOf().
    function LPS_balanceOf(address _holder) internal view override returns(uint) {
        return balanceOf(_holder);
    }
    // Expose internal transfer function.
    function LPS_transfer(address _from, address _to, uint _value) internal override {
        _transfer(_from, _to, _value);
    }
    // All the following overrides are optional, if you want to modify default behavior.

    // How the protection gets disabled.
    function protectionChecker() internal view override returns(bool) {
        return ProtectionSwitch_timestamp(1632924000); // Switch off protection on Tuesday, September 29, 2021 2:00:00 PM.
        // return ProtectionSwitch_block(13000000); // Switch off protection on block 13000000.
        // return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.
    }

    // This token will be pooled in pair with:
    function counterToken() internal pure override returns(address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    }

    // Disable/Enable FirstBlockTrap
    function FirstBlockTrap_skip() internal pure override returns(bool) {
        return false;
    }

    // Disable/Enable absolute amount of tokens bought trap.
    // Per address per LiquidityAmountTrap_blocks.
    function LiquidityAmountTrap_skip() internal pure override returns(bool) {
        return false;
    }
    function LiquidityAmountTrap_blocks() internal pure override returns(uint8) {
        return 4;
    }
    function LiquidityAmountTrap_amount() internal pure override returns(uint128) {
        return 4600 * 1e18; // Only valid for tokens with 18 decimals.
    }

    // Disable/Enable percent of remaining liquidity bought trap.
    // Per address per block.
    function LiquidityPercentTrap_skip() internal pure override returns(bool) {
        return false;
    }
    function LiquidityPercentTrap_blocks() internal pure override returns(uint8) {
        return 6;
    }
    function LiquidityPercentTrap_percent() internal pure override returns(uint64) {
        return HUNDRED_PERCENT / 20; // 5%
    }

    // Disable/Enable number of trades trap.
    // Per block.
    function LiquidityActivityTrap_skip() internal pure override returns(bool) {
        return false;
    }
    function LiquidityActivityTrap_blocks() internal pure override returns(uint8) {
        return 3;
    }
    function LiquidityActivityTrap_count() internal pure override returns(uint8) {
        return 7;
    }

    constructor() ERC20('DePo Token', 'DEPO') {
        _mint(owner(), 1000000000 * 1e18);
    }

    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        LPS_beforeTokenTransfer(_from, _to, _amount);
    }
}
