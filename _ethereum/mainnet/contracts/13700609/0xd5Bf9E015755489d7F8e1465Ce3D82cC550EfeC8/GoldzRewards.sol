// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./draft-EIP712.sol";
import "./Ownable.sol";

contract GoldzRewards is EIP712, Ownable {
    IERC20 goldz = IERC20(0x7bE647634A942e73F8492d15Ae492D867Ce5245c);

    mapping(address => uint) public accountToNonce;
    mapping(address => uint) public accountToLastWithdrawTimestamp;

    address _signerAddress;

    event Withdraw(uint amount, uint nonce, address receiver);
    
    constructor() EIP712("GoldzRewards", "1.0.0") {
        _signerAddress = 0x42bC5465F5b5D4BAa633550e205A1d7D81e6cACf;
    }

    function claim(uint amount, bytes calldata signature) external {
        require(amount > 0, "you have nothing to withdraw, do not lose your gas");
        require(_signerAddress == recoverAddress(msg.sender, amount, accountToNonce[msg.sender], signature), "invalid signature");

        goldz.transfer(msg.sender, amount);

        emit Withdraw(amount, accountToNonce[msg.sender], msg.sender);

        accountToLastWithdrawTimestamp[msg.sender] = block.timestamp;
        accountToNonce[msg.sender]++;
    }

     function _hash(address account, uint amount, uint nonce) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("Withdraw(uint256 amount,address account,uint256 nonce)"),
                        amount,
                        account,
                        nonce
                    )
                )
            );
    }

    function recoverAddress(address account, uint amount, uint nonce, bytes calldata signature) public view returns(address) {
        return ECDSA.recover(_hash(account, amount, nonce), signature);
    }
    
    function setSignerAddress(address signerAddress) external onlyOwner {
        _signerAddress = signerAddress;
    }

    function withdrawGoldz() external onlyOwner {
        uint amount = goldz.balanceOf(address(this));
        goldz.transfer(msg.sender, amount);
    }
}

