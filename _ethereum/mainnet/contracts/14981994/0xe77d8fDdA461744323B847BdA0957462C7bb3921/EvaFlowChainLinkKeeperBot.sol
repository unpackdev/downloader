//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./KeeperRegistryInterface.sol";
import "./KeeperCompatibleInterface.sol";
import "./EvaKeepBotBase.sol";
import "./IEvabaseConfig.sol";
import "./IEvaFlowChecker.sol";
import "./IEvaFlowController.sol";
import "./IEvaFlow.sol";
import "./Ownable.sol";
import "./EvabaseHelper.sol";

contract EvaFlowChainLinkKeeperBot is EvaKeepBotBase, KeeperCompatibleInterface, Ownable {
    uint256 public lastMoveTime;

    address private immutable _keeperRegistry;

    event SetEvaCheck(address indexed evaCheck);

    constructor(
        address config_,
        address evaFlowChecker_,
        address keeperRegistry_
    ) {
        require(config_ != address(0), "addess is 0x");
        require(evaFlowChecker_ != address(0), "addess is 0x");
        require(keeperRegistry_ != address(0), "addess is 0x");

        config = IEvabaseConfig(config_);
        evaFlowChecker = IEvaFlowChecker(evaFlowChecker_);
        _keeperRegistry = keeperRegistry_;
        lastMoveTime = block.timestamp; // solhint-disable
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (upkeepNeeded, performData) = _check(checkData);
    }

    function performUpkeep(bytes calldata performData) external override {
        //Removal of pre-execution by chainlink keeper
        // solhint-disable avoid-tx-origin
        if (tx.origin == address(0)) {
            return; // return if call from chainlink keeper
        }
        _exec(performData);
    }

    function _check(bytes memory _checkdata) internal override returns (bool needExec, bytes memory execdata) {
        uint32 keepBotId = abi.decode(_checkdata, (uint32));
        (needExec, execdata) = evaFlowChecker.check(keepBotId, lastMoveTime, KeepNetWork.ChainLink);
    }

    function _exec(bytes memory execdata) internal override {
        require(msg.sender == _keeperRegistry, "only for keeperRegistry");
        lastMoveTime = block.timestamp; // solhint-disable
        IEvaFlowController(config.control()).batchExecFlow(tx.origin, execdata);
    }

    function setEvaCheck(IEvaFlowChecker evaFlowChecker_) external onlyOwner {
        require(address(evaFlowChecker_) != address(0), "addess is 0x");
        evaFlowChecker = evaFlowChecker_;
        emit SetEvaCheck(address(evaFlowChecker_));
    }
}
