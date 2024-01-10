pragma solidity 0.8.11;
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract MerkleQuantity is Ownable {
    bytes32 private root;

    constructor(bytes32 _root) {
        root = _root;
    }

    function leaf(
        address account, 
        uint256 count
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    count,
                    account
                )
            );
    }

    function isPermitted(address account, uint256 count, bytes32[] memory proof) external view returns (bool) {
        return verify(leaf(account, count), proof);
    }

    function verify(bytes32 _leaf, bytes32[] memory proof)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, root, _leaf);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }
}
