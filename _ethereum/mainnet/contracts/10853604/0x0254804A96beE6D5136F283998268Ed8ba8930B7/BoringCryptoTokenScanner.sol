pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function owner() external view returns (address);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISushiSwapPoolNames {
    function logos(uint256) external view returns(string memory);
    function names(uint256) external view returns(string memory);
    function setPoolInfo(uint256 pid, string memory logo, string memory name) external;
}

interface ISushiToken is IERC20{
    function delegates(address who) external view returns(address);
    function getCurrentVotes(address who) external view returns(uint256);
    function nonces(address who) external view returns(uint256);
}

interface IMasterChef {
    function BONUS_MULTIPLIER() external view returns (uint256);
    function bonusEndBlock() external view returns (uint256);
    function devaddr() external view returns (address);
    function migrator() external view returns (address);
    function owner() external view returns (address);
    function startBlock() external view returns (uint256);
    function sushi() external view returns (address);
    function sushiPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);
    function poolInfo(uint256 nr) external view returns (address, uint256, uint256, uint256);
    function userInfo(uint256 nr, address who) external view returns (uint256, uint256);
    function pendingSushi(uint256 nr, address who) external view returns (uint256);
}

interface IFactory {
    function getPair(address token0, address token1) external view returns (address);
}

interface IPair is IERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Underflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Mul Overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Div by 0");
        uint256 c = a / b;

        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BoringCryptoTokenScanner is Ownable
{
    using SafeMath for uint256;

    mapping(uint256 => address) public tokens;
    uint256 public tokenCount;

    function add(address token) public onlyOwner {
        tokens[tokenCount] = token;
        tokenCount++;
    }
    
    function change(uint256 id, address token) public onlyOwner {
        tokens[id] = token;
    }
    
    function remove() public onlyOwner {
        tokenCount--;
        tokens[tokenCount] = address(0);
    }

    struct Balance {
        address token;
        uint256 balance;
    }
    
    struct TokenInfo {
        address token;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getInfo(address[] calldata extra) public view returns(TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](tokenCount + extra.length);

        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20 token = IERC20(tokens[i]);
            infos[i].token = address(token);
            infos[i].decimals = token.decimals();
            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
        }

        for (uint256 i = 0; i < extra.length; i++) {
            IERC20 token = IERC20(extra[i]);
            uint256 index = tokenCount + i;
            infos[index].token = address(token);
            infos[index].decimals = token.decimals();
            infos[index].name = token.name();
            infos[index].symbol = token.symbol();
        }

        return infos;
    }

    function getSpecificInfo(address[] calldata extra) public view returns(TokenInfo[] memory) {
        TokenInfo[] memory infos = new TokenInfo[](extra.length);

        for (uint256 i = 0; i < extra.length; i++) {
            IERC20 token = IERC20(extra[i]);
            infos[i].token = address(token);
            infos[i].decimals = token.decimals();
            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
        }

        return infos;
    }

    function getBalances(address who, address[] calldata extra) public view returns(Balance[] memory) {
        Balance[] memory balances = new Balance[](tokenCount + extra.length);

        for (uint256 i = 0; i < tokenCount; i++) {
            IERC20 token = IERC20(tokens[i]);
            balances[i].token = address(token);
            balances[i].balance = token.balanceOf(who);
        }
        
        for (uint256 i = 0; i < extra.length; i++) {
            IERC20 token = IERC20(extra[i]);
            balances[tokenCount + i].token = address(token);
            balances[tokenCount + i].balance = token.balanceOf(who);
        }
        
        return balances;
    }

    function getSpecificBalances(address who, address[] calldata extra) public view returns(Balance[] memory) {
        Balance[] memory balances = new Balance[](extra.length);

        for (uint256 i = 0; i < extra.length; i++) {
            IERC20 token = IERC20(extra[i]);
            balances[i].token = address(token);
            balances[i].balance = token.balanceOf(who);
        }
        
        return balances;
    }
}


