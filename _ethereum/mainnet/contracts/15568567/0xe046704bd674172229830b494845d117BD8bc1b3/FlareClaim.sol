//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract FlareClaim is 
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 private _root;
    mapping (address => bool) private _claimed;

    function initialize(bytes32 root_) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _root = root_;
        _pause();
    }

    receive() external payable {}

    function claim(uint256 amount_, bytes32[] calldata proof_) external whenNotPaused nonReentrant {
        require(isVerified(msg.sender, amount_, proof_), "Not valid proof");
        require(!claimed(msg.sender), "Already claimed");
        _claimed[msg.sender] = true;

        AddressUpgradeable.sendValue(payable (msg.sender), amount_);
    }

    function withdraw() external onlyOwner {
        AddressUpgradeable.sendValue(payable (owner()), address(this).balance);
    }

    function isVerified(address to_, uint256 amount_, bytes32[] calldata proof_) public view returns (bool) {
        return MerkleProofUpgradeable.verifyCalldata(proof_, _root, keccak256(abi.encodePacked(amount_, to_)));
    }

    function claimed(address to_) public view returns (bool) {
        return _claimed[to_];
    }

    function root() public view returns (bytes32) {
        return _root;
    }

    function setRoot(bytes32 root_) external onlyOwner {
        _root = root_;
    }    

    function togglePause(bool value_) external onlyOwner {
        if(value_) _pause();
        else _unpause();
    }
}