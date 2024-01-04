// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Approvable.sol";

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * CosmoFund Contract
 * https://CosmoFund.space/
 */
contract CosmoFund is Approvable {
    using SafeMath for uint256;

    string private _url;

    struct Transfer {
        uint256 id;
        bool executed;
        address token;
        uint256 amount;
        address payable to;
        uint256 approvalsWeight;
    }
    Transfer[] private _transfers;
    mapping(address => mapping(uint256 => bool)) private _approvalsTransfer;

    event NewTransfer(uint256 indexed id, address indexed token, uint256 amount, address indexed to);
    event VoteForTransfer(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event Transferred(uint256 indexed id, address indexed token, uint256 amount, address indexed to);

    constructor(uint256 weight, uint256 threshold) public {
        _setupApprover(_msgSender(), weight);
        _setupThreshold(threshold);
        _setURL("https://CosmoFund.space/");
    }

    function url() public view returns (string memory) {
        return _url;
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function balanceERC20(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }


    // Transfer
    function transfersCount() public view returns (uint256) {
        return _transfers.length;
    }

    function getTransfer(uint256 id) public view returns (Transfer memory) {
        return _transfers[id];
    }

    function createTransferETH(uint256 amount, address payable to) public onlyApprover returns (uint256) {
        uint256 id = _addNewTransfer(address(0), amount, to);
        _voteForTransfer(id);
        return id;
    }

    function createTransferERC20(address token, uint256 amount, address payable to) public onlyApprover returns (uint256) {
        uint256 id = _addNewTransfer(token, amount, to);
        _voteForTransfer(id);
        return id;
    }

    function approveTransfer(uint256 id) public onlyApprover returns (bool) {
        require(_transfers[id].executed == false, "CosmoFund: Transfer has already executed");
        require(_approvalsTransfer[_msgSender()][id] == false, "CosmoFund: Cannot approve transfer twice");
        return _voteForTransfer(id);
    }

    function executeTransfer(uint256 id) public onlyApprover returns (bool) {
        require(_transfers[id].executed == false, "CosmoFund: Transfer has already executed");
        require(_transfers[id].approvalsWeight >= getThreshold(), "CosmoFund: Insufficient approvals weight");
        return _executeTransfer(id);
    }

    function _addNewTransfer(address token, uint256 amount, address payable to) private returns (uint256) {
        require(to != address(0), "CosmoFund: to is the zero address");
        uint256 id = _transfers.length;
        _transfers.push(Transfer(id, false, token, amount, to, 0));
        emit NewTransfer(id, token, amount, to);
        return id;
    }

    function _voteForTransfer(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsTransfer[msgSender][id] = true;
        _transfers[id].approvalsWeight = _transfers[id].approvalsWeight.add(getApproverWeight(msgSender));
        emit VoteForTransfer(id, msgSender, getApproverWeight(msgSender), _transfers[id].approvalsWeight);
        if (_transfers[id].approvalsWeight >= getThreshold())
            _executeTransfer(id);
        return true;
    }

    function _executeTransfer(uint256 id) private returns (bool) {
        if (_transfers[id].token == address(0))
            require(_executeTransferETH(id), "CosmoFund: Failed to transfer ETH");
        else
            require(_executeTransferERC20(id), "CosmoFund: Failed to transfer ERC20");
        _transfers[id].executed = true;
        emit Transferred(_transfers[id].id, _transfers[id].token, _transfers[id].amount, _transfers[id].to);
        return true;
    }

    function _executeTransferETH(uint256 id) private returns (bool) {
        return _transfers[id].to.send(_transfers[id].amount);
    }

    function _executeTransferERC20(uint256 id) private returns (bool) {
        return IERC20(_transfers[id].token).transfer(_transfers[id].to, _transfers[id].amount);
    }

    function setURL(string memory newUrl) public onlyApprover {
        _setURL(newUrl);
    }

    function _setURL(string memory newUrl) private {
        _url = newUrl;
    }
    
    receive() external payable {}
}
