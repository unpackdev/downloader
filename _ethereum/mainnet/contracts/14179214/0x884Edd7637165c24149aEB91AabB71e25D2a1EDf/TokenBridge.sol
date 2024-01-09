// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./SignerRole.sol";


contract TokenBridge is Ownable, SignerRole {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(bytes32 => bool) pays;

    constructor(address signer) {
        addSigner(signer);
    }

    struct SigData {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event NewDeposit(address indexed account, address indexed token, uint256 amount, uint256 toChain);
    event Withdraw(address indexed account, address indexed token, uint256 amount, uint256 fromChain, bytes32 message);

    modifier checkChain(uint256 chianid) {
        require(chianid != block.chainid);
        _;
    }

    function deposit(address token, uint256 amount, uint256 toChain) external checkChain(toChain) {
        uint256 currentBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        emit NewDeposit(msg.sender, token, newBalance.sub(currentBalance), toChain);
    }

    function withdraw(address token, uint256 amount, uint256 fromChain, bytes32 txhash, SigData calldata signature) external checkChain(fromChain) {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, msg.sender, token, amount, fromChain, block.chainid, txhash)));
        require(pays[message] != true, "Already Executed");
        require(isSigner(ecrecover(message, signature.v, signature.r, signature.s)), "sign error");
        IERC20(token).safeTransfer(msg.sender, amount);
        pays[message] = true;
        emit Withdraw(msg.sender, token, amount, fromChain, message);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
