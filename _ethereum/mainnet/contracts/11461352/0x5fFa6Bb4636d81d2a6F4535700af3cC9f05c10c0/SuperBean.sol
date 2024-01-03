// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "SafeMath: add overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "SafeMath: sub underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "SafeMath: mul overflow");
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0, "SafeMath: division by zero");
        uint c = a / b;
        return c;
    }
}

contract SuperBean {
    using SafeMath for uint;

    string public constant name = "SuperBean";
    string public constant symbol = "SBT";
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public rainmaker;
    uint public FEEDING_END_BLOCK = 11688888;
    uint public MIN_STAKE_VALUE = 50000000000000000;
    uint public MAX_STAKE_VALUE = 10000000000000000000;
    uint public MIN_TIER_1 = 10000000000000000000;
    uint public MIN_TIER_2 = 50000000000000000000;
    uint public MIN_TIER_3 = 100000000000000000000;

    uint constant MATURITY = 300;
    uint constant MIN_CHANCE = 1;
    uint constant MAX_CHANCE = 95;
    uint8 constant LEFT_MASK = 0xf0;
    uint8 constant RIGHT_MASK = 0xf;

    struct Stake {
      uint blockNumber;
      uint8 rnd;
      uint8 chance;
      uint value;
      uint reward;
    }

    mapping (address => Stake[]) StakeMap;

    constructor() {
      rainmaker = msg.sender;
    }

    // events
    event Approval(
        address indexed owner,
        address indexed spender,
        uint value
    );
    event Transfer(address indexed from, address indexed to, uint value);

    event StakeEvent(address sender, uint8 chance, uint value, uint amount);
    event HarvestEvent(uint rnd, uint chance, uint value, uint reward);
    event UnstakeEvent(address sender, uint beans, uint amount);
    event SwapEvent(address sender, uint value, uint amount);
    event FeedEvent(address sender, uint value, uint amount);

    // modifiers
    modifier onlyRainmaker {
        require( msg.sender == rainmaker, "SuperBeans: onlyRainmaker methods called by non-rainmaker." );
        _;
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve( address owner, address spender, uint value ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer( address from, address to, uint value ) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom( address from, address to, uint value ) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub( value );
        }
        _transfer(from, to, value);
        return true;
    }

    // configuration
    function setRainmaker(address newRainmaker) external onlyRainmaker {
        rainmaker = newRainmaker;
    }
    function setStake(uint typ, uint value) external onlyRainmaker {
        if (typ == 0) {
            MIN_STAKE_VALUE = value;
        } else if (typ == 1) {
            MAX_STAKE_VALUE = value;
        }
    }
    function setTier(uint tier, uint value) external onlyRainmaker {
        if (tier == 1) {
            MIN_TIER_1 = value;
        } else if (tier == 2) {
            MIN_TIER_2 = value;
        } else if (tier == 3) {
            MIN_TIER_3 = value;
        }
    }
    function setFeedingEndBlock(uint value) external onlyRainmaker {
        require( block.number + MATURITY < value, 'SuperBean: invalid feeding end block');
        FEEDING_END_BLOCK = value;
    }

    // stake
    function stake(uint chance) external payable {
        uint value = msg.value;
        require(chance >= MIN_CHANCE && chance <= MAX_CHANCE, "SuperBean: invalid chance");
        require(value >= MIN_STAKE_VALUE && value <= MAX_STAKE_VALUE, "SuperBean: invalid stake value");

        Stake[] storage stakes = StakeMap[msg.sender];
        uint a = chance.mul(uint(100).sub(chance)).mul(uint(100).sub(chance));
        uint minBeans = value.mul(chance).mul(uint(100).sub(chance))/uint(10000);
        uint maxBeans = value.mul(uint(1000000).sub(a))/(chance.mul(uint(10000)));
        uint fee = minBeans/uint(100);
        uint amount = minBeans.sub(fee);
        uint reward = maxBeans.sub(minBeans);
        _mint(rainmaker, fee);
        _mint(msg.sender, amount);
        stakes.push(Stake(block.number, uint8(255), uint8(chance), value, reward));
        emit StakeEvent(msg.sender, uint8(chance), value, amount);
    }

    // harvest
    function harvest(address addr) external {
        Stake[] storage stakes = StakeMap[addr];
        require(stakes.length > 0, "SuperBean: no stakes to harvest");
        require(stakes[0].blockNumber + MATURITY < block.number, "SuperBean: stakes not mature");
        require(stakes[stakes.length - 1].rnd == uint8(255), "SuperBean: no pending stakes");

        uint rewards = 0;
        uint fees = 0;
        for (uint i = 0; i < stakes.length; i++) {
            if (stakes[i].rnd != uint8(255) || stakes[i].blockNumber + MATURITY > block.number) {
                continue;
            }
            uint rnd = random(hash(stakes[i]));
            stakes[i].rnd = uint8(rnd);
            if (rnd < stakes[i].chance) {
                uint fee = stakes[i].reward.div(uint(100));
                fees = fees.add(fee);
                rewards = rewards.add(stakes[i].reward);
                emit HarvestEvent(rnd, stakes[i].chance, stakes[i].value, stakes[i].reward);
             } else{
                emit HarvestEvent(rnd, stakes[i].chance, stakes[i].value, 0);
             }
        }
        if (rewards > 0) {
            _mint(rainmaker, fees);
            _mint(addr, rewards);
        }
    }

    // unstake
    function unstake(uint amount) external payable {
        require(amount > 0 && balanceOf[msg.sender] >= amount && totalSupply > amount, "SuperBean: inefficient beans");
        uint totalSeeds = payable(address(this)).balance;
        uint seeds = amount.mul(totalSeeds)/totalSupply;
        msg.sender.transfer(seeds);
        _burn(msg.sender, amount);
        emit UnstakeEvent(msg.sender, amount, seeds);
    }

    function swap() external payable {
        require(msg.value > 0, "SuperBean: inefficient funds to swap");
        uint totalSeeds = payable(address(this)).balance;
        uint beans = 0;
        if (totalSeeds > 0 && totalSeeds > msg.value && totalSupply > 0) {
            beans = (msg.value).mul(totalSupply)/totalSeeds.sub(msg.value);
        } else {
            beans = msg.value;
        }
        uint fee = beans/100;
        uint amount = beans.sub(fee);
        _mint(msg.sender, amount);
        _mint(rainmaker, fee);
        emit SwapEvent(msg.sender, msg.value, beans);
    }

    function feed() external payable {
        require(block.number < FEEDING_END_BLOCK, "SuperBean: feeding is over");
        require(msg.value >= MIN_TIER_1, "SuperBean: inefficient funds to feed");
        uint beans = 0;
        if (msg.value >= MIN_TIER_3) {
            beans = (msg.value).mul(9)/5;
        } else if (msg.value >= MIN_TIER_2) {
            beans = (msg.value).mul(7)/5;
        } else {
            beans = (msg.value).mul(6)/5;
        }
        uint fees = beans/10;
        _mint(msg.sender, beans);
        _mint(rainmaker, fees);
        emit FeedEvent(msg.sender, msg.value, beans);
    }

    function hash(Stake memory s) internal view returns(bytes32) {
        bytes32 hashStr = keccak256(abi.encodePacked(s.blockNumber, s.chance, s.value, block.difficulty, blockhash(block.number), block.timestamp));
        return hashStr;
    }

    function random(bytes32 gene) internal pure returns(uint) {
        uint first = 10;
        uint second = 10;
        uint cnt = 0;
        for (uint i = gene.length - 1; i >= 0 && cnt < 2; i--) {
            uint r = uint8(gene[i]) & RIGHT_MASK;
            if (r < 10) {
                if (cnt == 0) {
                    first = r;
                } else if (cnt == 1) {
                    second = r;
                }
                cnt = cnt + 1;
            }
            uint l = (uint8(gene[i]) & LEFT_MASK) >> 4;
            if (l < 10) {
                if (cnt == 0) {
                    first = l;
                } else if (cnt == 1) {
                    second = l;
                }
                cnt = cnt + 1;
            }
        }
        return second * 10 + first;
    }

    function getStakes(address addr) public view returns (Stake[] memory) {
      return StakeMap[addr];
    }

}