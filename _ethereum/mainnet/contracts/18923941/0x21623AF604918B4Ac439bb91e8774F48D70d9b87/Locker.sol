// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

contract Locker is Ownable {
    event Lock(uint256 amount, address from, address tokenAddress);
    event ReleaseLock(uint256 amount, address to, address tokenAddress);

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    uint256 public totalLocked;

    struct LockInfo {
        address owner;
        address tokenAddress;
        uint256 releaseDate;
        uint256 lockDate;
        uint256 amount;
        uint8 method;
    }

    struct AccountInfo {
        uint256 lockedCount;
        mapping(uint256 => LockInfo) lockinfo;
    }

    mapping(address => AccountInfo) public locker;

    constructor() {}

    //----STATEFUL

    //---LOCKING---
    function lock(
        uint256 unlockDate,
        address tokenAddress,
        uint256 amount
    ) external onlyEOA {
        (uint256 balance, uint256 allowance, ERC20 tokens) = _tokenProxy(
            tokenAddress,
            msg.sender
        );
        require(unlockDate >= block.timestamp, "Invalid date");
        require(allowance >= amount, "please adjust allowances");
        require(
            balance >= amount && balance > 0 && amount > 0,
            "invalid amount"
        );
        AccountInfo storage AInfo = locker[msg.sender];
        AInfo.lockedCount++;
        AInfo.lockinfo[AInfo.lockedCount] = LockInfo({
            owner: msg.sender,
            tokenAddress: tokenAddress,
            releaseDate: unlockDate,
            lockDate: block.timestamp,
            amount: amount,
            method: 1
        });
        totalLocked++;
        require(
            tokens.transferFrom(msg.sender, address(this), amount),
            "tx failed"
        );
        emit Lock(amount, msg.sender, tokenAddress);
    }

    //---RELEASE---
    function releaseLock(uint256 lockId) external onlyEOA {
        LockInfo storage LInfo = locker[msg.sender].lockinfo[lockId];
        (uint256 balance, , ERC20 tokens) = _tokenProxy(
            LInfo.tokenAddress,
            address(this)
        );

        require(block.timestamp >= LInfo.releaseDate, "Not unlocked yet");
        require(msg.sender == LInfo.owner, "invalid owner");
        require(balance > 0 && LInfo.amount > 0, "invalid balance");
        uint256 txAmount = LInfo.amount;
        LInfo.amount = 0;
        totalLocked--;
        require(
            tokens.transfer(msg.sender, txAmount),
            "tx failed / non standard token"
        );
        emit ReleaseLock(txAmount, msg.sender, LInfo.tokenAddress);
    }

    //----VIEW
    function _tokenProxy(address tokenAddress, address owner)
        private
        view
        returns (
            uint256 balance,
            uint256 allowance,
            ERC20 token
        )
    {
        ERC20 tokens = ERC20(tokenAddress);
        uint256 balances = tokens.balanceOf(owner);
        uint256 allowances = tokens.allowance(owner, address(this));
        return (balances, allowances, tokens);
    }

    function viewLockCount(address addr)
        public
        view
        returns (uint256 lockedCount)
    {
        AccountInfo storage AInfo = locker[addr];
        return (AInfo.lockedCount);
    }

    function viewLockByID(uint256 id, address addr)
        public
        view
        returns (LockInfo memory LInfo)
    {
        AccountInfo storage AInfo = locker[addr];
        LockInfo storage LInfos = AInfo.lockinfo[id];

        return (LInfos);
    }
}
