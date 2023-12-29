// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Ownable.sol";
import "./ECDSA.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract TipPool is Ownable {
    using ECDSA for bytes32;

    address public withdrawalSigner;

    bool public withdrawalsEnabled = false;

    mapping(address => uint256) public withdrawalIndex;

    mapping(address => uint256) public userDeposits;

    mapping(address => uint256) public userWithdrawals;

    event Deposit(address indexed user, uint256 indexed value);

    event Withdrawal(address indexed user, uint256 indexed value, uint256 indexed expiry);

    constructor(address _withdrawalSigner) {
        withdrawalSigner = _withdrawalSigner;
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }

    function _verifyWithdrawal(
        uint256 index,
        uint256 expiresAt,
        uint256 amount,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(index, expiresAt, msg.sender, amount)
        );
        bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(
            messageHash
        );
        address recoveredAddress = ECDSA.recover(
            ethSignedMessageHash,
            signature
        );
        require(recoveredAddress != address(0));
        return recoveredAddress == withdrawalSigner;
    }

    function depositETH() external payable {
        require(msg.value > 0, "Value must be greater than zero");
        userDeposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawETH(
        uint256 _index,
        uint256 _expiry,
        uint256 _amount,
        bytes memory _signature
    ) external {
        require(withdrawalsEnabled);
        require(withdrawalIndex[msg.sender] == _index);
        require(block.timestamp < _expiry);
        require(_verifyWithdrawal(_index, _expiry, _amount, _signature));
        withdrawalIndex[msg.sender]++;
        userWithdrawals[msg.sender] += _amount;
        (bool sent, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");
        require(sent, "Failed to transfer ether");
        emit Withdrawal(msg.sender, _amount, _expiry);
    }

    function recoverETH(uint256 _amount) external onlyOwner {
        (bool sent, bytes memory data) = payable(msg.sender).call{
            value: _amount
        }("");
        require(sent, "Failed to transfer ether");
    }

    function recoverToken(uint256 _amount, address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
    }

    function setWithdrawalSigner(address _signer) external onlyOwner {
        withdrawalSigner = _signer;
    }

    function toggleWithdrawal() external onlyOwner {
        withdrawalsEnabled = !withdrawalsEnabled;
    }

    receive() external payable {
        require(msg.value > 0, "Value must be greater than zero");
        userDeposits[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}
