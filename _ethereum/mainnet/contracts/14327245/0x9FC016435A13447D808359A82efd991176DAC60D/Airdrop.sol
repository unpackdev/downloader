// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "Pausable.sol";
import "Ownable.sol";
import "ECDSA.sol";
import "IERC20.sol";
import "ReentrancyGuard.sol";


contract MetaFabricAirdrop is Pausable, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    // withdrawals need to be signed
    address public signer;
    // signing salt for higher security
    bytes32 public salt;
    // keep track of withdrawals so it's impossible to withdraw the same money twice
    mapping (uint128 => bool) withdrawalIds;
    // token managed by the contract
    IERC20 public token;

    event Withdrawn(address indexed by, uint128 withdrawalId, uint256 amount);

    constructor(IERC20 _token, address _signer, bytes32 _salt) {
        token = _token;
        salt = _salt;
        setSigner(_signer);
    }

    function setSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0));
        signer = _newSigner;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw(uint256 _amount, uint128 _withdrawalId, uint256 _deadline, bytes memory _signature) public nonReentrant whenNotPaused {
        require(_amount > 0, "Amount must be > 0");
        // make sure that no-one can double spend
        require(!withdrawalIds[_withdrawalId], "Attempted the same withdrawal twice!");
        require(_deadline >= block.timestamp, "Past deadline");
        withdrawalIds[_withdrawalId] = true;

        bytes32 hashed = keccak256(abi.encode(
            // salt is used in case we are signing more things with the same key
            salt,
            // chainid is needed to make sure signatures won't be reused across chains
            block.chainid,
            // same as with salt - prevent accidental signature reuse
            address(this),
            // id is needed to protect from reply attacks so it acts as a nonce
            _withdrawalId,
            // needed so the signatures are not valid for eternity
            _deadline,
            // msg sender is needed to ensure no one will be able to use someone else's signature
            // (by front-running transaction for example)
            _msgSender(),
            // this is needed to make sure you can't set amount yourself :)
            _amount
        ));

        (address _signedBy,) = hashed.tryRecover(_signature);
        require(_signedBy == signer, "invalid-signature");

        uint256 reserves = token.balanceOf(address(this));
        require(reserves >= _amount, "Not enough token reserves");

        bool success = token.transfer(_msgSender(), _amount);
        require(success, "transfer failed");

        emit Withdrawn(_msgSender(), _withdrawalId, _amount);
    }

    function isWithdrawn(uint128 _id) public view returns (bool) {
        return withdrawalIds[_id];
    }

    // this contract is funded from MetaFabric marketing treasury so we can withdraw
    // the outstanding tokens if airdrop ends / we upgrade the contract etc.
    function withdrawAll(uint256 _amount) onlyOwner external {
        uint256 finalAmount = _amount > 0 ? _amount : token.balanceOf(address(this));
        require(token.transfer(_msgSender(), finalAmount), "Transfer failed");
    }
}
