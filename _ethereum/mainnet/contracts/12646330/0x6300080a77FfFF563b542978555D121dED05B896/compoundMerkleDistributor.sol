// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./compoundResolver.sol";

interface IndexInterface {
    function master() external view returns (address);
}

interface InstaListInterface {
    function accountID(address) external view returns (uint64);
}

interface InstaAccountInterface {
    function version() external view returns (uint256);
}

contract InstaCompoundMerkleDistributor is InstaCompoundMerkleResolver, Ownable {
    event Claimed(
        uint256 indexed index,
        address indexed dsa,
        address account,
        uint256 claimedRewardAmount,
        uint256 claimedNetworthsAmount
    );

    address public constant token = 0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb;
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    InstaListInterface public constant instaList = 
        InstaListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(bytes32 merkleRoot_, address _owner) public {
        merkleRoot = merkleRoot_;
        transferOwnership(_owner);
    }

    /**
     * @dev Throws if the sender not is Master Address from InstaIndex or owner
    */
    modifier isOwner {
        require(_msgSender() == IndexInterface(instaIndex).master() || owner() == _msgSender(), "caller is not the owner or master");
        _;
    }

    modifier isDSA {
        require(instaList.accountID(msg.sender) != 0, "InstaCompoundMerkleDistributor:: not a DSA wallet");
        require(InstaAccountInterface(msg.sender).version() == 2, "InstaCompoundMerkleDistributor:: not a DSAv2 wallet");
        _;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] calldata merkleProof,
        address[] memory supplyCtokens,
        address[] memory borrowCtokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) 
        external
        isDSA
    {
        require(!isClaimed(index), 'InstaCompoundMerkleDistributor: Drop already claimed.');
        require(supplyCtokens.length > 0, "InstaCompoundMerkleDistributor: Address length not vaild");
        require(supplyCtokens.length == supplyAmounts.length, "InstaCompoundMerkleDistributor: supply addresses and amounts doesn't match");
        require(borrowCtokens.length == borrowAmounts.length, "InstaCompoundMerkleDistributor: borrow addresses and amounts doesn't match");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, rewardAmount, networthAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'InstaCompoundMerkleDistributor: Invalid proof.');

        // Calculate claimable amount
        (uint256 claimableRewardAmount, uint256 claimableNetworth) = getPosition(
            networthAmount,
            rewardAmount,
            supplyCtokens,
            borrowCtokens,
            supplyAmounts,
            borrowAmounts
        );

        require(claimableRewardAmount > 0 && claimableNetworth > 0, "InstaCompoundMerkleDistributor: claimable amounts not vaild");
        require(rewardAmount >= claimableRewardAmount, 'InstaCompoundMerkleDistributor: claimableRewardAmount more then reward.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(msg.sender, claimableRewardAmount), 'InstaCompoundMerkleDistributor: Transfer failed.');

        emit Claimed(index, msg.sender, account, claimableRewardAmount, claimableNetworth);
    }

    function spell(address _target, bytes memory _data) public isOwner {
        require(_target != address(0), "target-invalid");
        assembly {
        let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
        switch iszero(succeeded)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}