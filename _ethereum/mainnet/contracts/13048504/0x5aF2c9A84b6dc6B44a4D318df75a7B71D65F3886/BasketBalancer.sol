// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./IReign.sol";
import "./IPoolRouter.sol";
import "./SafeMath.sol";

contract BasketBalancer {
    using SafeMath for uint256;

    uint256 public fullAllocation;
    uint128 public lastEpochUpdate;
    uint256 public lastEpochEnd;
    uint256 public maxDelta;

    address[] private allTokens;

    mapping(address => uint256) public continuousVote;
    mapping(address => uint256) private tokenAllocation;
    mapping(address => uint256) private tokenAllocationBefore;
    mapping(address => mapping(uint128 => bool)) private votedInEpoch;

    IReign private reign;
    address public poolRouter;
    address public reignDAO;
    address public reignDiamond;

    event UpdateAllocation(
        uint128 indexed epoch,
        address indexed pool,
        uint256 indexed allocation
    );
    event VoteOnAllocation(
        address indexed sender,
        address indexed pool,
        uint256 indexed allocation,
        uint128 epoch
    );

    event NewToken(address indexed pool, uint256 indexed allocation);
    event RemoveToken(address indexed pool);

    modifier onlyDAO() {
        require(msg.sender == reignDAO, "Only the DAO can execute this");
        _;
    }

    constructor(
        address _reignDiamond,
        address _reignDAO,
        address _poolRouter,
        uint256 _maxDelta
    ) {
        uint256 amountAllocated = 0;

        address[] memory tokens = IPoolRouter(_poolRouter).getPoolTokens();
        uint256[] memory weights = IPoolRouter(_poolRouter).getTokenWeights();

        for (uint256 i = 0; i < tokens.length; i++) {
            tokenAllocation[tokens[i]] = weights[i];
            tokenAllocationBefore[tokens[i]] = weights[i];
            continuousVote[tokens[i]] = weights[i];
            amountAllocated = amountAllocated.add(weights[i]);
        }
        fullAllocation = amountAllocated;

        lastEpochUpdate = 0;
        maxDelta = _maxDelta;
        allTokens = tokens;
        reign = IReign(_reignDiamond);
        reignDiamond = _reignDiamond;
        reignDAO = _reignDAO;
        poolRouter = _poolRouter;
    }

    // Counts votes and sets the outcome allocation for each pool,
    // can be called by anyone through DAO after an epoch ends.
    // The new allocation value is the average of the vote outcome and the current value
    function updateBasketBalance() public onlyDAO {
        uint128 _epochId = getCurrentEpoch();
        require(lastEpochUpdate < _epochId, "Epoch is not over");

        for (uint256 i = 0; i < allTokens.length; i++) {
            uint256 _currentValue = continuousVote[allTokens[i]]; // new vote outcome
            uint256 _previousValue = tokenAllocation[allTokens[i]]; // before this vote

            // the new current value is the average between the 2 values
            tokenAllocation[allTokens[i]] = (_currentValue.add(_previousValue))
                .div(2);

            // update the previous value
            tokenAllocationBefore[allTokens[i]] = _previousValue;

            emit UpdateAllocation(
                _epochId,
                allTokens[i],
                tokenAllocation[allTokens[i]]
            );
        }

        lastEpochUpdate = _epochId;
        lastEpochEnd = block.timestamp;
    }

    // Allows users to update their vote by giving a desired allocation for each pool
    // tokens and allocations need to share the index, pool at index 1 will get allocation at index 1
    function updateAllocationVote(
        address[] calldata tokens,
        uint256[] calldata allocations
    ) external {
        uint128 _epoch = getCurrentEpoch();

        // Checks
        require(
            tokens.length == allTokens.length,
            "Need to vote for all tokens"
        );
        require(
            tokens.length == allocations.length,
            "Need to have same length"
        );
        require(reign.balanceOf(msg.sender) > 0, "Not allowed to vote");

        require(
            votedInEpoch[msg.sender][_epoch] == false,
            "Can not vote twice in an epoch"
        );

        // we take the voting power as it was at the end of the last epoch to avoid flashloan attacks
        // or users sending their stake to new wallets and vote again
        uint256 _votingPower = reign.votingPowerAtTs(msg.sender, lastEpochEnd);
        uint256 _totalPower = reign.reignStaked();

        //users vote "against" all other users
        uint256 _remainingPower = _totalPower.sub(_votingPower);

        uint256 amountAllocated = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            //tokens need to have the same order as allTokens
            require(allTokens[i] == tokens[i], "tokens have incorrect order");
            uint256 _votedFor = allocations[i];
            uint256 _current = continuousVote[allTokens[i]];
            amountAllocated = amountAllocated.add(_votedFor);

            // The difference between the voted for allocation and the current value can not exceed maxDelta
            if (_votedFor > _current) {
                require(_votedFor - _current <= maxDelta, "Above Max Delta");
            } else {
                require(_current - _votedFor <= maxDelta, "Above Max Delta");
            }
            // if all checks have passed, we update the allocation vote
            continuousVote[allTokens[i]] = (
                _current.mul(_remainingPower).add(_votedFor.mul(_votingPower))
            )
                .div(_totalPower);

            //emit event for each token
            emit VoteOnAllocation(msg.sender, allTokens[i], _votedFor, _epoch);
        }

        //transaction will revert if allocation is not complete
        require(
            amountAllocated == fullAllocation,
            "Allocation is not complete"
        );

        // apply boost
        votedInEpoch[msg.sender][_epoch] = true;
    }

    // adds a token to the baskte balancer
    // this mirrors the tokens in the pool both in allocation and order added
    // every time a token is added to the pool it needs to be added here as well
    function addToken(address token, uint256 allocation)
        external
        onlyDAO
        returns (uint256)
    {
        // add token and store allocation
        allTokens.push(token);
        tokenAllocationBefore[token] = allocation;
        tokenAllocation[token] = allocation;
        continuousVote[token] = allocation;

        //update total allocation
        fullAllocation = fullAllocation.add(allocation);

        emit NewToken(token, allocation);

        return allTokens.length;
    }

    // removes a token from the baskte balancer
    // every time a token is removed to the pool it needs to be removed here as well
    function removeToken(address token) external onlyDAO returns (uint256) {
        require(tokenAllocation[token] != 0, "Token is not part of Basket");

        fullAllocation = fullAllocation.sub(continuousVote[token]);

        //remove token from array, moving all others 1 down if necessary
        uint256 index;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (allTokens[i] == token) {
                index = i;
                break;
            }
        }

        for (uint256 i = index; i < allTokens.length - 1; i++) {
            allTokens[i] = allTokens[i + 1];
        }
        allTokens.pop();

        // reset allocations
        tokenAllocationBefore[token] = 0;
        tokenAllocation[token] = 0;
        continuousVote[token] = 0;

        emit RemoveToken(token);

        return allTokens.length;
    }

    /*
     *   SETTERS
     */

    function setRouter(address _poolRouter) public onlyDAO {
        poolRouter = _poolRouter;
    }

    function setReignDAO(address _reignDAO) public onlyDAO {
        reignDAO = _reignDAO;
    }

    function setMaxDelta(uint256 _maxDelta) public onlyDAO {
        maxDelta = _maxDelta;
    }

    /*
     *   VIEWS
     */

    // gets the current target allocation
    function getTargetAllocation(address pool) public view returns (uint256) {
        return tokenAllocation[pool];
    }

    //Returns the id of the current epoch from reignDiamond
    function getCurrentEpoch() public view returns (uint128) {
        return reign.getCurrentEpoch();
    }

    function getTokens() external view returns (address[] memory) {
        return allTokens;
    }

    function hasVotedInEpoch(address user, uint128 epoch)
        external
        view
        returns (bool)
    {
        return votedInEpoch[user][epoch];
    }
}
