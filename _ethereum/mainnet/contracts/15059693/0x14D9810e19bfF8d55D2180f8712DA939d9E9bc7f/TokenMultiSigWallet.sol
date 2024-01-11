// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./MultiSigWallet.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokenMultiSigWallet is MultiSigWallet {
    using SafeERC20 for IERC20;

    event NotifyDeposit(
        address indexed caller,
        address indexed token,
        uint256 _amount,
        uint256 _balance
    );
    event SubmitTransfer(
        address indexed owner,
        uint256 indexed transferId,
        address token,
        address to,
        uint256 amount
    );
    event ApproveTransfer(address indexed owner, uint256 indexed transferId);
    event ExecuteTransfer(address indexed owner, uint256 indexed transferId);
    event RevokeApproval(address indexed owner, uint256 indexed transferId);

    /// Name assigned to this contract 
    string public name;

    error ZeroTransferAmount();
    error InsufficientBalance(uint256 amount, uint256 balance);
    error InvalidCaller();

    modifier onlyThis() {
        if (msg.sender != address(this)) revert InvalidCaller();
        _;
    }

    constructor (
        address[] memory _admin,
        address[] memory _owners,
        uint256 _numAdminConfirmationsRequired,
        uint256 _numConfirmationsRequired,
        string memory _name
    ) 
        MultiSigWallet(
            _admin, 
            _owners, 
            _numAdminConfirmationsRequired,
            _numConfirmationsRequired
        )
    {
        name = _name;
    }

    /// Should be called as a courtesy after _amount of _token is sent to this contract
    function notifyDeposit(address _token, uint256 _amount) external {
        emit NotifyDeposit(msg.sender, _token, _amount, getBalance(_token));
    }

    /// Submit request to transfer _amount of _token from contract to _to
    function submitTransfer(address _token, address _to, uint256 _amount) external {
        if (_to == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroTransferAmount();
        uint256 balance = getBalance(_token);
        if (_amount > balance) revert InsufficientBalance(_amount, balance);

        submitTransaction(address(this), 0, _getTransferData(_token, _to, _amount)); 

        uint256 transferId = getTransactionCount() - 1;
        emit SubmitTransfer(msg.sender, transferId, _token, _to, _amount);
    }

    /// Approve transfer request on _transferId
    function approveTransfer(uint256 _transferId) external {
        confirmTransaction(_transferId);
        emit ApproveTransfer(msg.sender, _transferId);
    }

    /// Execute the transfer of _transferId
    function executeTransfer(uint256 _transferId) external {
        executeTransaction(_transferId);
        emit ExecuteTransfer(msg.sender, _transferId);
    }

    /// Revoke approval to transfer _transferId
    function revokeApproval(uint256 _transferId) external {
        revokeConfirmation(_transferId);
        emit RevokeApproval(msg.sender, _transferId);
    }

    /// Return this contract's _token balance
    function getBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) revert ZeroAddress();
        return IERC20(_token).balanceOf(address(this));
    }

    // Called as a template for encoding the transaction
    // Visibility is public so that it's callable but access is restricted to multiSigWallet
    function _transfer(address _token, address _to, uint256 _amount) public onlyThis {
        IERC20(_token).safeTransfer(_to, _amount);
    }

    // Called to generate the data to transfer _amount of _token to _to
    function _getTransferData(address _token, address _to, uint256 _amount) 
        private 
        pure 
        returns 
        (bytes memory) 
    {
        return abi.encodeWithSignature("_transfer(address,address,uint256)", _token, _to, _amount);    
    }
}
