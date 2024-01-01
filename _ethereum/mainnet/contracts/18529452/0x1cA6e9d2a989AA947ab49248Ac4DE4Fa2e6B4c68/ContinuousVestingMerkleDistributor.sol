// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Initializable.sol";
import "./IERC20.sol";

import "./ContinuousVestingInitializable.sol";
import "./MerkleSetInitializable.sol";

contract ContinuousVestingMerkleDistributor is Initializable, ContinuousVestingInitializable, MerkleSetInitializable {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 _token, // the token being claimed
        uint256 _total, // the total claimable by all users
        string memory _uri, // information on the sale (e.g. merkle proofs)
        uint256 _start, // vesting clock starts at this time
        uint256 _cliff, // claims open at this time
        uint256 _end, // vesting clock ends and this time
        bytes32 _merkleRoot, // the merkle root for claim membership (also used as salt for the fair queue delay time),
        uint160 _maxDelayTime, // the maximum delay time for the fair queue
        address _owner
    ) public initializer {
        __ContinuousVesting_init(
            _token, _total, _uri, _start, _cliff, _end, _maxDelayTime, uint160(uint256(_merkleRoot)), _owner
        );

        __MerkleSet_init(_merkleRoot);

        _transferOwnership(_owner);
    }

    function NAME() external pure override returns (string memory) {
        return "ContinuousVestingMerkleInitializable";
    }

    function VERSION() external pure override returns (uint256) {
        return 3;
    }

    function initializeDistributionRecord(
        uint256 index, // the beneficiary's index in the merkle root
        address beneficiary, // the address that will receive tokens
        uint256 amount, // the total claimable by this beneficiary
        bytes32[] calldata merkleProof
    ) external validMerkleProof(keccak256(abi.encodePacked(index, beneficiary, amount)), merkleProof) {
        _initializeDistributionRecord(beneficiary, amount);
    }

    function claim(
        uint256 index, // the beneficiary's index in the merkle root
        address beneficiary, // the address that will receive tokens
        uint256 totalAmount, // the total claimable by this beneficiary
        bytes32[] calldata merkleProof
    )
        external
        validMerkleProof(keccak256(abi.encodePacked(index, beneficiary, totalAmount)), merkleProof)
        nonReentrant
    {
        // effects
        uint256 claimedAmount = super._executeClaim(beneficiary, totalAmount);
        // interactions
        _settleClaim(beneficiary, claimedAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _setMerkleRoot(_merkleRoot);
    }
}
