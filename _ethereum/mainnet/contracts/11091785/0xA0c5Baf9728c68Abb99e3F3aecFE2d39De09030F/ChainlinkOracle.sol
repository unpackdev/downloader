// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;


// 
// TODO: Needs testing to make sure math is correct and overflow/underflows are caught in all cases
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) { uint256 c = a + b; require(c >= b, "BoringMath: Overflow"); return c; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { require(b <= a, "BoringMath: Underflow"); return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
        { if (a == 0) {return 0;} uint256 c = a * b; require(c / a == b, "BoringMath: Overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { require(b > 0, "BoringMath: Div by 0"); return a / b; }
}

// 
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
// Edited by BoringCrypto
// - removed GSN context
// - removed comments (we all know this contract)
// - updated solidity version
// - made _owner public and renamed to owner
// - simplified code
// - onlyOwner modifier removed. Just copy the one line. Cheaper in gas, better readability and better error message.
// TODO: Consider using the version that requires acceptance from new owner
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function renounceOwnership() public virtual {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

// 
interface IOracle {
    // Each oracle should have a set function. The first parameter will be 'address pair' and any parameters can come after.
    // Setting should only be allowed ONCE for each pair.

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    function get(address pair) external returns (bool, uint256);

    // Check the last exchange rate without any state changes
    function peek(address pair) external view returns (uint256);
}

// 
// ChainLink Aggregator
interface IAggregator {
    function latestRoundData() external view returns (uint80, int256 answer, uint256, uint256, uint80);
}

contract ChainlinkOracle is Ownable, IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    struct SymbolPair {
        address multiply;   // The ChainLink price to multiply by to get rate
        address divide;     // The ChainLink price to divide by to get rate
        uint256 decimals;   // Just pre-calc and store as something like 10000000000000000000000.
        uint256 rate;
    }

    mapping(address => SymbolPair) symbols;

    function init(address multiply, address divide, uint256 decimals, address pair) public {
        require(msg.sender == owner, "ChainlinkOracle: not owner");

        // The rate can only be set once. It cannot be changed.
        if (symbols[pair].decimals == 0) {
            symbols[pair].multiply = multiply;
            symbols[pair].divide = divide;
            symbols[pair].decimals = decimals;
        }
    }

    function getInitData(address multiply, address divide, uint256 decimals) public pure returns (bytes memory) {
        return abi.encode(multiply, divide, decimals);
    }

    function _get(address multiply, address divide, uint256 decimals) public view returns (uint256) {
        uint256 price = uint256(1e18);
        if (multiply != address(0)) {
            (, int256 priceC,,,) = IAggregator(multiply).latestRoundData();
            price = price.mul(uint256(priceC));
        } else {
            price = price.mul(1e18);
        }

        if (divide != address(0)) {
            (, int256 priceC,,,) = IAggregator(divide).latestRoundData();
            price = price.div(uint256(priceC));
        }

        return price.div(decimals);
    }

    // Get the latest exchange rate
    function get(address pair) public override returns (bool, uint256) {
        SymbolPair storage s = symbols[pair];
        uint256 rate = _get(s.multiply, s.divide, s.decimals);
        s.rate = rate;
        return (true, rate);
    }

    // Check the last exchange rate without any state changes
    function peek(address pair) public override view returns (uint256) {
        SymbolPair storage s = symbols[pair];
        return _get(s.multiply, s.divide, s.decimals);
    }

    function test(address multiply, address divide, uint256 decimals) public view returns(uint256) {
        return _get(multiply, divide, decimals);
    }
}