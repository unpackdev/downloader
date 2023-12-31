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
interface IUniswapAnchoredView {
    function price(string memory symbol) external view returns (uint256);
}

contract CompoundOracle is IOracle {
    using BoringMath for uint256;

    struct PairInfo {
        string collateralSymbol;
        string supplySymbol;
        uint256 rate;
    }

    mapping(address => PairInfo) pairs;

    function init(string calldata collateralSymbol, string calldata supplySymbol, address pair) public {
        // The rate can only be set once. It cannot be changed.
        if (bytes(pairs[pair].collateralSymbol).length == 0) {
            pairs[pair].collateralSymbol = collateralSymbol;
            pairs[pair].supplySymbol = supplySymbol;
        }
    }

    function getInitData(string calldata collateralSymbol, string calldata supplySymbol) public pure returns (bytes memory) {
        return abi.encode(collateralSymbol, supplySymbol);
    }

    function _get(string memory collateralSymbol, string memory supplySymbol) private view returns (uint256) {
        return uint256(1e18)
            .mul(IUniswapAnchoredView(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1).price(collateralSymbol))
            .div(IUniswapAnchoredView(0x922018674c12a7F0D394ebEEf9B58F186CdE13c1).price(supplySymbol));
    }

    // Get the latest exchange rate
    function get(address pair) public override returns (bool, uint256) {
        pairs[pair].rate = _get(pairs[pair].collateralSymbol, pairs[pair].supplySymbol);
        return (true, pairs[pair].rate);
    }

    // Check the last exchange rate without any state changes
    function peek(address pair) public view override returns (uint256) {
        return _get(pairs[pair].collateralSymbol, pairs[pair].supplySymbol);
    }

    function test(string calldata collateralSymbol, string calldata supplySymbol) public view returns(uint256) {
        return _get(collateralSymbol, supplySymbol);
    }
}