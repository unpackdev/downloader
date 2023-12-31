// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IDABotManager.sol";
import "./IDABot.sol";
import "./IDABotGovernToken.sol";
import "./Errors.sol";
import "./Ownable.sol";
import "./IConfigurator.sol";
import "./IVoteStrategy.sol";

contract DABotVoteStrategy is IVoteStrategy {

    IDABotManager private _botManager;
    IBotVaultManager private _vaultManager;

    constructor(IDABotManager bm, IBotVaultManager vm) {
        _botManager = bm;
        _vaultManager = vm;
    }

    function snapshot(address target) external override { 
        _botManager.snapshot(target); 
    }

    function totalVotePower(address target, uint blockNo) external view override returns(uint) {
        IDABotGovernToken gToken = IDABotGovernToken(_dabot(target).governToken());
        return gToken.totalSupplyAt(blockNo); 
                
    }

    function votePower(address target, uint blockNo, address account) external view override returns(uint) {
        IDABotGovernToken gToken = IDABotGovernToken(_dabot(target).governToken());
        uint gVaultId = _vaultManager.vaultId(address(gToken), 1);
        return gToken.balanceOfAt(account, blockNo)
                + _vaultManager.balanceOfAt(gVaultId, account, blockNo)
                + _vaultManager.balanceOfAt(gVaultId + 1, account, blockNo);
    }

    function minPower(address target) external view override returns(uint) {
        IDABot bot = _dabot(target);
        return bot.readUint(Config.PROPOSAL_CREATOR_MININUM_POWER, 0);
    }

    function creationFee(address target) external view override returns(uint) {
        IDABot bot = _dabot(target);
        return bot.readUint(Config.PROPOSAL_DEPOSIT, 0);
    }

    function minQuorum(address target) external view override returns(uint) {
        IDABot bot = _dabot(target);
        return bot.readUint(Config.PROPOSAL_MINIMUM_QUORUM, 0);
    }

    function voteDifferential(address target) external view override returns(uint) {
        IDABot bot = _dabot(target);
        return bot.readUint(Config.PROPOSAL_VOTE_DIFFERENTIAL, 0);
    }

    function duration(address target) external view override returns(uint64) {
        IDABot bot = _dabot(target);
        return uint64(bot.readUint(Config.PROPOSAL_DURATION, 0));
    }

    function executionDelay(address target) external view override returns(uint64) {
        IDABot bot = _dabot(target);
        return uint64(bot.readUint(Config.PROPOSAL_EXECUTION_DELAY, 0));
    }

    function _dabot(address account) private view returns(IDABot) {
        require(_botManager.isRegisteredBot(account), Errors.BVS_NOT_A_REGISTERED_DABOT);
        return IDABot(account);
    }
}