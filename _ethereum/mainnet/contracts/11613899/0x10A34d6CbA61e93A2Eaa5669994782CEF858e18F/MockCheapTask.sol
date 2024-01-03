// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./MockProviderModule.sol";
import "./Address.sol";
import "./GelatoString.sol";
import "./IGelatoCore.sol";
import "./IGelatoProviders.sol";
import "./IGelatoProviders.sol";
import "./IGelatoProviderModule.sol";

contract MockCheapTask is Ownable, MockProviderModule {
    using Address for address payable;
    using GelatoString for string;

    // solhint-disable no-empty-blocks

    address public immutable gelatoCore;

    constructor(address _gelatoCore, address _executor) {
        gelatoCore = _gelatoCore;
        IGelatoProviderModule[] memory modules = new IGelatoProviderModule[](1);
        modules[0] = IGelatoProviderModule(this);
        try
            IGelatoProviders(_gelatoCore).multiProvide(
                _executor,
                new TaskSpec[](0),
                modules
            )
        {} catch {}
    }

    receive() external payable {
        require(
            msg.sender == gelatoCore,
            "MockCheapTask.receive:onlyGelatoCore"
        );
    }

    /// @dev only in case ETH gets stuck.
    function withdrawContractBalance() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    // solhint-disable-next-line function-max-lines
    function submitTask(
        uint256 _selfProviderGasLimit,
        uint256 _selfProviderGasPriceCeil
    ) external onlyOwner {
        Provider memory provider =
            Provider({
                addr: address(this),
                module: IGelatoProviderModule(this)
            });

        Action memory action =
            Action({
                addr: address(this),
                data: abi.encodeWithSelector(this.cheapAction.selector),
                operation: Operation.Call,
                dataFlow: DataFlow.None,
                value: 0,
                termsOkCheck: false
            });

        Action[] memory actions = new Action[](1);
        actions[0] = action;

        Task memory task =
            Task({
                conditions: new Condition[](0),
                actions: actions,
                selfProviderGasLimit: _selfProviderGasLimit,
                selfProviderGasPriceCeil: _selfProviderGasPriceCeil
            });

        try
            IGelatoCore(gelatoCore).submitTask(provider, task, 0)
        {} catch Error(string memory error) {
            revert(
                string("MockCheapTask.submitTask.submitTask:").suffix(error)
            );
        } catch {
            revert("MockCheapTask.submitTask.submitTask:undefined");
        }
    }

    /// @dev this is what we pay for during execution
    function cheapAction() external {}

    function multiProvide(
        address _executor,
        IGelatoProviderModule[] calldata _modules
    ) external payable onlyOwner {
        try
            IGelatoProviders(gelatoCore).multiProvide{value: msg.value}(
                _executor,
                new TaskSpec[](0),
                _modules
            )
        {} catch Error(string memory error) {
            revert(string("MockCheapTask.multiProvide:").suffix(error));
        } catch {
            revert("MockCheapTask.multiProvide:undefined");
        }
    }

    function unprovideFunds(uint256 _amount) external onlyOwner {
        try IGelatoProviders(gelatoCore).unprovideFunds(_amount) returns (
            uint256 withdrawAmount
        ) {
            payable(msg.sender).sendValue(withdrawAmount);
        } catch Error(string memory error) {
            revert(string("MockCheapTask.unprovideFunds:").suffix(error));
        } catch {
            revert("MockCheapTask.unprovideFunds:undefined");
        }
    }

    function provideFunds() public payable {
        try
            IGelatoProviders(gelatoCore).provideFunds{value: msg.value}(
                address(this)
            )
        {} catch Error(string memory error) {
            revert(string("MockCheapTask.provideFunds:").suffix(error));
        } catch {
            revert("MockCheapTask.provideFunds:undefined");
        }
    }
}
