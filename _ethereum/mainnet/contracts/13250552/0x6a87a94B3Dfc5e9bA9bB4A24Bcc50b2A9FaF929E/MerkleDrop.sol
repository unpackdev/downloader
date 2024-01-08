pragma solidity 0.7.6;

import "./MerkleProof.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";


/// @dev Contract for stakehouse testnet game reward distribution
contract MerkleDrop is Ownable, Pausable {
    /// @dev Merkle root for reward distribution tree
    bytes32 public ROOT;
    /// @dev Token address paid out as reward (cBSN)
    address public TOKEN_ADDRESS;

    /// @dev Tracks user claims to prevent double-claiming
    mapping(uint => mapping(address => bool)) public claims;

    uint public VERSION = 1;

    /// @dev Event indicating reward has been claimed
    event RewardClaim(
        address user,
        uint amount,
        uint version
    );

    /// @dev event to signal the new merkle version
    event MerkleUpdate(
        bytes32 newRoot,
        uint newVersion
    );

    constructor (address _tokenAddress, bytes32 _root) {
        require(_tokenAddress != address(0));
        require(_root != bytes32(0));

        ROOT = _root;
        TOKEN_ADDRESS = _tokenAddress;

        emit MerkleUpdate(_root, VERSION);
    }


    /// @dev redeem reward tokens by proving the user is part of the merkle tree
    /// @param _proof - Branch of the merkle tree to complete the proof on
    /// @param _amount - The amount to be claimed
    function redeem(bytes32[] calldata _proof, uint256 _amount) external whenNotPaused {
        address claimer = msg.sender;
        //Computing the hash of leaf
        bytes32 leaf = _leaf(_amount, claimer);

        require(!hasClaimed(claimer), 'User already claimed tokens');
        require(MerkleProof.verify(_proof, ROOT, leaf), 'User is not a part of airdrop list');

        //Set double spending prevention and transfer the tokens
        claims[VERSION][claimer] = true;
        IERC20(TOKEN_ADDRESS).transfer(claimer, _amount);

        emit RewardClaim(claimer, _amount, VERSION);
    }

    /// @dev Check if the user already claimed tokens
    /// @param _user - address of the claimer
    function hasClaimed(address _user) public view returns (bool claimed) {
        claimed = claims[VERSION][_user];
    }


    /// @dev get proof verification for testing
    /// @param _amount - amount to be claimed
    /// @param _claimer - address that will claim the amount
    /// @param _proof - proof that the data belongs to the merkletree
    function getProofVerification(uint256 _amount, address _claimer, bytes32[] memory _proof) public view returns (bool) {
        bytes32 leaf = _leaf(_amount, _claimer);
        return MerkleProof.verify(_proof, ROOT, leaf);
    }

    /// @dev Recover tokens in case of some emergency
    function recoverTokens() external onlyOwner {
      uint balance = IERC20(TOKEN_ADDRESS).balanceOf(address(this));
      IERC20(TOKEN_ADDRESS).transfer(owner(), balance);
    }

    /// @dev pause the smart contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev unpause the smart contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev change the root if needed
    /// @param _root - new root of the merkle tree for token distribution
    function changeRoot(bytes32 _root) external onlyOwner whenPaused {
        require(_root != bytes32(0), 'Setting root hash to 0 not allowed');
        VERSION += 1;
        ROOT = _root;

        emit MerkleUpdate(_root, VERSION);
    }

    /// @dev change the token address if needed
    /// @param _token - new ERC20 token address
    function changeTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), 'Setting address to 0 not allowed');
        TOKEN_ADDRESS = _token;
    }

    /// @dev Compute the leaf hash entry to the merkle tree
    /// @param _amount - Amount to be claimed
    /// @param _claimer - user claiming the reward
    function _leaf(uint256 _amount, address _claimer) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_amount, _claimer));
    }
}
