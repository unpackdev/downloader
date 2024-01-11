//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


import "./RewardProgramVaultStorage.sol";
import "./VaultProxy.sol";

import "./IProxyEvent.sol";

import "./Address.sol";
//import "./console.sol";

contract RewardProgramVaultProxy is RewardProgramVaultStorage, VaultProxy
{
    function setBaseInfoProxy(
        string memory _name,
        address _pool,
        address _token,
        address _staker,
        address _owner,
        uint256 _startWaitTime
    ) external onlyOwner  {
        require(bytes(name).length == 0,"already set");
        require(_staker != address(0) && _pool != address(0) && _token != address(0)
                && _owner != address(0), "zero address");
        require(_startWaitTime >= 30, "_startWaitTime is less than 30");

        name = _name;
        token = IERC20Minimal(_token);
        pool = IUniswapV3Pool(_pool);
        staker = IUniswapV3Staker(_staker);

        startWaitTime = _startWaitTime;

        if(!isAdmin(_owner)){
            _setupRole(PROJECT_ADMIN_ROLE, _owner);
        }

    }
}
