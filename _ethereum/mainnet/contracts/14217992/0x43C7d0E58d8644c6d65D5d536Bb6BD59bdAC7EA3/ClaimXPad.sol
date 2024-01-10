// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "Pausable.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";


contract ClaimXPad is Pausable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    // staking rewards need to be signed!
    address signer;
    IERC20 public sb;
    IERC20 public xpad;

    mapping (uint32 => bool) nonces;

    event Claimed(address indexed who, uint256 sbAmount, uint256 xpadAmount);

    constructor(address _signer, IERC20 _sb, IERC20 _xpad) {
        signer = _signer;
        sb = _sb;
        xpad = _xpad;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _exchange(uint256 extra) nonReentrant whenNotPaused private {
        require(extra >= 0, "extra must be >= 0");
        address me = address(this);
        uint256 sbAmount = sb.balanceOf(_msgSender());
        uint256 ownSbBalance = sb.balanceOf(me);

        if (sbAmount > 0) {
            require(sb.transferFrom(_msgSender(), me, sbAmount), "SuperBid transfer failed");
        }

        // safety check to ensure we got all SB tokens
        require(sb.balanceOf(me) == ownSbBalance + sbAmount, "ClaimXPad: did not receive all tokens");

        // and transfer XPADs
        uint256 xpadAmount = sbAmount + extra;
        require(xpadAmount > 0, "Unnecessary exchange attempt: no rewards and no tokens to exchange");
        require(xpad.balanceOf(me) >= xpadAmount, "Not enough XPad left in contract");
        require(xpad.transfer(_msgSender(), xpadAmount), "XPad transfer failed");

        emit Claimed(_msgSender(), sbAmount, xpadAmount);
    }

    // This can be used by anyone to exchange tokens
    function exchange() external {
        _exchange(0);
    }

    function _useNonce(uint32 nonce) private {
        require(!nonces[nonce], "Attempted to re-use signature!");
        nonces[nonce] = true;
    }

    function isNonceUsed(uint32 nonce) public view returns(bool) {
        return nonces[nonce];
    }

    // This is used by staking panel to do the exchange together with staking rewards
    function exchangeWithRewards(uint256 stakingRewards, uint32 nonce, bytes memory signature) external {
        require(stakingRewards >= 0, "stakingRewards must be >= 0");

        // We need to use nonces to ensure that no one reuses the signature.
        _useNonce(nonce);

        bytes32 hashed = keccak256(abi.encode(
            // chainid is needed to make sure signatures won't be reused across chains
            block.chainid,
            // msg sender is needed to ensure no one will be able to use someone else's signature
            _msgSender(),
            // nonce is needed to protect from reply attacks
            nonce,
            // this is needed to make sure you can't set rewards yourself :)
            stakingRewards
        ));

         (address _signedBy,) = hashed.tryRecover(signature);
        require(_signedBy == signer, "invalid-signature");

        _exchange(stakingRewards);
    }

    // ability to withdraw remaining XPad tokens
    function withdraw(uint256 amount) onlyOwner public {
        uint256 finalAmount = amount > 0 ? amount : xpad.balanceOf(address(this));
        require(xpad.transfer(_msgSender(), finalAmount), "Transfer failed");
    }
}
