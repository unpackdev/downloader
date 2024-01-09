// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "ERC721.sol";
import "Ownable.sol";
import "Pausable.sol";
import "ReentrancyGuard.sol";
import "ECDSA.sol";
import "Address.sol";
import "IToken.sol";
import "IHandleRegistry.sol";


contract SigController is Ownable, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;
    using Address for address payable;

    // This is token which will be burned when making a reservation.
    IToken token;
    // This is the NFT registry we will be calling.
    IHandleRegistry registry;
    // Requests must be signed. We are using a server which handles all this and
    // prevents front-running. We could use commit/reveal pattern, but that increases
    // number of transactions, which sucks and we don't need to do that for now.
    // This address is public address of the key which needs to sign request for
    // it to be valid.
    address signer;
    address payable ethReceiver;

    constructor(
        IToken _token,
        IHandleRegistry _registry,
        address _signer,
        address payable _ethReceiver
    ) {
        token = _token;
        registry = _registry;
        signer = _signer;
        ethReceiver = _ethReceiver;
    }

    // This function is for making reservations.
    // It takes the following parameters:
    //   - handle: the handle we want
    //   - toBurn: amount of tokens to burn
    //   - p_*: EIP-2612 signature which authorizes transfer/burn of `toBurn` amount of tokens
    //   - signature: ECDSA signature which authorizes this call
    function mint(
        string memory handle,
        uint256 toBurn,
        uint256 ethCost,
        uint256 p_deadline,
        uint8 p_v,
        bytes32 p_r,
        bytes32 p_s,
        bytes memory signature
    ) external payable whenNotPaused nonReentrant {
        require(msg.value >= ethCost, "SigController: not-enough-ether");
        address sender = _msgSender();

        bytes32 hashed = keccak256(abi.encode(
            // use this to prevent any reply attacks from testnets (not that we would use the same key!)
            block.chainid,
            // we need to encode sender in the sig to prevent front running
            sender,
            // we also need to make sure that the right amount is burned
            toBurn,
            // and the right amount of eth cost
            ethCost,
            // and at the end we include hashed handle, we don't simply use string
            // because it could make signature malleable (well, not if it's at the end but let's
            // do this for s3cur1ty).
            keccak256(bytes(handle))
        ));
        (address _signedBy,) = hashed.tryRecover(signature);
        require(_signedBy == signer, "invalid-signature");

        if (toBurn > 0) {
            token.permit(sender, address(this), toBurn, p_deadline, p_v, p_r, p_s);
            token.burnFrom(sender, toBurn);
        }

        if (ethCost > 0) {
            ethReceiver.sendValue(msg.value);
        }

        registry.mint(handle, sender);
    }

    // Pausing in case of an emergency
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    //
    function setEthReceiver(address payable _newReceiver) external onlyOwner {
        ethReceiver = _newReceiver;
    }

    function rotateSigner(address payable _newSigner) external onlyOwner {
        signer = _newSigner;
    }
}
