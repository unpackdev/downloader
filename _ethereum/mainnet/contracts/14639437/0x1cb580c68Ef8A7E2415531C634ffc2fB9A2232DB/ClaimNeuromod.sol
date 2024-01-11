//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

interface NeuromodI {
    function mintBatch(address _owner, uint16[] calldata _tokenIds) external;
}

contract ClaimNeuromod is Ownable, ReentrancyGuard {
    bytes32 public merkleRoot;

    NeuromodI public immutable neuromod;

    address public immutable dev;
    address public immutable vault;

    mapping(address => uint256) public claimedPerAccount;

    uint256 public constant MAX_PER_ACCOUNT_WL = 1;
    uint256 public constant MAX_PER_ACCOUNT_OG = 2;
    uint256 public constant MAX_PER_ACCOUNT_PUBLIC = 2;

    /**
     * @notice this is 50 because the first 50 are reserved for the Vault
     */
    uint256 public currentId = 50;

    uint256 public price = 0.08 ether;

    bool public pause;

    bool public publicSale;

    error Unauthorized();
    error InvalidProof();
    error WrongAmount();
    error Paused();
    error TooManyNfts(uint256 _type);

    event PriceChanged(uint256 _newPrice);
    event EnabledPublicSale(bool _enabled);
    event MerkleRootChanged(bytes32 _newMerkleRoot);
    event Claimed(address _user, uint256 _quantity);
    event PauseChanged(bool _paused);
    event MintedToVault(uint16[] ids);

    constructor(
        NeuromodI _neuromod,
        address _vault,
        address _dev
    ) {
        neuromod = _neuromod;
        vault = _vault;
        dev = _dev;
    }

    function mintToVault(uint16[] memory _mintedToVault) external onlyOwner {
        neuromod.mintBatch(vault, _mintedToVault);
        emit MintedToVault(_mintedToVault);
    }

    /**
     * @notice claiming based on whitelisted merkle tree
     * @dev every proof includes type and msg sender
     * @param _quantity how much you can claim, needs to be <= type (e.g. OG max allowed 2 so _amount must be < 2)
     * @param _type 1 = WL, 2 = OG
     * @param _merkleProof proof he is whitelisted
     */
    function claim(
        uint256 _quantity,
        uint256 _type,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        if (pause) revert Paused();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _type));

        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidProof();

        if (price * _quantity > msg.value) revert WrongAmount();
        if (_type == 1 && claimedPerAccount[msg.sender] + _quantity > MAX_PER_ACCOUNT_WL) revert TooManyNfts(1);
        else if (_type == 2 && claimedPerAccount[msg.sender] + _quantity > MAX_PER_ACCOUNT_OG) revert TooManyNfts(2);

        unchecked {
            claimedPerAccount[msg.sender] += _quantity;
            uint16[] memory ids = new uint16[](_quantity);
            uint256 i = 1;
            for (; i <= _quantity; i++) {
                ids[i - 1] = uint16(++currentId);
            }
            neuromod.mintBatch(msg.sender, ids);
        }

        emit Claimed(msg.sender, _quantity);
    }

    /**
     * @notice claim public lets everyone claim. The ones who claimed in the whitelisting phase, will count for already minted.
     * @notice e.g. if i minted 1 in whitelist phase, i can mint only 1 in public
     * @param _quantity how much i can claim, no more than 2
     */
    function claimPublic(uint256 _quantity) external payable nonReentrant {
        if (pause) revert Paused();
        if (!publicSale) revert Paused();

        if (price * _quantity > msg.value) revert WrongAmount();
        if (claimedPerAccount[msg.sender] + _quantity > MAX_PER_ACCOUNT_PUBLIC) revert TooManyNfts(3);

        unchecked {
            claimedPerAccount[msg.sender] += _quantity;
            uint16[] memory ids = new uint16[](_quantity);
            uint256 i = 1;
            for (; i <= _quantity; i++) {
                ids[i - 1] = uint16(++currentId);
            }
            neuromod.mintBatch(msg.sender, ids);
        }
        emit Claimed(msg.sender, _quantity);
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit PriceChanged(_newPrice);
    }

    function setPublicSale(bool _enabled) external onlyOwner {
        publicSale = _enabled;
        emit EnabledPublicSale(_enabled);
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit MerkleRootChanged(_newMerkleRoot);
    }

    function pauseUnpause(bool _newPause) external onlyOwner {
        pause = _newPause;
        emit PauseChanged(_newPause);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance * 100;
        uint256 toVault = (balance * 98) / 100;
        uint256 toDev = balance - toVault;

        (bool succeed, ) = vault.call{ value: toVault / 100 }("");
        require(succeed, "Failed to withdraw Ether");

        (succeed, ) = dev.call{ value: toDev / 100 }("");
        require(succeed, "Failed to withdraw Ether");
    }
}
