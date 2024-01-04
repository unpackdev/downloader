// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "./IOptionsManager.sol";
import "./IOptionsPool.sol";
import "./ICapitalManager.sol";

import "./Ownable.sol";
import "./SafeMath.sol";

contract OptionsManager is IOptionsManager, Ownable {
    using SafeMath for uint;
    IOptionsPool public optionsPool;
    ICapitalManager public capitalManager;

    mapping(address => bool) public frontContracts;
    mapping(address => bool) public portfolioManagers;

    bool public stopChanges;

    constructor(IOptionsPool oPool, ICapitalManager cManager) public {
        optionsPool = oPool;
        _setCapitalManager(cManager);
        _setPortfolioManager(msg.sender, true);
    }

    receive() external payable {}

    function stopChangesForever() external onlyOwner {
        stopChanges = true;
    }

    function setFrontContract(address fc, bool approved) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        _setFrontContract(fc, approved);
    }

    function setPortfolioManager(address pm, bool approved) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        _setPortfolioManager(pm, approved);
    }

    function setCapitalManager(ICapitalManager cm) external onlyOwner {
        require(!stopChanges, "!stopChanges");
        _setCapitalManager(cm);
    }

    function depositOption(address from, uint tokenId, uint premium) external override onlyFrontContract {
        // transfer option to pool
        optionsPool.takeOptionFrom(from, tokenId);
        optionsPool.depositOption(tokenId, premium);
    }

    function withdrawOption(address to, uint tokenId) external override onlyFrontContract {
        // transfer option out of pool
        optionsPool.sendOptionTo(to, tokenId);
    }

    function exerciseOption(uint tokenId) external override onlyPortfolioManager {
        uint gas = gasleft();
        IOptionsPool op = optionsPool;
        ICapitalManager cm = capitalManager;
        uint profit = op.exerciseOption(tokenId);
        uint paidPremium = op.paidPremiums(tokenId);
        cm.receivePayout{value: profit}(address(op), tokenId, paidPremium, profit, false);
        op.unlockOption(tokenId);
        uint refund = gas.sub(gasleft()).mul(tx.gasprice).mul(125).div(100);
        require(refund < profit, "2ndary::OptionsManager::not-profitable-exercise");
        cm.refundGas(msg.sender, refund);
    }

    function unlockOption(uint tokenId) external override {
        uint paidPremium = optionsPool.paidPremiums(tokenId);
        require(paidPremium > 0 && !optionsPool.isActiveOption(tokenId), "2ndary::OptionsManager::is-not-locked");
        optionsPool.unlockOption(tokenId);        
        capitalManager.unlockBalance(tokenId, paidPremium);
    }

    function _setCapitalManager(ICapitalManager cm) internal {
        capitalManager = cm;
    }

    function _setFrontContract(address fc, bool approved) internal {
        frontContracts[fc] = approved;
    }

    function _setPortfolioManager(address pm, bool approved) internal {
        portfolioManagers[pm] = approved;
    }

    modifier onlyFrontContract {
        require(frontContracts[msg.sender], "2ndary::OptionsManager::not-allowed");
        _;
    }

    modifier onlyPortfolioManager {
        require(portfolioManagers[msg.sender], "2ndary::OptionsManager::not-allowed");
        _;
    }
}