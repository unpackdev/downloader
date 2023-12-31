// "SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./GelatoActionsStandard.sol";
import "./IGelatoAction.sol";
import "./IGelatoProviders.sol";
import "./IGelatoProviderModule.sol";

// This Action is the Provider and must be called from any UserProxy with .call a
contract MockActionMaliciousProvider  {
    IGelatoProviders immutable gelato;

    constructor(IGelatoProviders _gelato) public { gelato = _gelato; }

    receive() external payable {}

    function action() public payable virtual {
        uint256 providerFunds = gelato.providerFunds(address(this));
        try gelato.unprovideFunds(providerFunds) {
        } catch Error(string memory err) {
            revert(
                string(
                    abi.encodePacked("MockActionMaliciousProvider.action.unprovideFunds:", err)
                )
            );
        } catch {
            revert("MockActionMaliciousProvider.action.unprovideFunds:undefinded");
        }
    }

    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    )
        external
        payable
    {
        try gelato.multiProvide{value: msg.value}(_executor, _taskSpecs, _modules) {
        } catch Error(string memory err) {
            revert(
                string(abi.encodePacked("MockActionMaliciousProvider.multiProvide:", err))
            );
        } catch {
            revert("MockActionMaliciousProvider.multiProvide:undefinded");
        }
    }
}
