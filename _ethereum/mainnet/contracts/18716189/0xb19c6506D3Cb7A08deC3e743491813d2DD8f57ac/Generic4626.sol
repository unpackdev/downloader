// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity <=0.8.19;

import "./ERC4626.sol";

contract Generic4626 is ERC4626 {
    constructor(ERC20 _asset)
        ERC4626(_asset, string.concat(_asset.name(), "_4626_Vault"), string.concat(_asset.symbol(), "_4626"))
    {}

    function totalAssets() public view virtual override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}
