// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "./ERC20Capped.sol";

contract Token is ERC20Capped {
    uint8 private immutable customDecimals;

    error Token_InvalidMintParams();
    error Token_InvalidSupply();

    constructor(
        string memory erc20Name_,
        string memory erc20Symbol_,
        uint8 decimals_,
        uint256 cap_,
        address[] memory mintAddresses_,
        uint256[] memory mintAmounts_
    ) ERC20(erc20Name_, erc20Symbol_) ERC20Capped(cap_) {
        uint256 _mintAddressesLength = mintAddresses_.length;
        if (_mintAddressesLength != mintAmounts_.length) {
            revert Token_InvalidMintParams();
        }

        customDecimals = decimals_;

        for (uint256 i; i < _mintAddressesLength; ++i) {
            ERC20._mint(mintAddresses_[i], mintAmounts_[i]);
        }

        if (cap_ < totalSupply()) {
            revert Token_InvalidSupply();
        }
    }

    function decimals() public view override returns (uint8) {
        return customDecimals;
    }
}
