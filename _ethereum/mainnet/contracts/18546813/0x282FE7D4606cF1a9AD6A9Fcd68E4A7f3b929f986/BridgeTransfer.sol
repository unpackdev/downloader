// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Counters.sol";

abstract contract BridgeTransfer {
    // Strange layout to use less storage slots (3 instead of 4/5)
    struct TeleportInfo {
        uint64 timestamp;
        address from;
        uint64 nonce;
        address to;
        uint256 amount;
    }

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // The token to teleport.
    IERC20 public immutable token;
    // The minimum amount of tokens to teleport.
    uint256 public minTeleportAmount;
    // Nonce for teleporting tokens to the bridge contract.
    Counters.Counter private _teleportNonce;
    // Nonces for claiming tokens from the bridge contract.
    mapping(uint256 => bool) public processedNonces;
    // Teleport info for each teleport.
    mapping(uint256 => TeleportInfo) public teleports;

    event Teleport(address indexed from, address indexed to, uint amount, uint indexed nonce);
    event Claimed(address indexed from, address indexed to, uint amount, uint indexed nonce);
    event MinTeleportAmountChanged(address changer, uint amount);

    constructor(address _token) {
        require(_token != address(0), "Bridge: token address is zero");
        token = IERC20(_token);
    }

    /**
     * @dev Returns the current teleport nonce.
     */
    function nonce() public view returns (uint) {
        return _teleportNonce.current();
    }

    /**
     * @dev Teleports tokens from the user to the bridge contract.
     * @param from The address of the user who will send the tokens.
     * @param to The address of the user who will receive the tokens.
     * @param amount The amount of tokens to teleport.
     */
    function _teleport(address from, address to, uint amount) internal {
        uint256 currentNonce = _teleportNonce.current();

        emit Teleport(from, to, amount, currentNonce);

        teleports[currentNonce] = TeleportInfo({
            timestamp: uint64(block.timestamp),
            from: from,
            nonce: uint64(currentNonce),
            to: to,
            amount: amount
        });

        token.safeTransferFrom(from, to, amount);

        _teleportNonce.increment();
    }

    /**
     * @dev Claims tokens from the bridge contract.
     * @param to The address of the user who will receive the tokens.
     * @param amount The amount of tokens to claim.
     * @param otherChainNonce The nonce of the teleport on the other chain.
     */
    function _claim(address to, uint amount, uint otherChainNonce) internal {
        require(!processedNonces[otherChainNonce], "Bridge: nonce already processed");
        processedNonces[otherChainNonce] = true;

        token.safeTransfer(to, amount);

        emit Claimed(address(this), to, amount, otherChainNonce);
    }

    /**
     * @dev Changes the minimum amount of tokens to teleport.
     * @param amount The minimum amount of tokens to teleport.
     */
    function _setMinTeleportAmount(uint256 amount) internal {
        ERC20 _token = ERC20(address(token));
        uint256 _minTeleportAmount = amount * (10 ** _token.decimals());
        emit MinTeleportAmountChanged(msg.sender, _minTeleportAmount);
        minTeleportAmount = _minTeleportAmount;
    }
}
