// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./WmbApp.sol";

// Cross Chain Token Pool for bitrock
contract CCPoolV3 is WmbApp, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public poolToken;

    // chain id => remote pool address
    mapping(uint => address) public remotePools;

    event CrossArrive(uint256 indexed fromChainId, address indexed from, address indexed to, uint256 amount, string crossType);
    event CrossRequest(uint256 indexed toChainId, address indexed from, address indexed to, uint256 amount);
    event CrossRevert(uint256 indexed fromChainId, address indexed from, address indexed to, uint256 amount);

    error RevertFailed (
        address from,
        address to,
        uint256 amount,
        uint256 fromChainId
    );

    constructor(address admin, address _wmbGateway, address _poolToken) WmbApp() {
        initialize(admin, _wmbGateway);
        poolToken = _poolToken;
    }

    function configRemotePool(uint256 chainId, address remotePool) public onlyRole(DEFAULT_ADMIN_ROLE) {
        remotePools[chainId] = remotePool;
    }

    function crossTo(uint256 toChainId, uint256 amount) public payable nonReentrant {
        require(remotePools[toChainId] != address(0), "remote pool not configured");
        IERC20(poolToken).safeTransferFrom(msg.sender, address(this), amount);
        uint fee = estimateFee(toChainId, 800_000);
        require(msg.value >= fee, "Insufficient fee");
        _dispatchMessage(toChainId, remotePools[toChainId], abi.encode(msg.sender, msg.sender, amount, "crossTo"), fee);
        emit CrossRequest(toChainId, msg.sender, msg.sender, amount);
    }

    // Transfer in enough native coin for fee. 
    receive() external payable {}

    function _wmbReceive(
        bytes calldata data,
        bytes32 /*messageId*/,
        uint256 fromChainId,
        address fromSC
    ) internal override {
        (address fromAccount, address to, uint256 amount, string memory crossType) = abi.decode(data, (address, address, uint256, string));
        if (IERC20(poolToken).balanceOf(address(this)) >= amount) {
            IERC20(poolToken).safeTransfer(to, amount);
            emit CrossArrive(fromChainId, fromAccount, to, amount, crossType);
        } else {
            if (keccak256(bytes(crossType)) == keccak256("crossTo")) {
                uint fee = estimateFee(fromChainId, 400_000);
                _dispatchMessage(fromChainId, fromSC, abi.encode(to, fromAccount, amount, "crossRevert"), fee);
                emit CrossRevert(fromChainId, fromAccount, to, amount);
            } else {
                revert RevertFailed(fromAccount, to, amount, fromChainId);
            }
        }
    }
}
