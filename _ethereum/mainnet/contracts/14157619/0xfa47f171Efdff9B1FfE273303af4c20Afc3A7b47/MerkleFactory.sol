pragma solidity 0.8.10;

import "./Merkle.sol";
import "./MerkleClaim.sol";
import "./CloneFactory.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract MerkleFactory is Initializable, OwnableUpgradeable {
    address public baseMerkle;
    address public claimMerkle;
    Merkle[] public baseMerkles;
    MerkleClaim[] public claimMerkles;

    CloneFactory public cloneFactory;

    event BaseMerkleCreated(address merkle);
    event ClaimMerkleCreated(address merkle);

    function initialize(address _baseMerkle, address _claimMerkle) public initializer {
        baseMerkle = _baseMerkle;
        claimMerkle = _claimMerkle;
        __Ownable_init();
    }

    function createBaseMerkle(bytes32 root) public returns (Merkle) {
        Merkle merkle = Merkle(
            cloneFactory.createClone(baseMerkle)            
        );        
        merkle.initialize(root, msg.sender);
        baseMerkles.push(merkle);
        emit BaseMerkleCreated(address(merkle));
        return merkle;
    }

    function createClaimMerkle(bytes32 root) public returns (MerkleClaim) {
        MerkleClaim merkle = MerkleClaim(
            cloneFactory.createClone(claimMerkle)            
        );        
        merkle.initialize(root, msg.sender);
        claimMerkles.push(merkle);
        emit ClaimMerkleCreated(address(merkle));
        return merkle;
    }

    function updateBaseMerkle(address _merkle) external onlyOwner {
        baseMerkle = _merkle;
    }

    function updateClaimMerkle(address _merkle) external onlyOwner {
        claimMerkle = _merkle;
    }

    function updateCloneFactory(CloneFactory _clone) external onlyOwner {
        cloneFactory = _clone;
    }
}
