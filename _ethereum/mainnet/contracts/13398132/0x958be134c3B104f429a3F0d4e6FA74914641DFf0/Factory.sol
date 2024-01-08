// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.3;

import "./Ownable.sol";
import "./IERC20.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";
import "./TokenFarming.sol";

contract Factory is Ownable {
    event FarmingDeployed(address _farmingImp, address _farmingProxy, address _proxyAdmin);

    function deployFarmingContract(
        address _stakeToken,
        address _distributionToken,
        uint256 _rewardPerBlock
    )
        external
        onlyOwner
        returns (
            address,
            address,
            address
        )
    {
        TokenFarming _farmingImp = new TokenFarming();
        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        TransparentUpgradeableProxy _proxy =
            new TransparentUpgradeableProxy(address(_farmingImp), address(_proxyAdmin), "");
        TokenFarming _farmingProxy = TokenFarming(address(_proxy));
        _farmingProxy.initTokenFarming(_stakeToken, _distributionToken, _rewardPerBlock);
        _farmingProxy.transferOwnership(msg.sender);
        _proxyAdmin.transferOwnership(msg.sender);

        emit FarmingDeployed(address(_farmingImp), address(_farmingProxy), address(_proxyAdmin));
        return (address(_farmingImp), address(_farmingProxy), address(_proxyAdmin));
    }
}
