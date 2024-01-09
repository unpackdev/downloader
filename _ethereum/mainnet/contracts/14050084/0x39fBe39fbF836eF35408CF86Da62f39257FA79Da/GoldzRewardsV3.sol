// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./draft-EIP712.sol";
import "./Ownable.sol";

contract GoldzRewardsV3 is EIP712, Ownable {
    IERC20 goldz = IERC20(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);

    mapping(address => uint) public accountToNonce;
    mapping(address => uint) public accountToLastWithdrawTimestamp;
    mapping(address => uint) public accountToDepositedAmount;

    address _signerAddress;

    event Withdraw(uint amount, uint nonce, address receiver);
    
    constructor() EIP712("GoldzRewards", "3.0.0") {
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
    }

    function deposit(uint amount) external {
        require(amount > 0, "depositing 0 golds lol");

        goldz.transferFrom(msg.sender, address(this), amount);

        accountToDepositedAmount[msg.sender] += amount;
    }

    function depositedAmountOf(address userAddress) public view returns (uint) {
        return accountToDepositedAmount[userAddress];
    }

    function claim(uint amount, uint deadline, bytes calldata signature) external {
        require(amount > 0, "you have nothing to withdraw, do not lose your gas");
        require(_signerAddress == recoverAddress(msg.sender, amount, accountToNonce[msg.sender], deadline, signature), "invalid signature");
        require(deadline > block.timestamp, "signature expired");

        goldz.transfer(msg.sender, amount);

        emit Withdraw(amount, accountToNonce[msg.sender], msg.sender);

        accountToLastWithdrawTimestamp[msg.sender] = block.timestamp;
        accountToNonce[msg.sender]++;
    }

    function _hash(address account, uint amount, uint nonce, uint deadline) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Withdraw(uint256 amount,address account,uint256 nonce,uint256 deadline)"),
                        amount,
                        account,
                        nonce,
                        deadline
                    )
                )
            );
    }

    function recoverAddress(address account, uint amount, uint nonce, uint deadline, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, amount, nonce, deadline), signature);
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function withdrawGoldz() external onlyOwner {
        uint amount = goldz.balanceOf(address(this));
        goldz.transfer(msg.sender, amount);
    }

    function withdrawGoldz(uint amount) external onlyOwner {
        goldz.transfer(msg.sender, amount);
    }
}