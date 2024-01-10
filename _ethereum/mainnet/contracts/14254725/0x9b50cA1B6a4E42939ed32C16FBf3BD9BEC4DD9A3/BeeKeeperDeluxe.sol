// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./HoneyHiveDeluxeI.sol";
import "./HoneyTokenI.sol";
import "./HoneyCombsDeluxeI.sol";

/**
 * @title BeeKeeperDeluxe Contract
 * @notice BeeKeeperDelux is a smart contract that does handle the generation of the HoneyCombs
 * @dev This contract is upgradable and ownable
 */
contract BeeKeeperDeluxe is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC1155HolderUpgradeable {
    HoneyCombsDeluxeI public honeyCombs;
    HoneyHiveDeluxeI public hives;
    HoneyTokenI public honey;

    /**
     * @notice claimed combs per hive with a maximum of 2
     */
    // solhint-disable-next-line
    mapping(uint16 => uint8) claimedCombsPerHive;

    /**
     * @notice how much honey needs to be burnt per rarity of combs when claiming
     */
    mapping(HONEY_COMB_RARITY => uint256) public honeyAmountPerCombRarity;

    bytes32 public merkleRoot;

    event MerkleRootChanged(bytes32 _newMerkleRoot);
    event ClaimedHoneyComb(address indexed _owner, uint256 _hiveId, HONEY_COMB_RARITY _rarity, uint8 _quantity);
    event SetContract(string indexed _contract, address _target);
    event TokenRecovered(address indexed _token, address _destination, uint256 _amount);

    constructor() {} //solhint-disable

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC1155Holder_init();

        honeyAmountPerCombRarity[HONEY_COMB_RARITY.COMMON] = 100 * 1e17;
        honeyAmountPerCombRarity[HONEY_COMB_RARITY.UNCOMMON] = 175 * 1e17;
        honeyAmountPerCombRarity[HONEY_COMB_RARITY.RARE] = 250 * 1e17;
        honeyAmountPerCombRarity[HONEY_COMB_RARITY.EPIC] = 325 * 1e17;
        honeyAmountPerCombRarity[HONEY_COMB_RARITY.LEGENDARY] = 400 * 1e17;
    }

    /**
     * @notice Claim HoneyComb by owning a hive. You can claim 2 HoneyCombs per Hive.
     * @dev Every hive can claim 2 honeycombs. So if a user has multiple hives for a certain rarity.
     *      we can mint them multiple combs at once for gas efficiency.
     *      The _hivesIds contains all the ids that needs to be claimed
     *      the leafs/_merkleProofs contains the leafs/merkleProofs corresponding with each hiveId
     *      (e.g. hiveIds[1] has to have the corresponding
     *      leaf at leafs[1] and corresponding proofs at _merkleProofs[1])
     *      All the hiveIds has to have the same rarity in order for this to work.
     * @param _hiveIds the hive ids
     * @param _rarity The rarity of the honey comb given by rarity of the hive
     * @param _quantities The quantity of combs we want to claim for each hiveId
     * @param _leafs leafs from merkle tree
     * @param _merkleProofs proofs that these leafs are valid with the _hiveIds and _rarity
     */
    function claimHoneyComb(
        uint16[] calldata _hiveIds,
        uint8[] memory _quantities,
        HONEY_COMB_RARITY _rarity,
        bytes32[] calldata _leafs,
        bytes32[][] calldata _merkleProofs
    ) external nonReentrant {
        uint256 amountOfHoney;
        uint256 amountOfCombs;
        require(_hiveIds.length == _quantities.length, "Invalid quantities");
        for (uint256 i; i < _hiveIds.length; i++) {
            uint16 _hiveId = _hiveIds[i];

            require(keccak256(abi.encodePacked(_hiveId, _rarity)) == _leafs[i], "Leaf not matching the node");
            require(MerkleProof.verify(_merkleProofs[i], merkleRoot, _leafs[i]), "Invalid proof");

            uint8 claimedCount = claimedCombsPerHive[_hiveId];
            if (claimedCount >= 2 || hives.ownerOf(_hiveId) != msg.sender || _quantities[i] == 0) continue;
            uint8 quantity = _quantities[i];
            if (claimedCount + quantity > 2) quantity = 2 - claimedCount;

            amountOfCombs += quantity;
            claimedCombsPerHive[_hiveId] = claimedCount + quantity;
            amountOfHoney += honeyAmountPerCombRarity[_rarity] * quantity;

            require(honey.balanceOf(msg.sender) >= amountOfHoney, "Not enough Honey");
            emit ClaimedHoneyComb(msg.sender, _hiveId, _rarity, quantity);
        }
        require(amountOfHoney > 0, "Nothing to claim");
        honey.burn(msg.sender, amountOfHoney);
        honeyCombs.safeTransferFrom(address(this), msg.sender, uint256(_rarity), amountOfCombs, "");
    }

    function getClaimedCombsPerHive(uint16 _hiveId) external view returns (uint8) {
        return claimedCombsPerHive[_hiveId];
    }

    /**
     * @notice sets the merkle root for claiming verifications
     * @param _merkleRoot merkle root that it will define the merkle tree for claiming
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @notice sets the honey combs contract
     * @param _contract the contract of the honey combs
     */
    function setHoneyCombs(address _contract) external onlyOwner {
        require(_contract != address(0), "!address(0)");
        honeyCombs = HoneyCombsDeluxeI(_contract);
        emit SetContract("HoneyCombs", _contract);
    }

    /**
     * @notice sets the hives contract
     * @param _contract the contract of the honey combs
     */
    function setHives(address _contract) external onlyOwner {
        require(_contract != address(0), "!address(0)");
        hives = HoneyHiveDeluxeI(_contract);
        emit SetContract("HivesDeluxe", _contract);
    }

    /**
     * @notice sets the honey token contract
     * @param _contract the contract of the honey combs
     */
    function setHoney(address _contract) external onlyOwner {
        require(_contract != address(0), "!address(0)");
        honey = HoneyTokenI(_contract);
        emit SetContract("HoneyDeluxe", _contract);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        require(msg.sender == address(honeyCombs), "!UNAUTHORIZED");
        return super.onERC1155Received(operator, from, id, value, data);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public override returns (bytes4) {
        require(msg.sender == address(honeyCombs), "!UNAUTHORIZED");
        return super.onERC1155BatchReceived(operator, from, ids, values, data);
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     */
    function recoverNFT(
        address _nft,
        address _destination,
        uint256 _tokenId
    ) external onlyOwner {
        require(_destination != address(0), "!address(0)");
        IERC721(_nft).safeTransferFrom(address(this), _destination, _tokenId);
        emit TokenRecovered(_nft, _destination, _tokenId);
    }

    /**
     * @notice Recover NFT sent by mistake to the contract
     * @param _nft the 1155 NFT address
     * @param _destination where to send the NFT
     * @param _tokenId the token to want to recover
     * @param _amount amount of this token to want to recover
     */
    function recover1155NFT(
        address _nft,
        address _destination,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyOwner {
        require(_destination != address(0), "!address(0)");
        IERC1155(_nft).safeTransferFrom(address(this), _destination, _tokenId, _amount, "");
        emit TokenRecovered(_nft, _destination, _tokenId);
    }

    /**
     * @notice Recover TOKENS sent by mistake to the contract
     * @param _token the TOKEN address
     * @param _destination where to send the NFT
     */
    function recoverERC20(address _token, address _destination) external onlyOwner {
        require(_destination != address(0), "!address(0)");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_destination, amount);
        emit TokenRecovered(_token, _destination, amount);
    }
}
