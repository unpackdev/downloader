// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IApeToken.sol";

contract Bridge is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable apeUSD;
    IApeToken public immutable mainPool;

    mapping(IApeToken => bool) public isPool;
    IApeToken[] public allPools;
    address public guardian;

    event PoolAdded(address pool);
    event PoolRemoved(address pool);
    event Bridged(address fromPool, address toPool, uint256 amount);
    event GuardianSet(address guardian);
    event TokenSeized(address token, uint256 amount);

    modifier onlyGuardian() {
        require(msg.sender == guardian, "!guardian");
        _;
    }

    constructor(IERC20 _apeUSD, IApeToken _mainPool) {
        require(
            _mainPool.underlying() == address(_apeUSD),
            "mismatch underlying"
        );
        apeUSD = _apeUSD;
        mainPool = _mainPool;

        isPool[_mainPool] = true;
        allPools.push(_mainPool);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Get all pools including the main pool.
     */
    function getAllPools() public view returns (IApeToken[] memory) {
        return allPools;
    }

    /**
     * @notice Get apeUSD borrow balance from the main pool.
     */
    function getBorrowBalance() public view returns (uint256) {
        return mainPool.borrowBalanceStored(address(this));
    }

    /**
     * @notice Get apeUSD supply balance in apeUSD of a sub pool.
     * @param pool The pool address
     */
    function getSupplyBalance(IApeToken pool) public view returns (uint256) {
        (, uint256 balance, , uint256 exchangeRate) = pool.getAccountSnapshot(
            address(this)
        );
        return (balance * exchangeRate) / 1e18;
    }

    /**
     * @notice Get all apeUSD supply balance in apeUSD accross all pools.
     */
    function getAllSupplyBalance() public view returns (uint256) {
        uint256 supplyBalance;
        for (uint256 i = 0; i < allPools.length; i++) {
            supplyBalance += getSupplyBalance(allPools[i]);
        }
        return supplyBalance;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Add sub pools.
     * @param pools The pool addresses
     */
    function addPools(IApeToken[] calldata pools) external onlyOwner {
        for (uint256 i = 0; i < pools.length; i++) {
            IApeToken pool = pools[i];
            require(pool != mainPool, "cannot add main pool");
            require(!isPool[pool], "pool already added");
            require(
                pool.underlying() == address(apeUSD),
                "mismatch underlying"
            );

            isPool[pool] = true;
            allPools.push(pool);

            emit PoolAdded(address(pool));
        }
    }

    /**
     * @notice Remove sub pools.
     * @param pools The pool addresses
     */
    function removePools(IApeToken[] calldata pools) external onlyOwner {
        for (uint256 i = 0; i < pools.length; i++) {
            IApeToken pool = pools[i];
            require(pool != mainPool, "cannot remove main pool");
            require(isPool[pool], "pool not added");
            require(getSupplyBalance(pool) == 0, "pool still active");

            isPool[pool] = false;
            removePool(pool);

            emit PoolRemoved(address(pool));
        }
    }

    /**
     * @notice Bridge apeUSD from main pool to sub pool.
     * @param pool The sub pool address
     * @param amount The amount
     */
    function bridgeToSubPool(IApeToken pool, uint256 amount)
        external
        onlyOwner
        whenNotPaused
    {
        require(isPool[pool], "pool not added");

        require(
            mainPool.borrow(payable(address(this)), amount) == 0,
            "borrow failed"
        );
        apeUSD.safeIncreaseAllowance(address(pool), amount);
        require(pool.mint(address(this), amount) == 0, "supply failed");

        assert(apeUSD.balanceOf(address(this)) == 0);

        emit Bridged(address(mainPool), address(pool), amount);
    }

    /**
     * @notice Bridge apeUSD from sub pool to main pool.
     * @param pool The sub pool address
     * @param amount The amount
     */
    function bridgeFromSubPool(IApeToken pool, uint256 amount)
        external
        onlyOwner
        whenNotPaused
    {
        require(isPool[pool], "pool not added");

        require(
            pool.redeem(payable(address(this)), 0, amount) == 0,
            "redeem failed"
        );
        uint256 borrowBalance = mainPool.borrowBalanceCurrent(address(this));
        if (amount > borrowBalance) {
            repay(borrowBalance);

            apeUSD.safeTransfer(guardian, amount - borrowBalance);
        } else {
            repay(amount);
        }

        assert(apeUSD.balanceOf(address(this)) == 0);

        emit Bridged(address(pool), address(mainPool), amount);
    }

    /**
     * @notice Set guardian.
     * @param _guardian The guardian address
     */
    function setGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;

        emit GuardianSet(_guardian);
    }

    /**
     * @notice Seize tokens.
     * @param token The token address
     */
    function seize(IERC20 token) external onlyGuardian {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(guardian, balance);

        emit TokenSeized(address(token), balance);
    }

    /**
     * @notice Pause bridging.
     */
    function pause() external onlyGuardian {
        _pause();
    }

    /**
     * @notice Unause bridging.
     */
    function unpause() external onlyGuardian {
        _unpause();
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function removePool(IApeToken pool) internal {
        for (uint256 i = 0; i < allPools.length; i++) {
            if (allPools[i] == pool && i != allPools.length - 1) {
                allPools[i] = allPools[allPools.length - 1];
                allPools.pop();
                break;
            }
        }
    }

    function repay(uint256 amount) internal {
        apeUSD.safeIncreaseAllowance(address(mainPool), amount);
        require(
            mainPool.repayBorrow(address(this), amount) == 0,
            "repay failed"
        );
    }
}
