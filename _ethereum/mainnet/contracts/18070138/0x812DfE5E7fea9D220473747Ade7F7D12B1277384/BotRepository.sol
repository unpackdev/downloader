// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDABot.sol";

struct BotRepository {
    IDABot[] bots;
    mapping(address => uint) botIndex;   // mapping a bot's address to 1-based bot index
    mapping(bytes32 => uint) qfnIndex;   // mapping a bot's qualified name to 1-based bot index
}

library BotRepositoryLib {

    function indexOf(BotRepository storage repo, address bot) internal view returns(uint result) {
        result = repo.botIndex[bot];
        if (result > repo.bots.length)
            result = 0;
    }

    function indexOfQFN(BotRepository storage repo, string memory qualifiedName) internal view returns(uint result) {       
        result = repo.qfnIndex[keccak256(abi.encodePacked(qualifiedName))];
        if (result > repo.bots.length)
            result = 0;
    }

    function addBot(BotRepository storage repo, IDABot bot) internal {
        require(indexOf(repo, address(bot)) == 0, 'BotRepo: bot existed');
        repo.bots.push(bot);
        _updateBotIndex(repo, bot, repo.bots.length);
    }

    function removeBot(BotRepository storage repo, IDABot bot) internal {
        uint idx = indexOf(repo, address(bot));
        require(idx > 0, 'BotRepo: bot not found');
        idx--;  // convert 1-based to 0-based index
        uint lastIdx = repo.bots.length - 1;
        if (idx < lastIdx) {
            IDABot lastBot = repo.bots[lastIdx];
            repo.bots[idx] = lastBot;
            _updateBotIndex(repo, lastBot, idx);
        }
        repo.bots.pop();
    }

    function clear(BotRepository storage repo) internal {
        delete repo.bots;
    }

    function _updateBotIndex(BotRepository storage repo, IDABot bot, uint index) private {
        repo.botIndex[address(bot)] = index;
        repo.qfnIndex[keccak256(abi.encodePacked(bot.qualifiedName()))] = index;
    }
}