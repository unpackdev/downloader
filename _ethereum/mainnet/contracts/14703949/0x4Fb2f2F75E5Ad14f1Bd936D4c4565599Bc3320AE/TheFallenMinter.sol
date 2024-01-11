// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./OperatorAccess.sol";
import "./TheFallen.sol";
import "./IStaking.sol";

/**
 * @title TheFallen Minter
 * @notice TheFallen Minting Station
 */
contract TheFallenMinter is OperatorAccess, ReentrancyGuard {
    using SafeMath for uint256;

    uint8 public constant STATUS_NOT_INITIALIZED = 0;
    uint8 public constant STATUS_PREPARING = 1;
    uint8 public constant STATUS_CLAIM = 2;
    uint8 public constant STATUS_CLOSED = 3;

    uint8 public currentStatus = STATUS_NOT_INITIALIZED;

    uint256 public maxSupply;
    uint256 public availableSupply;

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    TheFallen public immutable nftCollection;

    address public immutable samuraiCollection;
    address public immutable samuraiStakingV1;
    address public immutable samuraiStakingV2;
    address public immutable onnaCollection;
    address public immutable onnaStaking;

    mapping(uint256 => uint256) private _tokenIdsCache;

    modifier whenClaimable() {
        require(currentStatus == STATUS_CLAIM, "Status not claim");
        _;
    }

    modifier whenMintOpened() {
        require(startTimestamp > 0, "Mint not configured");
        require(startTimestamp <= block.timestamp, "Mint not opened");
        require(endTimestamp == 0 || endTimestamp >= block.timestamp, "Mint closed");
        _;
    }

    modifier whenValidQuantity(uint256 _quantity) {
        require(availableSupply > 0, "No more supply");
        require(availableSupply >= _quantity, "Not enough supply");
        require(_quantity > 0, "Qty <= 0");
        _;
    }

    // modifier to allow execution by owner or operator
    modifier onlyOwnerOrOperator() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()),
            "Not an owner or operator"
        );
        _;
    }

    constructor(
        TheFallen _collection,
        address _samuraiCollection,
        address _samuraiStakingV1,
        address _samuraiStakingV2,
        address _onnaCollection,
        address _onnaStaking
    ) {
        nftCollection = _collection;
        samuraiCollection = _samuraiCollection;
        samuraiStakingV1 = _samuraiStakingV1;
        samuraiStakingV2 = _samuraiStakingV2;
        onnaCollection = _onnaCollection;
        onnaStaking = _onnaStaking;

        currentStatus = STATUS_PREPARING;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _syncSupply();
    }

    function _mint(
        address _to,
        uint256[] memory _linkedSamuraiIds,
        uint256[] memory _linkedOnnaIds
    ) internal returns (uint256[] memory) {
        uint256 quantity = _linkedSamuraiIds.length + _linkedOnnaIds.length;
        require(availableSupply >= quantity, "Not enough supply");

        uint256[] memory tokenIds = new uint256[](quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = getNextTokenId();
            availableSupply = availableSupply - 1;
            tokenIds[i] = tokenId;
        }

        if (quantity == 1) {
            if (_linkedSamuraiIds.length > 0) nftCollection.mint(_to, tokenIds[0], 0, _linkedSamuraiIds[0]);
            else nftCollection.mint(_to, tokenIds[0], 1, _linkedOnnaIds[0]);
        } else {
            nftCollection.mintBatch(_to, tokenIds, _linkedSamuraiIds, _linkedOnnaIds);
        }

        return tokenIds;
    }

    function _verifyOwner(
        address expected,
        address collection,
        uint256 tokenId
    ) internal view returns (bool) {
        address currentOwner = IERC721(collection).ownerOf(tokenId);

        if (currentOwner == samuraiStakingV2) {
            (currentOwner, , , ) = ISamuraiStaking(samuraiStakingV2).getStakeInfo(tokenId);
        } else if (currentOwner == samuraiStakingV1) {
            (currentOwner, , , ) = ISamuraiStaking(samuraiStakingV1).getStakeInfo(tokenId);
        } else if (currentOwner == onnaStaking) {
            (currentOwner, , , , ) = IOnnaStaking(onnaStaking).getStakeInfo(tokenId);
        }

        return currentOwner == expected;
    }

    /**
     * @dev mint NFTs and link them to original collections
     */
    function mint(uint256[] calldata _linkedSamuraiIds, uint256[] calldata _linkedOnnaIds)
        external
        nonReentrant
        whenValidQuantity(_linkedSamuraiIds.length + _linkedOnnaIds.length)
        whenClaimable
        whenMintOpened
    {
        address to = _msgSender();

        uint256 i;
        for (i = 0; i < _linkedSamuraiIds.length; i++) {
            require(_verifyOwner(to, samuraiCollection, _linkedSamuraiIds[i]), "Must be owner of linked samurai");
        }

        for (i = 0; i < _linkedOnnaIds.length; i++) {
            require(_verifyOwner(to, onnaCollection, _linkedOnnaIds[i]), "Must be owner of linked onna");
        }

        _mint(to, _linkedSamuraiIds, _linkedOnnaIds);
    }

    function setStatus(uint8 _status) external onlyOwnerOrOperator {
        currentStatus = _status;
    }

    function _syncSupply() internal {
        uint256 totalSupply = nftCollection.totalSupply();
        maxSupply = nftCollection.maxSupply();
        availableSupply = maxSupply - totalSupply;
    }

    function syncSupply() external onlyOwnerOrOperator {
        _syncSupply();
    }

    /**
     * @dev configure the round
     */
    function configure(uint256 _startTimestamp, uint256 _endTimestamp) external onlyOwnerOrOperator {
        require(_endTimestamp == 0 || _startTimestamp < _endTimestamp, "Invalid timestamps");
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }

    function _getNextRandomNumber() private returns (uint256 index) {
        require(availableSupply > 0, "Invalid _remaining");

        uint256 i = maxSupply.add(uint256(keccak256(abi.encode(block.difficulty, blockhash(block.number))))).mod(
            availableSupply
        );

        // if there's a cache at _tokenIdsCache[i] then use it
        // otherwise use i itself
        index = _tokenIdsCache[i] == 0 ? i : _tokenIdsCache[i];

        // grab a number from the tail
        _tokenIdsCache[i] = _tokenIdsCache[availableSupply - 1] == 0
            ? availableSupply - 1
            : _tokenIdsCache[availableSupply - 1];
    }

    function getNextTokenId() internal returns (uint256 index) {
        return _getNextRandomNumber() + 1;
    }
}
