// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./console.sol";
import "./MultiSigWallet.sol";

contract Team is AccessControl, Ownable {
    bool private aApprove;
    bool private bApprove;
    bool private cApprove;
    address private a;
    address private b;
    address private c;
    string public name;

    constructor(
        address _b,
        address _c,
        string memory _name
    ) {
        a = msg.sender;
        b = _b;
        c = _c;
        name = _name;
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier threshold() {
        require(msg.sender == a || msg.sender == b || msg.sender == c, "not owner");
        require((aApprove && bApprove) || (aApprove && cApprove) || (bApprove && cApprove), "not authorized");
        aApprove = false;
        bApprove = false;
        cApprove = false;
        _;
    }

    function setA(address _a) external threshold {
        a = _a;
    }

    function setB(address _b) external threshold {
        b = _b;
    }

    function setC(address _c) external threshold {
        c = _c;
    }

    function approveA(bool boo) external {
        require(msg.sender == a, "not owner");
        aApprove = boo;
    }

    function approveB(bool boo) external {
        require(msg.sender == b, "not owner");
        bApprove = boo;
    }

    function approveC(bool boo) external {
        require(msg.sender == c, "not owner");
        cApprove = boo;
    }

    function withdraw() external payable threshold {
        payable(msg.sender).transfer(address(this).balance);
    }

    function transfer(address erc20TokenAddress, uint256 amount) external threshold {
        require(amount > 0, "amount must more than 0!");
        require(address(erc20TokenAddress).balance > amount, "erc20Token balance is too low!");

        ERC20 erc20Contract = ERC20(erc20TokenAddress);
        bool success = erc20Contract.transfer(msg.sender, amount);

        require(success, "failed to transfer token");
    }
}
