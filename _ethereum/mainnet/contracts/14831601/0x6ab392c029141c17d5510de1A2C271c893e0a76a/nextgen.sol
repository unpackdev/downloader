/*
    In order to buy this token during the first few minutes you need to whitelist yourself calling the function letMeIn in our contract. 
    This has been done to avoid bots and snipers.
*/


//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC1155.sol";

contract NextGenerationLabsToken is ERC20, Ownable {
    bool private _enableGateKeeper;
    bool private _tradingEnabled;
    bool private _enableTransactionLimit;
    uint256 private _gateKeeperMaxTokenAmount;
    address private _deployer;
    mapping(address => uint256) private _lastBuyBlock;
    mapping(address => bool) private whitelisted;

    constructor()
    ERC20("Next Generation Labs", "NEXTGEN") {
        _deployer = msg.sender;
        _mint(msg.sender, 1_000_000_000_000 ether);
        _enableGateKeeper = true;
        _tradingEnabled = false;
        _enableTransactionLimit = true;
    }

    function isTradingEnabled() public view returns (bool) {
        return _tradingEnabled;
    }

    function isGateKeeperEnabled() public view returns (bool) {
        return _enableGateKeeper && _gateKeeperMaxTokenAmount != 0;
    }

    function isGateKeeperPermanentlyDisabled() public view returns (bool) {
        return !_enableGateKeeper;
    }

    function enableTrading() public onlyOwner {
        _tradingEnabled = true;
    }

    function permanentlyDisableTransactionLimit() public onlyOwner {
        _enableTransactionLimit = false;
    }

    function permanentlyDisarmUniswapGateKeeper() public onlyOwner {
        _enableGateKeeper = false;
    }

    function setupGateKeeper(uint256 maxTokenAmount) public onlyOwner {
        _gateKeeperMaxTokenAmount = maxTokenAmount;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(_tradingEnabled || from == _deployer || to == _deployer, "Trading is not enabled yet. Refer to our Website or Twitter for further information.");

        if (!isGateKeeperEnabled()) {
            // Once gatekeeper is disabled, we are just a vanilla ERC20 token
            return;
        }

        // Buying from DEX and transfers between wallets requires being whitelisted
        require(whitelisted[to], "Buy blocked by gatekeeper. Target wallet didn't completed our whitelist steps. Refer to our Website or Twitter for further information. This restriction will be lifted in a few minutes.");

        if (_enableTransactionLimit) {
            require(amount <= _gateKeeperMaxTokenAmount * (1 ether), "Buy blocked by gatekeeper. Token limit per transaction exceeded. Refer to our Website or Twitter for further information. This restriction will be lifted in a few minutes.");
            require(_lastBuyBlock[to] < block.number, "Buy blocked by gatekeeper. You can only buy once per block. Refer to our Website or Twitter for further information. This restriction will be lifted in a few hours.");

            _lastBuyBlock[to] = block.number;
        }
    }

    function letMeIn() external {
        require(!whitelisted[msg.sender], "You're already whitelisted. Refer to our Website or Twitter for further information.");
        whitelisted[msg.sender] = true;
    }
}