pragma solidity ^0.5.12;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IAdapter {
    function calc(
        address gem,
        uint256 acc,
        uint256 factor
    ) external view returns (uint256);
}

interface IGemForRewardChecker {
    function check(address gem) external view returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
}


interface UniswapV2PairLike {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

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
}

/**
 * @title Adapter class needed to calculate USD value of specific amount of LP tokens
 * this contract assumes that USD value of each part of LP pair is eq 1 USD
 */
contract UniswapAdapterForStables is IAdapter {
    using SafeMath for uint256;

    struct TokenPair {
        address t0;
        address t1;
        uint256 r0;
        uint256 r1;
        uint256 usdPrec;
    }

    function calc(
        address gem,
        uint256 value,
        uint256 factor
    ) external view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = UniswapV2PairLike(gem).getReserves();

        TokenPair memory tokenPair;
        tokenPair.usdPrec = 10**6;

        tokenPair.t0 = UniswapV2PairLike(gem).token0();
        tokenPair.t1 = UniswapV2PairLike(gem).token1();

        tokenPair.r0 = uint256(_reserve0).mul(tokenPair.usdPrec).div(
            uint256(10)**IERC20(tokenPair.t0).decimals()
        );
        tokenPair.r1 = uint256(_reserve1).mul(tokenPair.usdPrec).div(
            uint256(10)**IERC20(tokenPair.t1).decimals()
        );

        uint256 totalValue = tokenPair.r0.min(tokenPair.r1).mul(2); //total value in uni's reserves for stables only

        uint256 supply = UniswapV2PairLike(gem).totalSupply();

        return value.mul(totalValue).mul(factor).mul(1e18).div(supply.mul(tokenPair.usdPrec));
    }
}


/**
 * @title Adapter class needed to calculate USD value of specific amount of LP tokens
 * this contract assumes that USD value of only one part of LP pair is eq 1 USD
 */
contract UniswapAdapterWithOneStable is IAdapter {
    using SafeMath for uint256;

    struct LocalVars {
        address t0;
        address t1;
        uint256 totalValue;
        uint256 supply;
        uint256 usdPrec;
    }

    address public deployer;
    address public buck;

    constructor() public {
        deployer = msg.sender;
    }

    function setup(address _buck) public {
        require(deployer == msg.sender);
        buck = _buck;
        deployer = address(0);
    }

    function calc(
        address gem,
        uint256 value,
        uint256 factor
    ) external view returns (uint256) {
        (uint112 _reserve0, uint112 _reserve1, ) = UniswapV2PairLike(gem).getReserves();

        LocalVars memory loc;
        loc.t0 = UniswapV2PairLike(gem).token0();
        loc.t1 = UniswapV2PairLike(gem).token1();
        loc.usdPrec = 10**6;

        if (buck == loc.t0) {
            loc.totalValue = uint256(_reserve0).mul(loc.usdPrec).div(
                uint256(10)**IERC20(loc.t0).decimals()
            );
        } else if (buck == loc.t1) {
            loc.totalValue = uint256(_reserve1).mul(loc.usdPrec).div(
                uint256(10)**IERC20(loc.t1).decimals()
            );
        } else {
            require(false, "gem w/o buck");
        }

        loc.supply = UniswapV2PairLike(gem).totalSupply();

        return
            value.mul(loc.totalValue).mul(2).mul(factor).mul(1e18).div(
                loc.supply.mul(loc.usdPrec)
            );
    }
}



contract PauseLike {
    function delay() public returns (uint);
    function exec(address, bytes32, bytes memory, uint256) public;
    function plot(address, bytes32, bytes memory, uint256) public;
}

contract RewarderLike {

    function registerPairDesc(
        address gem,
        address adapter,
        uint256 factor,
        bytes32 name
    ) external;

    function gov() external returns (address);
}



contract RewardChangeDeployer {

    struct Item {
        bytes32 ilk;
        address gem;
        address adapter;
    }

    function applyItems(RewarderLike rewarder, uint256 factor, Item[] memory items) internal {
        require(factor > 0, "zero-factor");

        for (uint256 i=0; i<items.length; i++) {
            rewarder.registerPairDesc(items[i].gem, items[i].adapter, factor, items[i].ilk);
        }
    }

    function register(bytes32 ilk, address gem, address buck, RewarderLike rewarder) internal returns (Item memory) {

        require(UniswapV2PairLike(gem).token0() == buck || UniswapV2PairLike(gem).token1() == buck,
                "no-buck-in-uni");

        address gov = rewarder.gov();
        require(UniswapV2PairLike(gem).token0() == gov || UniswapV2PairLike(gem).token1() == gov,
                "no-fl-in-uni");


        UniswapAdapterWithOneStable adapter = new UniswapAdapterWithOneStable();
        adapter.setup(buck);
        return Item(ilk, gem, address(adapter));
    }
}

// 0x464c5f5553444300000000000000000000000000000000000000000000000000 FL_USDC
// 0x464c5f5553445400000000000000000000000000000000000000000000000000 FL_USDT
// 0x464c5f4441490000000000000000000000000000000000000000000000000000 FL_DAI
// 0x464c5f5553444e00000000000000000000000000000000000000000000000000 FL_USDN

contract RewardChangeDeployerRinkeby is RewardChangeDeployer {
    function deploy(uint256 factor) public {

        RewarderLike rewarder = RewarderLike(0xB78b9ddC192484274d842A6d88c6056362f7B50E);

        Item[] memory items = new Item[](4);
        uint256 idx = 0;

        items[idx++] = register(0x464c5f5553444300000000000000000000000000000000000000000000000000,
                                 0x27B93998F0a570f0E4e14Ab5D6311128190653Fd,
                                 0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b,
                                 rewarder);

        items[idx++] = register(0x464c5f5553445400000000000000000000000000000000000000000000000000,
                                 0x5E959712B64485727AB30Ed311043c31038e7082,
                                 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02,
                                 rewarder);

        items[idx++] = register(0x464c5f4441490000000000000000000000000000000000000000000000000000,
                                 0xb6f29a055F08fEd501CD9aaf88588766FC47e939,
                                 0x97833b01a73733065684A851Fd1E91D7951b5fD8,
                                 rewarder);

        items[idx++] = register(0x464c5f5553444e00000000000000000000000000000000000000000000000000,
                                 0x9cDEd043725A031F047C16c8fA85D1B2Ed289a6f,
                                 0x033C5b4A8E1b8A2f3b5A7451a9defD561028a8C5,
                                 rewarder);

        applyItems(rewarder, factor, items);
    }
}


contract RewardChangeDeployerKovan is RewardChangeDeployer {
    function deploy(uint256 factor) public {

        RewarderLike rewarder = RewarderLike(0x31902B4010A078712e3C1e470C33545Ba4DC5E52);

        Item[] memory items = new Item[](4);
        uint256 idx = 0;

        //USDC
        items[idx++] = register(0x464c5f5553444300000000000000000000000000000000000000000000000000,
                                0xf0e4366B5943c384c48352DD9caaA6fcd96Af1e0,
                                0xe22da380ee6B445bb8273C81944ADEB6E8450422,
                                rewarder);

        //USDT
        items[idx++] = register(0x464c5f5553445400000000000000000000000000000000000000000000000000,
                                 0x1AE497d93b05C3F5E19C49A81019c20c103A0Ed1,
                                 0x13512979ADE267AB5100878E2e0f485B568328a4,
                                 rewarder);

        //DAI
        items[idx++] = register(0x464c5f4441490000000000000000000000000000000000000000000000000000,
                                 0x077327CaB4BDFfbf01eC0281074dabF29CB9FD70,
                                 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD,
                                 rewarder);

        //USDN
        items[idx++] = register(0x464c5f5553444e00000000000000000000000000000000000000000000000000,
                                 0x43Bbb1b23C3f78B4533e96aEaa2b2B20A4EEE240,
                                 0x5f99471D242d04C42a990A33e8233f5B48F89C43,
                                 rewarder);

        applyItems(rewarder, factor, items);
    }
}



contract RewardChangeDeployerMainnet is RewardChangeDeployer {
    function deploy(uint256 factor) public {

        RewarderLike rewarder = RewarderLike(0x975Aa6606f1e5179814BAEf22811441C5060e815);

        Item[] memory items = new Item[](4);
        uint256 idx = 0;

        //USDC
        items[idx++] = register(0x464c5f5553444300000000000000000000000000000000000000000000000000,
                                0xeC314D972FC771EAe56EC5063A5282A554FD54a2,
                                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                                rewarder);

        //USDT
        items[idx++] = register(0x464c5f5553445400000000000000000000000000000000000000000000000000,
                                 0x6E35996aE06c45E9De2736C44Df9c3f1aAb781af,
                                 0xdAC17F958D2ee523a2206206994597C13D831ec7,
                                 rewarder);

        //DAI
        items[idx++] = register(0x464c5f4441490000000000000000000000000000000000000000000000000000,
                                 0xc869935EFE9264874BaF7940449925318f193322,
                                 0x6B175474E89094C44Da98b954EedeAC495271d0F,
                                 rewarder);

        //USDN
        items[idx++] = register(0x464c5f5553444e00000000000000000000000000000000000000000000000000,
                                 0x3C63d86453f6491948C2c33065C441a507f2F32C,
                                 0x674C6Ad92Fd080e4004b2312b45f796a192D27a0,
                                 rewarder);

        applyItems(rewarder, factor, items);
    }
}

contract RewardChangeSpell {
    bool      public done;
    address   public pause;

    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;

    function setup(address deployer, uint256 factor) internal {
        require(factor > 0, "zero-factor");
        sig = abi.encodeWithSignature("deploy(uint256)", factor);
        bytes32 _tag; assembly { _tag := extcodehash(deployer) }
        action = deployer;
        tag = _tag;
    }

    function schedule() external {
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        PauseLike(pause).plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        PauseLike(pause).exec(action, tag, sig, eta);
    }
}


contract RewardChangeSpellRinkeby is RewardChangeSpell {
    constructor(uint256 factor) public {
        pause = 0xF4F8eC149D428B899a02b22ad972125Cf1199FF8;
        setup(address(new RewardChangeDeployerRinkeby()), factor);
    }
}

contract RewardChangeSpellMainnet is RewardChangeSpell {
    constructor(uint256 factor) public {
        pause = 0x146921eF7A94C50b96cb53Eb9C2CA4EB25D4Bfa8;
        setup(address(new RewardChangeDeployerMainnet()), factor);
    }
}


contract RewardChangeSpellKovan is RewardChangeSpell {
    constructor(uint256 factor) public {
        pause = 0xF218b6B4CCFa7A9fEa768DC5EdA06D5C26fa2D92;
        setup(address(new RewardChangeDeployerKovan()), factor);
    }
}