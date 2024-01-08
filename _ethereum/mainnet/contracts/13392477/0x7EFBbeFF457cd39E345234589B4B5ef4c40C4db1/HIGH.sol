// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./ERC20.sol";
import "./UsingLiquidityProtectionService.sol";
import "./Ownable.sol";

contract HIGH is ERC20, Ownable, UsingLiquidityProtectionService(0x87CEA93454e2DDA31dCB9Cd12c07824f5843901d) {
    constructor(address minter) ERC20("Street Token", "HIGH"){
        uint256 amount = 100000000 * 1e18; //decimals 18
        _mint(minter, amount);
    }

    function token_transfer(address _from, address _to, uint _amount) internal override {
        _transfer(_from, _to, _amount); // Expose low-level token transfer function.
    }
    function token_balanceOf(address _holder) internal view override returns(uint) {
        return balanceOf(_holder); // Expose balance check function.
    }
    function protectionAdminCheck() internal view override onlyOwner {} // Must revert to deny access.
    function uniswapVariety() internal pure override returns(bytes32) {
        return UNISWAP; // UNISWAP / PANCAKESWAP / QUICKSWAP.
    }
    function uniswapVersion() internal pure override returns(UniswapVersion) {
        return UniswapVersion.V3; // V2 or V3.
    }
    function uniswapFactory() internal pure override returns(address) {
        return 0x1F98431c8aD98523631AE4a59f267346ea31F984; // Replace with the correct address.
    }
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        LiquidityProtection_beforeTokenTransfer(_from, _to, _amount);
    }
    // All the following overrides are optional, if you want to modify default behavior.

    // How the protection gets disabled.
    function protectionChecker() internal view override returns(bool) {
         return ProtectionSwitch_timestamp(1635724799); // Switch off protection on Sunday, October 31, 2021 11:59:59 PM GMT.
        // return ProtectionSwitch_block(13000000); // Switch off protection on block 13000000.
//        return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.
    }

    // This token will be pooled in pair with:
    function counterToken() internal pure override returns(address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    }
}
