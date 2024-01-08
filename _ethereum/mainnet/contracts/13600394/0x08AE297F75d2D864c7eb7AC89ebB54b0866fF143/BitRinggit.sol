// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract BitRinggit is Ownable {
    using ECDSA for bytes32;

    struct WithdrawRequest {
        address account;
        uint256 userId;
        uint256 amount;
    }

    IERC20 public token;
    address internal _signer;
    mapping(uint256 => WithdrawRequest) public withdrawals;

    event DepositEvent(address _address, uint256 _userId, uint256 _amount);
    event WithdrawalEvent(address _address, uint256 _userId, uint256 _amount, uint256 _nonce);

    constructor(address _token) Ownable() {
        token = IERC20(_token);
    }

    function deposit(uint256 _userId, uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
        emit DepositEvent(msg.sender, _userId, _amount);
    }

    function withdraw(
        uint256 _userId,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public {
        require(withdrawals[_nonce].account == address(0), "Invalid Nonce");
        bytes32 hash =
            keccak256(abi.encodePacked(_userId, msg.sender, _amount, _nonce));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        require(
            messageHash.recover(_signature) == _signer,
            "Invalid Signature"
        );
        token.transfer(msg.sender, _amount);
        emit WithdrawalEvent(msg.sender, _userId, _amount, _nonce);
        withdrawals[_nonce].account = msg.sender;
        withdrawals[_nonce].amount = _amount;
        withdrawals[_nonce].userId = _userId;
    }

    function setSigner(address _newSigner) public onlyOwner {
        _signer = _newSigner;
    }

    function signer() public view returns (address) {
        return _signer;
    }
}
