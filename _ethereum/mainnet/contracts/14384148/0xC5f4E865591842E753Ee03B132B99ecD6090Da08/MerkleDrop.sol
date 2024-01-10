// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MerkleProof.sol";
import "./ERC721.sol";
import "./AccessControlEnumerable.sol";

import "./ICollectibles.sol";
import "./Collectibles.sol";

error MerkleSetterError();

contract MerkleDrop is AccessControlEnumerable {
    error MerkleProofError();
    error InvalidTokenTypeError();
    error OnlyMerkleSetterError();
    error OnlyAdminError();
    error OnlyClaimedSetterError();
    error InsufficientCollateralError();
    error MoreThanAllocatedError();
    error ClaimingMoreThanAllowedError();

    struct MerkleTree {
        bytes32 root;
        string ipfsHash; //to be able to fetch the merkle tree without relying on a centralized UI
    }

    address public collateralAddress;
    address public mintableAddress;
    mapping(address => uint256) internal _claimCount;

    MerkleTree public merkleTree;

    bytes32 public constant MERKLE_SETTER_ROLE = keccak256("MERKLE_SETTER_ROLE");
    bytes32 public constant CLAIMED_SETTER_ROLE = keccak256("CLAIMED_SETTER_ROLE");

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert OnlyAdminError();
        }
        _;
    }

    modifier onlyMerkleSetter() {
        if (!hasRole(MERKLE_SETTER_ROLE, msg.sender)) {
            revert OnlyMerkleSetterError();
        }
        _;
    }

       modifier onlyClaimedSetter() {
        if (!hasRole(CLAIMED_SETTER_ROLE, msg.sender)) {
            revert OnlyClaimedSetterError();
        }
        _;
    }

    event MerkleTreeUpdated(bytes32 indexed root, string ipfsHash);
    event CollectiblesClaimed(uint256 indexed collectedAmount, address indexed receiver);

    /// @notice Constructor
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateCollateralAddress(address _collateralAddress) external onlyAdmin {
        collateralAddress = _collateralAddress;
    }

    function updateMintableAddress(address _mintableAddress) external onlyAdmin {
        mintableAddress = _mintableAddress;
    }

    /// @notice returns the amount claimed by as user
    /// @param _claimerAddress address of claimer
    function getClaimCount(address _claimerAddress) external view returns (uint256) {
        return _claimCount[_claimerAddress];
    }

    /// @notice Updates the NFT drop merkle tree. Can only be called by the merkle setter
    /// @param _merkleRoot new merkleRoot
    /// @param _merkleIpfsHash IPFS hash of all leafs in the merkle tree
    function updateNFTMerkleTree(bytes32 _merkleRoot, string memory _merkleIpfsHash) external onlyMerkleSetter {
        merkleTree = MerkleTree({ root: _merkleRoot, ipfsHash: _merkleIpfsHash });

        emit MerkleTreeUpdated(_merkleRoot, _merkleIpfsHash);
    }

    /// @notice Updates the claimed amount for a given address.
    /// @param _receiver Address to be updated.
    /// @param _amount Claimed amount to set.
    function updateClaimedAmount(address _receiver, uint256 _amount) external onlyClaimedSetter {
        _claimCount[_receiver] = _amount;
    }

    /// @notice Claim an nft using the merkleProof
    /// @param _amountsOverride override the amounts given in the merkle tree
    /// @param _amounts amounts of tokens to claim, index denotes the NFT id
    /// @param _receiver Receiver of the NFT
    /// @param _proof merkle proof
    function claim(
        uint256[] calldata _amountsOverride,
        uint256[] calldata _amounts,
        address _receiver,
        bytes32[] calldata _proof
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(_amounts, _receiver));

        if (!MerkleProof.verify(_proof, merkleTree.root, leaf)) {
            revert MerkleProofError();
        }

        if (!_overrideIsValid(_amountsOverride, _amounts)) {
            revert MoreThanAllocatedError();
        }

        uint256 claimedAmount = _claimCount[_receiver];
        uint256 willingToMint = _getArraySum(_amountsOverride);

        _validateAmount(_receiver, _amounts, claimedAmount, willingToMint);

        Collectibles collectibles = Collectibles(mintableAddress);
        uint256[] memory mintableIds = _getMintableIds();

        _claimCount[_receiver] = claimedAmount + willingToMint;

        collectibles.mintBatch(mintableIds, _amountsOverride, _receiver);

        emit CollectiblesClaimed(willingToMint, _receiver);
    }

    function _validateAmount(
        address _receiver,
        uint256[] calldata _amounts,
        uint256 claimedAmount,
        uint256 willingToMint
    ) private view {
        uint256 maxAllowed = _getArraySum(_amounts);

        if ((claimedAmount + willingToMint) > maxAllowed) {
            revert ClaimingMoreThanAllowedError();
        }

        uint256 collateralBalance = _getCollateralBalance(_receiver);

        if ((claimedAmount + willingToMint) > collateralBalance) {
            revert InsufficientCollateralError();
        }
    }

    function _getCollateralBalance(address _receiver) private view returns (uint256) {
        ERC721 collateralNFT = ERC721(collateralAddress);

        return collateralNFT.balanceOf(_receiver);
    }

    function _overrideIsValid(uint256[] calldata _override, uint256[] calldata _initial) private view returns (bool) {
        if (_override[0] > _initial[0] || _override[1] > _initial[1] || _override[2] > _initial[2]) {
            return false;
        }

        return true;
    }

    function _getArraySum(uint256[] calldata array) private pure returns (uint256) {
        uint256 sum = 0;

        for (uint256 i = 0; i < array.length; i++) {
            sum = sum + array[i];
        }

        return sum;
    }

    function _getMintableIds() private pure returns (uint256[] memory) {
        uint256[] memory mintableIds = new uint256[](3);

        mintableIds[0] = uint256(0);
        mintableIds[1] = uint256(1);
        mintableIds[2] = uint256(2);

        return mintableIds;
    }
}
