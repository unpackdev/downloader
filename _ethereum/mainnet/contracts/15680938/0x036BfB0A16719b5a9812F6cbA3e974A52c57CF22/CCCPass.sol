// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./draft-EIP712.sol";
import "./Ownable.sol";

contract CCCPass is EIP712, Ownable {
    // EIP712 Feature
    bytes32 public constant TYPEHASH =
        keccak256("PassReq(address receiver,uint256 amount)");

    struct PassReq {
        address receiver;
        uint256 amount;
    }

    mapping(address => uint256) public claimedCount;

    bool public paused = true;
    string public baseURI;
    address public cccStore;

    event Paused();
    event Unpaused();
    event ClaimPass(address claimer, uint256 amount);

    constructor(
        string memory __name
    ) EIP712(__name, "1") {
    }

    function setCCCStore(address _cccStore) external onlyOwner {
        cccStore = _cccStore;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function claimPass(
        address sender,
        uint256 _passAmount,
        uint256 _amountToMint,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external {
        require(msg.sender == cccStore, "Not cccStore");
        require(paused == false, "Claims paused");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, sender, _passAmount))
        );
        address signer = ecrecover(digest, vSig, rSig, sSig);
        require(signer == owner(), "Signature not owner");       

        require(_passAmount - claimedCount[sender] >= _amountToMint, "Not enough pass");

        claimedCount[sender] += _amountToMint;
        emit ClaimPass(sender, _amountToMint);
    }
}