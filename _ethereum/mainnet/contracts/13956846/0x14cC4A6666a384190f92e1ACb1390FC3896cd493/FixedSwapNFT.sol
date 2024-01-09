// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Governable.sol";
import "./IERC1155.sol";
import "./NFTIndexer.sol";

contract FixedSwapNFT is Configurable, IERC721Receiver {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint    internal constant TypeErc721            = 0;
    uint    internal constant TypeErc1155           = 1;

    struct Pool {
        // address of pool creator
        address payable creator;
        // pool name
        string name;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // token id of token0
        uint tokenId;
        // total amount of token0
        uint amountTotal0;
        // total amount of token1
        uint amountTotal1;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // NFT token type
        uint nftType;
    }

    Pool[] public pools;

    // creator address => pool index + 1. if the result is 0, the account don't create any pool.
    mapping(address => uint) public myCreatedP;
    // name => pool index + 1
    mapping(string => uint) public myNameP;

    // pool index => a flag that if creator is claimed the pool
    mapping(uint => bool) public creatorClaimedP;
    mapping(uint => bool) public swappedP;

    // check if token0 in whitelist
    bool public checkToken0;
    // token0 address => true or false
    mapping(address => bool) public token0List;

    // pool index => swapped amount of token0
    mapping(uint => uint) public swappedAmount0P;
    // pool index => swapped amount of token1
    mapping(uint => uint) public swappedAmount1P;

    uint256 public fee;

    uint256 public feeMax;

    address payable public feeTo;

    address indexer; 

    // the timestamp in seconds the pool will start
    mapping(uint => uint) public startAt;

    mapping(uint => bool) public poolIsUnique;
    mapping(address => uint) public userLimited;

    // promo token list
    mapping(address => uint256) public promoTokenList;

    address public feeGovernor;

    event Created(address indexed sender, uint indexed index, Pool pool, uint startTime);
    event Swapped(address indexed sender, uint indexed index, uint amount0, uint amount1);
    event Claimed(address indexed sender, uint indexed index, uint amount0);

    function initialize(address _governor) public override initializer {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;
        feeMax = 10000;
    }

    function createErc721(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // total amount of token1
        uint amountTotal1,
        // duration time
        uint duration
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint amountTotal0 = 1;
        _create(
            name, token0, token1, tokenId, amountTotal0, amountTotal1,
            duration, TypeErc721, now, false
        );
    }

    function createErc721WithStartTime (
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // total amount of token1
        uint amountTotal1,
        // duration time
        uint duration,
        // start time
        uint startTime,
        // is unique
        bool isUnique
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        uint amountTotal0 = 1;
        _create(
            name, token0, token1, tokenId, amountTotal0, amountTotal1,
            duration, TypeErc721, startTime, isUnique
        );
    }

    function createErc1155(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // total amount of token0
        uint amountTotal0,
        // total amount of token1
        uint amountTotal1,
        // duration time
        uint duration
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        _create(
            name, token0, token1, tokenId, amountTotal0, amountTotal1,
            duration, TypeErc1155, now, false
        );
    }

    function createErc1155WithStartTime(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // total amount of token0
        uint amountTotal0,
        // total amount of token1
        uint amountTotal1,
        // duration time
        uint duration,
        // start time
        uint startTime,
        // is unique
        bool isUnique
    ) external payable {
        if (checkToken0) {
            require(token0List[token0], "invalid token0");
        }
        _create(
            name, token0, token1, tokenId, amountTotal0, amountTotal1,
            duration, TypeErc1155, startTime, isUnique
        );
    }

    function _create(
        string memory name,
        address token0,
        address token1,
        uint tokenId,
        uint amountTotal0,
        uint amountTotal1,
        uint duration,
        uint nftType,
        uint startTime,
        bool isUnique
    ) private
    {
        require(startTime > 0, "start time should not be zero");
        require(amountTotal1 != 0, "the value of amountTotal1 is zero.");
        require(duration != 0, "the value of duration is zero.");
        require(bytes(name).length <= 15, "the length of name is too long");

        uint closeTime = 0;
        if (startTime <= now) {
            closeTime = now.add(duration);
        } else {
            closeTime = startTime.add(duration);
        }

        // creator pool
        Pool memory pool;
        pool.creator = msg.sender;
        pool.name = name;
        pool.token0 = token0;
        pool.token1 = token1;
        pool.tokenId = tokenId;
        pool.amountTotal0 = amountTotal0;
        pool.amountTotal1 = amountTotal1;
        pool.closeAt = closeTime;
        pool.nftType = nftType;

        uint index = pools.length;

        pools.push(pool);
        startAt[index] = startTime;
        myCreatedP[msg.sender] = pools.length;
        myNameP[name] = pools.length;
        if (isUnique) {
            poolIsUnique[index] = true;
        }

        // transfer tokenId of token0 to this contract
        if (nftType == TypeErc721) {
            require(amountTotal0 == 1, "invalid amountTotal0");
            IERC721(token0).safeTransferFrom(msg.sender, address(this), tokenId);
            NFTIndexer(indexer).new721Fixswap(token0, tokenId, pools.length - 1);
        } else {
            require(amountTotal0 != 0, "invalid amountTotal0");
            IERC1155(token0).safeTransferFrom(msg.sender, address(this), tokenId, amountTotal0, "");
            NFTIndexer(indexer).new1155Fixswap(token0, pool.creator, tokenId, pools.length - 1);
        }

        emit Created(msg.sender, index, pool, startTime);
    }

    function swap(uint index, uint amount0) external payable
        isPoolExist(index)
        isPoolNotClosed(index)
        isPoolStarted(index)
        isAccountLimited(index, msg.sender)
    {
        Pool storage pool = pools[index];
        require(amount0 >= 1 && amount0 <= pool.amountTotal0, "invalid amount0");
        require(swappedAmount0P[index].add(amount0) <= pool.amountTotal0, "pool filled or invalid amount0");

        uint amount1 = amount0.mul(pool.amountTotal1).div(pool.amountTotal0);
        swappedAmount0P[index] = swappedAmount0P[index].add(amount0);
        swappedAmount1P[index] = swappedAmount1P[index].add(amount1);
        if (swappedAmount0P[index] == pool.amountTotal0) {
            // mark pool is swapped
            swappedP[index] = true;
        }
        uint256 swapFee = 0;
        if (feeTo != address(0) && fee > 0) {
            if (promoTokenList[pool.token1] != 0) {
                swapFee = amount1.mul(promoTokenList[pool.token1]).div(feeMax);
            } else {
                swapFee = amount1.mul(fee).div(feeMax);
            }
        }

        if (poolIsUnique[index]) {
            userLimited[msg.sender] = block.timestamp;
        }

        // transfer amount of token1 to creator
        if (pool.token1 == address(0)) {
            require(amount1 == msg.value, "invalid ETH amount");
            // transfer ETH to creator

            if (swapFee > 0) {
                feeTo.transfer(swapFee);
            }
            pool.creator.transfer(amount1.sub(swapFee));
        } else {
            IERC20(pool.token1).safeTransferFrom(msg.sender, pool.creator, amount1.sub(swapFee));
            if (swapFee > 0) {
                IERC20(pool.token1).safeTransferFrom(msg.sender, feeTo, swapFee);
            }
        }

        // transfer tokenId of token0 to sender
        if (pool.nftType == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), msg.sender, pool.tokenId);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), msg.sender, pool.tokenId, amount0, "");
        }

        if (swappedAmount0P[index] == pool.amountTotal0) {
            pools[index].closeAt = now;
        }

        emit Swapped(msg.sender, index, amount0, amount1);
    }

    function creatorClaim(uint index) external
        isPoolExist(index)
    {
        require(isCreator(msg.sender, index), "sender is not pool creator");
        require(!swappedP[index], "all swapped, nothing to claim");
        require(!creatorClaimedP[index], "creator has claimed this pool");
        creatorClaimedP[index] = true;
        if (pools[index].closeAt > now) {
            pools[index].closeAt = now;
        }

        // remove ownership of this pool from creator
        delete myCreatedP[msg.sender];

        Pool memory pool = pools[index];
        if (pool.nftType == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId, pool.amountTotal0.sub(swappedAmount0P[index]), "");
        }

        emit Claimed(msg.sender, index, pool.amountTotal0.sub(swappedAmount0P[index]));
    }

    function transferGovernor(address _governor) external {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;
    }

    function isCreator(address target, uint index) internal view returns (bool) {
        if (pools[index].creator == target) {
            return true;
        }
        return false;
    }

    function getPoolCount() external view returns (uint) {
        return pools.length;
    }

    function setFee(uint256 _fee) external feeGovernance returns (bool) {
        fee = _fee;
        return  true;
    }

    function setFeeMax(uint256 _feeMax) external feeGovernance returns (bool) {
        feeMax = _feeMax;
        return  true;
    }

    function setFeeTo(address payable _feeTo) external governance returns (bool) {
        feeTo = _feeTo;
        return  true;
    }

    function setIndexer(address _indexer) external governance returns (bool) {
        indexer = _indexer;
        return  true;
    }

    function onERC721Received(address, address, uint, bytes calldata) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint, uint, bytes calldata) external returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    modifier isPoolClosed(uint index) {
        require(pools[index].closeAt <= now, "this pool is not closed");
        _;
    }

    modifier isPoolNotClosed(uint index) {
        require(pools[index].closeAt > now, "this pool is closed");
        _;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier isPoolStarted(uint index) {
        require(startAt[index] <= now, "this pool is not started yet");
        _;
    }

    modifier feeGovernance() {
        require(msg.sender == feeGovernor);
        _;
    }

    function getStartTime(uint index) external view returns (uint) {
        return startAt[index];
    }

    modifier isAccountLimited(uint index, address _address) {
        if (poolIsUnique[index] && userLimited[_address] > 0) {
            require(now - userLimited[_address] >= 30 minutes, "this user is restricted in 30 minutes");
        }
        _;
    }

    function setPromoToken(address _promoToken, uint256 _fee) external governance returns (bool) {
        promoTokenList[_promoToken] = _fee;
        return true;
    }

    function getTokenRate(address _promoToken) external view returns (uint) {
        uint rate = fee;
        if (promoTokenList[_promoToken] != 0) {
            rate = promoTokenList[_promoToken];
        }
        return rate;
    }

    function setFeeGovernor(address _feeGovernor) external governance returns (bool) {
        feeGovernor = _feeGovernor;
        return true;
    }
}
