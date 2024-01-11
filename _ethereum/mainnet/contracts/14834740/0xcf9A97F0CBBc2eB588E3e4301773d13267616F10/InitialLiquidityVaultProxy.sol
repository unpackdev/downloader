//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./InitialLiquidityVaultStorage.sol";
import "./VaultProxy.sol";

contract InitialLiquidityVaultProxy is InitialLiquidityVaultStorage, VaultProxy
{

    function setBaseInfoProxy(
        string memory _name,
        address _token,
        address _owner,
        uint256 tosPrice,
        uint256 tokenPrice
    ) external onlyOwner {
        require(bytes(name).length == 0,"already set");
        require(_token != address(0) && _owner != address(0), "zero address");
        require(tosPrice > 0 && tokenPrice > 0, "zero price");

        name = _name;
        token = IERC20(_token);

        if(!isAdmin(_owner)){
            _setupRole(PROJECT_ADMIN_ROLE, _owner);
        }

        initialTosPrice = tosPrice;
        initialTokenPrice = tokenPrice;
    }
}
