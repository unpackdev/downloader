// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./INutDistributor.sol";
import "./INut.sol";
import "./IPriceOracle.sol";
import "./Governable.sol";

/*
This contract distributes nut tokens based on staking unstaking during
the staking period.  It generates an array of "value times blocks" for
each token/lender pair and "total value times block" for each token.
It then distributes the rewards across the array.

One issue is that each unstake/stake requires a calculation to
determine the fraction of the pool owned by a lender.  To avoid having
to loop across all epochs and use up gas, this algorithm relies on the
fact that all future epochs have the same value.  So the vtb and
totalVtb arrays keep an index of the last epoch in which there was a
partial stake and unstake of tokens and then the epochs beyond that
all of the same value which is stored in futureVtbMap and
futureTotalVtbMap.
*/

contract NutDistributor is Governable, INutDistributor {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct Echo {
        uint id;
        uint endBlock;
        uint amount;
    }

    address public nutmeg;
    address public nut;
    address public oracle;

    uint public constant MAX_NUM_POOLS = 256;
    uint public DIST_START_BLOCK; // starting block of echo 0
    uint public constant NUM_EPOCH = 15; // # of epochs
    uint public BLOCKS_PER_EPOCH; // # of blocks per epoch
    uint public constant DIST_START_AMOUNT = 250000 ether; // # of tokens distributed at epoch 0
    uint public constant DIST_MIN_AMOUNT = 18750 ether; // min # of tokens distributed at any epoch

    uint public CURRENT_EPOCH;
    mapping(address => bool) addedPoolMap;
    address[] public pools;
    mapping(uint => Echo) public echoMap;
    mapping(uint => bool) public distCompletionMap;

    // the term vtb is short for value times blocks
    mapping(address => uint[15]) public totalVtbMap; // pool => total vtb, i.e., valueTimesBlocks.
    mapping(address => uint[15]) public totalNutMap; // pool => total Nut awarded.
    mapping(address => mapping( address => uint[15] ) ) public vtbMap; // pool => lender => vtb.

    mapping(address => uint) futureTotalVtbMap;
    mapping(address => mapping( address => uint) ) futureVtbMap;
    mapping(address => uint) futureTotalVtbEpoch;
    mapping(address => mapping( address => uint) ) futureVtbEpoch;

    modifier onlyNutmeg() {
        require(msg.sender == nutmeg, 'only nutmeg can call');
        _;
    }

    /// @dev Set the Nutmeg
    function setNutmegAddress(address addr) external onlyGov {
        nutmeg = addr;
    }

    /// @dev Set the oracle
    function setPriceOracle(address addr) external onlyGov {
        oracle = addr;
    }

    function initialize(address nutAddr, address _governor) public initializer{
        nut = nutAddr;
        DIST_START_BLOCK = block.number;
        BLOCKS_PER_EPOCH = 80640;
         __Governable__init(_governor);

        // config echoMap which indicates how many tokens will be distributed at each epoch
        for (uint i = 0; i < NUM_EPOCH; i++) {
            Echo storage echo =  echoMap[i];
            echo.id = i;
            echo.endBlock = DIST_START_BLOCK.add(BLOCKS_PER_EPOCH.mul(i.add(1)));
            uint amount = DIST_START_AMOUNT.div(i.add(1));
            if (amount < DIST_MIN_AMOUNT) {
                amount = DIST_MIN_AMOUNT;
            }
            echo.amount = amount;
        }
    }


    function inNutDistribution() external override view returns(bool) {
        return (block.number >= DIST_START_BLOCK && block.number < DIST_START_BLOCK.add(BLOCKS_PER_EPOCH.mul(NUM_EPOCH)));
    }

    /// @notice Update valueTimesBlocks of pools and the lender when they stake or unstake
    /// @param token Base token of the pool.
    /// @param lender Address of the lender.
    /// @param incAmount to stake or unstake
    /// @param decAmount false=subtract/unstake true=add/stake
    function updateVtb(address token, address lender, uint incAmount, uint decAmount) external override onlyNutmeg {
        require(block.number >= DIST_START_BLOCK, 'updateVtb: invalid block number');
        require(incAmount == 0 || decAmount == 0, 'updateVtb: update amount is invalid');

        uint amount = incAmount.add(decAmount);
        require(amount > 0, 'updateVtb: update amount should be positive');

        // get current epoch
        CURRENT_EPOCH = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        if (CURRENT_EPOCH >= NUM_EPOCH) return;

        _fillVtbGap(token, lender);
        _fillTotalVtbGap(token);

        uint dv = echoMap[CURRENT_EPOCH].endBlock.sub( block.number ).mul(amount);
        uint epochDv = BLOCKS_PER_EPOCH.mul(amount);

        if (incAmount > 0) {
            vtbMap[token][lender][CURRENT_EPOCH] = vtbMap[token][lender][CURRENT_EPOCH].add(dv);
            totalVtbMap[token][CURRENT_EPOCH] = totalVtbMap[token][CURRENT_EPOCH].add(dv);
            futureVtbMap[token][lender] = futureVtbMap[token][lender].add(epochDv);
            futureTotalVtbMap[token] = futureTotalVtbMap[token].add(epochDv);
        } else {
            vtbMap[token][lender][CURRENT_EPOCH] = vtbMap[token][lender][CURRENT_EPOCH].sub(dv);
            totalVtbMap[token][CURRENT_EPOCH] = totalVtbMap[token][CURRENT_EPOCH].sub(dv);
            futureVtbMap[token][lender] = futureVtbMap[token][lender].sub(epochDv);
            futureTotalVtbMap[token] = futureTotalVtbMap[token].sub(epochDv);
        }

        if (!addedPoolMap[token]) {
            pools.push(token);
            addedPoolMap[token] = true;
        }
    }
    // @dev This function fills the array between the last epoch at which things were calculated and the current epoch.
    function _fillVtbGap(address token, address lender) internal {
        if (futureVtbEpoch[token][lender] > CURRENT_EPOCH || CURRENT_EPOCH >= NUM_EPOCH ) return;
        uint futureVtb = futureVtbMap[token][lender];
        for (uint i = futureVtbEpoch[token][lender]; i <= CURRENT_EPOCH; i++) {
            vtbMap[token][lender][i] = futureVtb;
        }
        futureVtbEpoch[token][lender] = CURRENT_EPOCH.add(1);
    }

    // @dev This function fills the array between the last epoch at which things were calculated and the current epoch.
    function _fillTotalVtbGap(address token) internal {
        if (futureTotalVtbEpoch[token] > CURRENT_EPOCH || CURRENT_EPOCH >= NUM_EPOCH ) return;
        uint futureTotalVtb = futureTotalVtbMap[token];
        for (uint i = futureTotalVtbEpoch[token]; i <= CURRENT_EPOCH; i++) {
            totalVtbMap[token][i] = futureTotalVtb;
        }
        futureTotalVtbEpoch[token] = CURRENT_EPOCH.add(1);
    }

    /// @dev Distribute NUT tokens for the previous epoch
    function distribute() external onlyGov {
        require(oracle != address(0), 'distribute: no oracle available');

        // get current epoch
        uint currEpochId = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        require(currEpochId > 0, 'distribute: nut token distribution not ready');
        require(currEpochId < NUM_EPOCH.add(1), 'distribute: nut token distribution is over');

        // distribute the nut tokens for the previous epoch.
        uint prevEpochId = currEpochId.sub(1);
        require(!distCompletionMap[prevEpochId], 'distribute: distribution is completed');

        // mint nut tokens
        uint amount = echoMap[prevEpochId].amount;
        INut(nut).mint(address(this), amount);

        uint numOfPools = pools.length < MAX_NUM_POOLS ? pools.length : MAX_NUM_POOLS;
        uint sumOfDv;
        uint actualSumOfNut;
        for (uint i = 0; i < numOfPools; i++) {
            uint price = IPriceOracle(oracle).getPrice(pools[i]);
            uint dv = price.mul(getTotalVtb(pools[i],prevEpochId));
            sumOfDv = sumOfDv.add(dv);
        }

        if (sumOfDv > 0) {
            for (uint i = 0; i < numOfPools; i++) {
                uint price = IPriceOracle(oracle).getPrice(pools[i]);
                uint dv = price.mul(getTotalVtb(pools[i], prevEpochId));
                uint nutAmount = dv.mul(amount).div(sumOfDv);
                actualSumOfNut = actualSumOfNut.add(nutAmount);
                totalNutMap[pools[i]][prevEpochId] = nutAmount;
            }
        }

        require(actualSumOfNut <= amount, "distribute: overflow");

        distCompletionMap[prevEpochId] = true;
    }

    /// @dev Collect Nut tokens
    function collect() external  {
        uint epochId = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        require(epochId > 0, 'collect: distribution is completed');

        address lender = msg.sender;

        uint numOfPools = pools.length < MAX_NUM_POOLS ? pools.length : MAX_NUM_POOLS;
        uint totalAmount;
        for (uint i = 0; i < numOfPools; i++) {
            address pool = pools[i];
            for (uint j = 0; j < epochId && j < NUM_EPOCH; j++) {
                uint vtb = getVtb(pool, lender, j);
                if (vtb > 0 && getTotalVtb(pool, j) > 0) {
                    uint amount = vtb.mul(totalNutMap[pool][j]).div(getTotalVtb(pool, j));
                    totalAmount = totalAmount.add(amount);
                    vtbMap[pool][lender][j] = 0;
                }
            }
        }

        if (totalAmount > 0) {
            require(
                IERC20(nut).approve(address(this), 0),
                'distributor approve failed'
            );
            require(
                IERC20(nut).approve(address(this), totalAmount),
                'NutDist approve amount failed'
            );
            require(
                IERC20(nut).transferFrom(address(this), lender, totalAmount),
                'NutDist transfer failed'
            );
        }
    }

    /// @dev getCollectionAmount get the # of NUT tokens for collection
    function getCollectionAmount() external view returns(uint) {
        uint epochId = (block.number.sub(DIST_START_BLOCK)).div(BLOCKS_PER_EPOCH);
        require(epochId > 0, 'getCollectionAmount: distribution is completed');

        address lender = msg.sender;

        uint numOfPools = pools.length < MAX_NUM_POOLS ? pools.length : MAX_NUM_POOLS;
        uint totalAmount;
        for (uint i = 0; i < numOfPools; i++) {
            address pool = pools[i];
            for (uint j = 0; j < epochId && j < NUM_EPOCH; j++) {
                uint vtb = getVtb(pool, lender, j);
                if (vtb > 0 && getTotalVtb(pool, j) > 0) {
                    uint amount = vtb.mul(totalNutMap[pool][j]).div(getTotalVtb(pool, j));
                    totalAmount = totalAmount.add(amount);
                }
            }
        }

        return totalAmount;
    }

    function getVtb(address pool, address lender, uint i) public view returns(uint) {
        require(i < NUM_EPOCH, 'vtb idx err');
        return i < futureVtbEpoch[pool][lender] ?
            vtbMap[pool][lender][i] : futureVtbMap[pool][lender];
    }
    function getTotalVtb(address pool, uint i) public view returns (uint) {
        require(i < NUM_EPOCH, 'totalVtb idx err');
        return i < futureTotalVtbEpoch[pool] ?
            totalVtbMap[pool][i] : futureTotalVtbMap[pool];
    }

    //@notice output version string
    function getVersionString()
    external virtual pure returns (string memory) {
        return "1";
   }
}
