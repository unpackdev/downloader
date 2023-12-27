// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./ERC1967Proxy.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721Receiver.sol";
import "./IERC721ReceiverUpgradeable.sol";

contract BookOfDestinyStakingProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}

contract BookOfDestinyStaking is
Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable,
OwnableUpgradeable, UUPSUpgradeable, IERC721ReceiverUpgradeable {
    uint256 public lockUtilBlockNumber;
    uint256 public stakeAmount;
    mapping(address => uint256) public stakeBalances;
    mapping(uint256 => address) public tokenIdToOwner;

    IERC721 private _nftContract;

    event Stake(address indexed addr, uint256 tokenId);
    event UnStake(address indexed addr, uint256 tokenId);

    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function initialize(uint256 _lockUtilBlockNumber, address nftContract_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        lockUtilBlockNumber = _lockUtilBlockNumber;
        _nftContract = IERC721(nftContract_);
    }

    function setLockUtilBlockNumber(uint256 blockNumber) external onlyOwner {
        require(blockNumber > block.number, "invalid block number");
        lockUtilBlockNumber = blockNumber;
    }

    function setNftContract(address nftContract_) external onlyOwner {
        require(nftContract_ != address(0), "invalid nft contract");
        _nftContract = IERC721(nftContract_);
    }

    function stake(uint256 tokenId) external whenNotPaused {
        require(tokenId > 0, "invalid token id");
        require(block.number < lockUtilBlockNumber, "staking is closed");
        require(tokenIdToOwner[tokenId] == address(0), "token already staked");
        require(_nftContract.ownerOf(tokenId) == msg.sender, "not owner");

        tokenIdToOwner[tokenId] = msg.sender;
        stakeBalances[msg.sender] += 1;
        stakeAmount += 1;

        emit Stake(msg.sender, tokenId);
        _nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
    }

    function unStake(uint256 tokenId) external whenNotPaused nonReentrant {
        require(tokenId > 0, "invalid token id");
        require(block.number >= lockUtilBlockNumber, "staking is locked yet");
        require(tokenIdToOwner[tokenId] != address(0), "token not stakeed");
        require(tokenIdToOwner[tokenId] == msg.sender, "not owner");

        delete tokenIdToOwner[tokenId];
        stakeBalances[msg.sender] -= 1;
        stakeAmount -= 1;

        emit UnStake(msg.sender, tokenId);
        _nftContract.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
}
