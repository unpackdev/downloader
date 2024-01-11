//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./SafeERC20.sol";

contract Split is Ownable {

    using SafeERC20 for IERC20;

    // The accounts to split the funds among
    address[] public accounts;

    // The split weightss
    uint256[] public percentages;

    // The total weight
    uint256 public total;

    /**
     * Creates the contract and sets the owner as the only recipient
     */
    constructor() {
        accounts.push(msg.sender);
        percentages.push(1);
        total = 1;
    }

    /**
     * Pays the configured accounts. The rounding error for ETH stays in this
     * contract. If the token is ERC20, the rounding error stays with msg.sender.
     */
    function pay(address _token, uint256 _amount) public payable {
        if (_token == address(0)) {
            for (uint256 i = 0; i < percentages.length; i++) {
                uint256 toTransfer = msg.value * percentages[i] / total;
                payable(accounts[i]).transfer(toTransfer);
                // the rounding error stays here
            }
        } else {
            for (uint256 i = 0; i < percentages.length; i++) {
                uint256 toTransfer = _amount * percentages[i] / total;
                IERC20(_token).safeTransferFrom(msg.sender, accounts[i], toTransfer);
                // msg.sender keeps the rounding errors
            }
        }
    }

    /**
     * Pays the configured accounts from its own balance. The rounding error
     * stays in this contract.
     */
    function payBalance(address _token, uint256 _amount) public {
        if (_token == address(0)) {
            for (uint256 i = 0; i < percentages.length; i++) {
                uint256 toTransfer = _amount * percentages[i] / total;
                payable(accounts[i]).transfer(toTransfer);
                // the rounding error stays here
            }
        } else {
            for (uint256 i = 0; i < percentages.length; i++) {
                uint256 toTransfer = _amount * percentages[i] / total;
                IERC20(_token).safeTransfer(accounts[i], toTransfer);
                // the rounding error stays here
            }
        }
    }

    /**
     * The contract is payable, so it can be used to receive and split 
     * royalties.
     */
    receive() external payable {}

    /**
     * Configures the payment recipients and split weights.
     */
    function setSplit(address[] calldata _accounts, uint256[] calldata _percentages) public onlyOwner {
        require(_accounts.length == _percentages.length, "Data length mismatch");
        require(_accounts.length > 0, "Configure at least one");
        accounts = _accounts;
        percentages = _percentages;
        uint256 newTotal = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            newTotal += _percentages[i];
        }
        total = newTotal;
    }

    /**
     * Removes this contract from the blockchain.
     */
    function kill() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}

