// SPDX-License-Identifier: CC-BY-NC-SA-2.5
//@code0x2

pragma solidity ^0.6.12;

interface IFeeManager {
    function queryFee(address sender, address receiver, uint256 amount) external returns(address, uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Standard {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IDynamic {
    function burnFrom(address account, uint256 amount) external;
}

interface IOracle {
    function update() external;

    function nextEpochPoint() external view returns (uint256);

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
    // function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp);
}

contract feeManager is Ownable {
    address public feeReceiver;
    using SafeMath for uint256;
    address public coin;
    address public priceOracle;
    bool public paused;
    bool public enabled;
    mapping (address => bool) internal uniPair;

    constructor (address _feeReceiver) public {
        feeReceiver = _feeReceiver;
    }

    function setFeeReceiver(address _receiver) public onlyOwner {
        feeReceiver = _receiver;
    }

    function setPaused(bool _isPaused) public onlyOwner {
        paused = _isPaused;
    }

    function setOracle(address _oracle) public onlyOwner {
        priceOracle = _oracle;
    }

    function setStatus(bool _enabled) public onlyOwner{
        enabled = _enabled;
    }

    function setCoin(address _coin) public onlyOwner {
        coin = _coin;
    }

    function setUniPair(address _pair, bool _isPair) public onlyOwner {
        uniPair[_pair] = _isPair;
    }

    function queryFee(address sender, address receiver, uint256 amount) public returns (address _feeReceiver, uint256 _feeAmount) {
        require(!paused, 'FeeManager: Transfers paused');
        require(sender != address(0), 'FeeManager: Transfer from zero address');
        if(enabled) {
            if(block.timestamp > IOracle(priceOracle).nextEpochPoint()) IOracle(priceOracle).update();
            uint256 oraclePrice = IOracle(priceOracle).consult(coin, 1e18);
            _feeReceiver = feeReceiver;
            if(uniPair[receiver]) {
                if(oraclePrice >= 980000000000000000) {
                 _feeAmount = 0;
                } else {
                    _feeAmount = 1e18;
                    _feeAmount = amount.mul(_feeAmount.sub(oraclePrice)).div(1e18);
                }
            }
        } else {
            _feeReceiver = feeReceiver;
            _feeAmount = 0;
        }
    }

    function rescueToken(IERC20 _token) public onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}