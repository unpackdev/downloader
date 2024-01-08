// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./RecoverableFunds.sol";
import "./ICallbackContract.sol";
import "./WithCallback.sol";

/**
 * @dev CandaoToken
 */
contract CandaoToken is ERC20, ERC20Burnable, Pausable, RecoverableFunds, WithCallback {

    mapping(address => bool) public unpausable;

    modifier notPaused(address account) {
        require(!paused() || unpausable[account], "Pausable: paused");
        _;
    }

    constructor(string memory name, string memory symbol, address[] memory initialAccounts, uint256[] memory initialBalances) payable ERC20(name, symbol) {
        for(uint8 i = 0; i < initialAccounts.length; i++) {
            _mint(initialAccounts[i], initialBalances[i]);
        }
    }

    function addToWhitelist(address[] memory accounts) public onlyOwner {
        for(uint8 i = 0; i < accounts.length; i++) {
            unpausable[accounts[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory accounts) public onlyOwner {
        for(uint8 i = 0; i < accounts.length; i++) {
            unpausable[accounts[i]] = false;
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _burnCallback(account, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);
        _transferCallback(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override notPaused(from) {
        super._beforeTokenTransfer(from, to, amount);
    }

}
