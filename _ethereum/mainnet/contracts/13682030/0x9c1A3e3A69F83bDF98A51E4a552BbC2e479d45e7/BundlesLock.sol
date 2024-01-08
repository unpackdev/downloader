//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./NativeMetaTransaction.sol";

contract BundlesLock is ReentrancyGuard, NativeMetaTransaction {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    event Lock(address indexed user, uint256 amount);
    event Release(address indexed user, uint256 amount, string indexed burnTxHash);
    mapping(string => bool) public burnTxHashes;

    constructor(IERC20 _token) {
        _initializeEIP712("BundlesLock", "1");
        token = _token;
    }

    function lockTokens(uint256 amount) external nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit Lock(msg.sender, amount);
    }

    function releaseTokens(address user, uint256 amount, string memory burnTxHash) external onlyOwner nonReentrant {
        require(burnTxHashes[burnTxHash] == false, "Burn Tx Hash already exists");
        burnTxHashes[burnTxHash] = true;
        token.safeTransfer(user, amount);
        emit Release(user, amount, burnTxHash);
    }
}