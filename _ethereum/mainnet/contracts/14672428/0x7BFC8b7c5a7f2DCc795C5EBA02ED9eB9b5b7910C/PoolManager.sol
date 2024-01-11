// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface IPool {
    function start(uint256 tokenId) external payable;
}

interface INft {
    function mint(address sender, uint256 tokenId, uint256 tokens) external;

    function burn(address sender, uint256 tokenId, uint256 tokens) external;

    function totalSupply(uint256 tokenId) view external returns (uint256);

    function balanceOf(address investor, uint256 tokenId) view external returns (uint256);
}

interface IPoolDistributor {
    function snapshot() external returns (uint256);

    function receiveFee(uint256 snapshotId) external payable;
}

contract PoolManager is Ownable {

    enum Status{Pending, Open, Locked, Closed, Exited}
    struct PoolData {
        Status status;
        uint256 price;
        uint256 maxSupply;
        address poolContract;
    }

    mapping(uint256 => PoolData) public pools;
    mapping(uint256 => uint256) public finalBalances;
    mapping(uint256 => uint256) public snapshotIds;
    address public managementContract;
    INft immutable public poolNft;
    IERC20 immutable public landDao;
    IPoolDistributor immutable public poolDistributor;

    constructor(address poolNft_, address poolDistributor_, address landDao_) {
        poolNft = INft(poolNft_);
        poolDistributor = IPoolDistributor(poolDistributor_);
        landDao = IERC20(landDao_);
    }

    function setManagementContract(address managementContract_) external onlyOwner {
        require(managementContract_ != address(0), "Manager: should be not null");
        managementContract = managementContract_;
    }

    function totalSupply(uint256 tokenId) view public returns (uint256) {
        return poolNft.totalSupply(tokenId);
    }

    function balanceOf(address investor, uint256 tokenId) view public returns (uint256){
        return poolNft.balanceOf(investor, tokenId);
    }

    function open(uint256 tokenId, uint256 price, uint256 maxSupply, address poolContract) external onlyOwner {
        require(tokenId > 0, "Manager: tokenId is 0");
        PoolData memory pool = pools[tokenId];
        require(pool.status == Status.Pending, "Manager: not pending");
        pools[tokenId] = PoolData(Status.Open, price, maxSupply, poolContract);
        uint256 snapshotId = poolDistributor.snapshot();
        snapshotIds[tokenId] = snapshotId;
    }

    function invest(uint256 tokenId, uint256 tokens) external payable {
        PoolData memory pool = pools[tokenId];
        require(pool.status == Status.Open, "Manager: not enabled");
        require(totalSupply(tokenId) + tokens <= pool.maxSupply, "Manager: exceeds max");
        require(msg.value == pool.price * tokens, "Manager: wrong amount");
        poolNft.mint(msg.sender, tokenId, tokens);
    }

    function lock(uint256 tokenId) external onlyOwner {
        PoolData memory pool = pools[tokenId];
        uint256 totalSupply_ = totalSupply(tokenId);
        require(totalSupply_ > 0, "Manager: no investments");
        require(managementContract != address(0), "Manager: management contract null");
        require(pool.status == Status.Open, "Manager: contract not open");
        uint256 balance = pool.price * totalSupply_;
        uint256 managementFee = (balance * 3) / 100;
        uint256 distributableFee = (balance * 2) / 100;
        uint256 operationAmount = balance - (managementFee + distributableFee);
        pools[tokenId].status = Status.Locked;
        poolDistributor.receiveFee{value : distributableFee}(snapshotIds[tokenId]);
        IPool(pool.poolContract).start{value : operationAmount}(tokenId);
        (bool success,) = payable(managementContract).call{value : managementFee}("");
        require(success, "Manager: unsuccessful payment");
    }

    function allowExit(uint256 tokenId) external onlyOwner {
        require(pools[tokenId].status == Status.Open, "Manager: bad status");
        pools[tokenId].status = Status.Exited;
    }

    function exit(uint256 tokenId) external {
        PoolData memory pool = pools[tokenId];
        require(pool.status == Status.Exited, "Manager: exit not possible");
        uint256 balance = balanceOf(msg.sender, tokenId);
        require(balance > 0, "Manager: not a holder");
        poolNft.burn(msg.sender, tokenId, balance);
        (bool success,) = payable(msg.sender).call{value : balance * pool.price}("");
        require(success, "Manager: unsuccessful payment");
    }

    function close(uint256 tokenId) external payable {
        PoolData memory pool = pools[tokenId];
        require(pool.status == Status.Locked, "Manager: not locked");
        require(msg.sender == pool.poolContract, "Manager: only pool");
        uint256 invested = totalSupply(tokenId) * pool.price;
        uint256 fee;
        if (msg.value > invested) {
            uint256 profit = msg.value - invested;
            fee = profit / 10;
            poolDistributor.receiveFee{value : fee}(snapshotIds[tokenId]);
        }
        finalBalances[tokenId] = msg.value - (fee * 2);
        pools[tokenId].status = Status.Closed;
        if (fee > 0) {
            (bool success,) = payable(managementContract).call{value : fee}("");
            require(success, "Manager: unsuccessful payment");
        }
    }

    function claimable(address investor, uint256 tokenId) public view returns (uint256) {
        uint256 balance = balanceOf(investor, tokenId);
        uint256 finalBalance = finalBalances[tokenId];
        uint256 totalSupply_ = totalSupply(tokenId);
        return (finalBalance * balance) / totalSupply_;
    }

    function claim(uint256 tokenId) external {
        PoolData memory pool = pools[tokenId];
        require(pool.status == Status.Closed, "Manager: claim not available");
        uint256 balance = balanceOf(msg.sender, tokenId);
        require(balance > 0, "Manager: nothing to claim");
        uint256 totalSupply_ = totalSupply(tokenId);
        uint256 finalBalance = finalBalances[tokenId];
        uint256 amount = (finalBalance * balance) /totalSupply_;

        uint256 landBalance = landDao.balanceOf(pool.poolContract);
        if (landBalance > 0) {
            uint256 rewards = (landBalance * balance) / totalSupply_;
            landDao.transferFrom(pool.poolContract, msg.sender, rewards);
        }

        finalBalances[tokenId] -= amount;
        poolNft.burn(msg.sender, tokenId, balance);

        (bool success,) = payable(msg.sender).call{value : amount}("");
        require(success, "Manager: unsuccessful payment");
    }
}
