// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
//
// accounts which own the sharedVault in proportion to their weight, max totalShares is 1000
// owner can add accounts with share weight, but can't change no accounts nor weight.
// accounts allowed to change them self only.
// only owner can without tokens, but only on behalf of the all accounts.
//
contract SharedVault is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    address[] public accounts;
    uint256[] public shares;
    uint256 totalShares;
    uint maxShares;
    uint256 constant MAX_NUMBER_ACCOUNTS = 50;

    constructor (IERC20 _token, uint256 _maxShares) public {
        token = _token;
        maxShares = _maxShares;
    }

    function numberAccounts() public view returns(uint256) {
        return accounts.length;
    }

    function getIndex(address account) public view returns (uint256) {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == account) return i;
        }
        revert("Not account found");
    }

    function addAccounts(address[] memory _accounts, uint256[] memory _shares) public onlyOwner {
        require(_accounts.length == _shares.length);
        require( (accounts.length + _accounts.length) <= MAX_NUMBER_ACCOUNTS,
            "Total number of account limit exceeded");
        for (uint256 i = 0; i < _accounts.length; i++) {
            accounts.push(_accounts[i]);
            shares.push(_shares[i]);
            totalShares = totalShares.add(_shares[i]);
        }
        require(totalShares <= maxShares, "Total amount of shared exceeded");
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(amount <= token.balanceOf(address(this)), "Not enough tokens");
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amountForI = (amount.mul(shares[i])).div(totalShares);
            token.transfer(accounts[i], amountForI);
        }
    }

    function withdrawAll() public onlyOwner {
        withdraw(token.balanceOf(address(this)));
    }

    function changeAccount(uint256 accountId, address newAccount) public {
        require(msg.sender == accounts[accountId], "Only account can change themselves");
        accounts[accountId] = newAccount;
    }
}
