// SPDX-License-Identifier: MIT

pragma solidity ^0.5.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;

        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);

        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;

        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);

        c = a / b;
    }
}

library ExtendedMath {
    function limitLessThan(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a > b) return b;

        return a;
    }
}

contract ERC20Interface {
    function totalSupply() public returns (uint256);

    function balanceOf(address tokenOwner) public returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public returns (bool success);

    function approve(address spender, uint256 tokens)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 tokens,
        address token,
        bytes memory data
    ) public;
}

contract Owned {
    address public owner;

    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);

        _;
    }

    function renounceOwnership() public onlyOwner {
        transferOwnership(address(0));
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

contract BTCERC20 is ERC20Interface, Owned {
    using SafeMath for uint256;
    using ExtendedMath for uint256;

    string public symbol;

    string public name;

    uint8 public decimals;

    uint256 public _totalSupply;

    uint256 public latestDifficultyPeriodStarted;

    uint256 public epochCount; 

    uint256 public _BLOCKS_PER_READJUSTMENT = 1024;

    uint256 public _MINIMUM_TARGET = 2**16;

    uint256 public _MAXIMUM_TARGET = 2**234;

    uint256 public miningTarget;

    bytes32 public challengeNumber; 

    uint256 public rewardEra;
    uint256 public maxSupplyForEra;

    address public lastRewardTo;
    uint256 public lastRewardAmount;
    uint256 public lastRewardBscBlockNumber;

    bool locked = false;

    bool mintToOwner;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint256 public tokensMinted;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    event Mint(
        address indexed from,
        uint256 reward_amount,
        uint256 epochCount,
        bytes32 newChallengeNumber
    );

    constructor() public {
        symbol = "BTCe";

        name = "BTC ERC20";

        decimals = 8;

        _totalSupply = 21000000 * 10**uint256(decimals);

        if (locked) revert();
        locked = true;

        tokensMinted = 0;

        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);
        mintToOwner = false;

        miningTarget = _MAXIMUM_TARGET;

        latestDifficultyPeriodStarted = block.number;

        _startNewMiningEpoch();
        balances[msg.sender] = 5250000 * 10**uint256(decimals);
        tokensMinted = 5250000 * 10**uint256(decimals);

        emit Transfer(address(0), msg.sender, 5250000 * 10**uint256(decimals));
    }

    function mint(uint256 nonce, bytes32 challenge_digest)
        public
        returns (bool success)
    {

        bytes32 digest = keccak256(
            abi.encodePacked(challengeNumber, msg.sender, nonce)
        );


        if (digest != challenge_digest) revert();


        if (uint256(digest) > miningTarget) revert();


        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        if (solution != 0x0) revert();

       
        if(rewardEra == 0 && (!mintToOwner))
        {
           balances[owner] = balances[owner].add(maxSupplyForEra.div(2)); 
           lastRewardTo = owner;
           tokensMinted = tokensMinted.add(maxSupplyForEra.div(2));
           lastRewardAmount = maxSupplyForEra.div(2);
           lastRewardBscBlockNumber = block.number;
           _startNewMiningEpoch();
           mintToOwner = true;
           emit Mint(owner, maxSupplyForEra.div(2), epochCount, challengeNumber);
        }
        else
        {
        uint256 reward_amount = getMiningReward();
        balances[msg.sender] = balances[msg.sender].add(reward_amount);
        lastRewardTo = msg.sender;
        tokensMinted = tokensMinted.add(reward_amount);
        lastRewardAmount = reward_amount;
        lastRewardBscBlockNumber = block.number;
        _startNewMiningEpoch();
        emit Mint(msg.sender, reward_amount, epochCount, challengeNumber);
        }
        
        assert(tokensMinted <= maxSupplyForEra);
        return true;
    }


    function _startNewMiningEpoch() internal {

        if (
            tokensMinted.add(getMiningReward()) > maxSupplyForEra &&
            rewardEra < 39
        ) {
            rewardEra = rewardEra + 1;
        }

        maxSupplyForEra = _totalSupply - _totalSupply.div(2**(rewardEra + 1));

        epochCount = epochCount.add(1);

        if (epochCount % _BLOCKS_PER_READJUSTMENT == 0) {
            _reAdjustDifficulty();
        }

        challengeNumber = blockhash(block.number - 1);
    }

    function _reAdjustDifficulty() internal {
        uint256 bscBlocksSinceLastDifficultyPeriod = block.number -
            latestDifficultyPeriodStarted;

        uint256 epochsMined = _BLOCKS_PER_READJUSTMENT;

        uint256 targetBscBlocksPerDiffPeriod = epochsMined * 60; 

        if (bscBlocksSinceLastDifficultyPeriod < targetBscBlocksPerDiffPeriod) {
            uint256 excess_block_pct = (targetBscBlocksPerDiffPeriod.mul(100))
                .div(bscBlocksSinceLastDifficultyPeriod);

            uint256 excess_block_pct_extra = excess_block_pct
                .sub(100)
                .limitLessThan(1000);

            miningTarget = miningTarget.sub(
                miningTarget.div(2000).mul(excess_block_pct_extra)
            ); 
        } else {
            uint256 shortage_block_pct = (
                bscBlocksSinceLastDifficultyPeriod.mul(100)
            ).div(targetBscBlocksPerDiffPeriod);

            uint256 shortage_block_pct_extra = shortage_block_pct
                .sub(100)
                .limitLessThan(1000);

            miningTarget = miningTarget.add(
                miningTarget.div(2000).mul(shortage_block_pct_extra)
            ); 
        }

        latestDifficultyPeriodStarted = block.number;

        if (miningTarget < _MINIMUM_TARGET) 
        {
            miningTarget = _MINIMUM_TARGET;
        }

        if (miningTarget > _MAXIMUM_TARGET) 
        {
            miningTarget = _MAXIMUM_TARGET;
        }
    }

    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view returns (uint256) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public view returns (uint256) {
        return miningTarget;
    }

    function getMiningReward() public view returns (uint256) {


        return (50 * 10**uint256(decimals)).div(2**rewardEra);
    }


    function getMintDigest(uint256 nonce, bytes32 challenge_number)
        public
        view
        returns (bytes32 digesttest)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(challenge_number, msg.sender, nonce)
        );

        return digest;
    }

    function checkMintSolution(
        uint256 nonce,
        bytes32 challenge_digest,
        bytes32 challenge_number,
        uint256 testTarget
    ) public view returns (bool success) {
        bytes32 digest = keccak256(
            abi.encodePacked(challenge_number, msg.sender, nonce)
        );

        if (uint256(digest) > testTarget) revert();

        return (digest == challenge_digest);
    }


    function totalSupply() public returns (uint256) {
        return _totalSupply - balances[address(0)];
    }



    function balanceOf(address tokenOwner) public returns (uint256 balance) {
        return balances[tokenOwner];
    }



    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;
    }



    function approve(address spender, uint256 tokens)
        public
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        return true;
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        emit Transfer(from, to, tokens);

        return true;
    }


    function allowance(address tokenOwner, address spender)
        public
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }



    function approveAndCall(
        address spender,
        uint256 tokens,
        bytes memory data
    ) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(
            msg.sender,
            tokens,
            address(this),
            data
        );

        return true;
    }


    function transferAnyERC20Token(address tokenAddress, uint256 tokens)
        public
        onlyOwner
        returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}