// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./SafeERC20.sol";

contract Promotion is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public signer;
    address public feeReceiver;

    event PromotionSuccess(uint256 package, uint256 promotionChainId, address promotionToken, uint256 promotionId, address sender);

    constructor(address _signer, address _feeReceiver) {
        require(_feeReceiver != address(0), "Cannot set zero address");
        signer = _signer;
        feeReceiver = _feeReceiver;
    }

    function promote(uint256 package, address token, uint256 amount, uint256 promotionChainId, address promotionToken, uint256 promotionId, uint256 deadline, bytes calldata signature) external payable nonReentrant {
        require(signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(block.chainid, _msgSender(), address(this), package, token, amount, promotionChainId, promotionToken, promotionId, deadline))), signature), "Invalid signature");
        require(deadline >= block.timestamp, "Deadline passed");
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value == amount, "Wrong payment amount");
            payable(feeReceiver).transfer(msg.value);
        }
        else {
            require(msg.value == 0, "Cannot send native currency while paying with token");
            IERC20(token).safeTransferFrom(_msgSender(), feeReceiver, amount);
        }
        emit PromotionSuccess(package, promotionChainId, promotionToken, promotionId, _msgSender());
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Cannot set zero address");
        feeReceiver = _feeReceiver;
    }
}