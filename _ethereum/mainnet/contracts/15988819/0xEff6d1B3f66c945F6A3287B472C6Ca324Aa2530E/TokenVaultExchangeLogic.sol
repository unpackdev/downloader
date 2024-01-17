pragma solidity ^0.8.0;

import "./Address.sol";
import "./ClonesUpgradeable.sol";
import "./ISettings.sol";
import "./IExchange.sol";

library TokenVaultExchangeLogic {
    //
    function newExchangeInstance(address settings, address vaultToken)
        external
        returns (address)
    {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address)",
            vaultToken
        );
        address exchange = ClonesUpgradeable.clone(
            ISettings(settings).exchangeTpl()
        );
        Address.functionCall(exchange, _initializationCalldata);
        return exchange;
    }

    function addRewardToken(address exchange, address token) external {
        IExchange(exchange).addRewardToken(token);
    }
}
