pragma solidity >=0.6.6;

import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./ICAVO.sol";
import "./IExcavoERC20.sol";
import "./IxCAVO.sol";
import "./IEXCV.sol";
import "./IExcavoFactory.sol";

contract BaseCAVO is ICAVO, IExcavoERC20, ReentrancyGuard {
    using SafeMath for uint;

    string public constant override name = 'CAVO';
    string public constant override symbol = 'CAVO';
    uint8 public constant override decimals = 18;
    
    uint public constant override MAX_SUPPLY = 10**6 * 10**18;
    uint public constant override CREATOR_SUPPLY = 200 ether + 120 ether;

    address public override xCAVOToken;
    address public immutable override creator;
    address public override EXCVToken;

    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    mapping(address => uint) private lastBalanceOf;
    mapping(address => uint) private lastBalanceBlockOf;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        creator = msg.sender;
        _mint(msg.sender, CREATOR_SUPPLY);
    }

    function initialize(address _factory) external override nonReentrant {
        require(msg.sender == creator && IEXCV(EXCVToken).factory() == address(0), 'EXCV: FORBIDDEN');
        IEXCV(EXCVToken).initialize(_factory);
        IxCAVO(xCAVOToken).initialize(_factory, EXCVToken);
    }

    function virtualBalanceOf(address account) external view override returns (uint) {
        uint balance = balanceOf[account];
        if (block.number - lastBalanceBlockOf[account] > 0) {
            return balance;
        }
        uint lastBalance = lastBalanceOf[account];
        return balance < lastBalance ? balance : lastBalance;
    }

    function mint(address account, uint256 amount) external override nonReentrant {
        require(msg.sender == xCAVOToken, 'Excavo: FORBIDDEN');
        _mint(account, amount);
    }

    function _mint(address to, uint value) internal {
        _saveLastBalance(to);
        uint _value = Math.min(value, MAX_SUPPLY.sub(totalSupply));
        totalSupply = totalSupply.add(_value);
        balanceOf[to] = balanceOf[to].add(_value);
        emit Transfer(address(0), to, _value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) internal {
        _saveLastBalance(from);
        _saveLastBalance(to);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external virtual override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function _saveLastBalance(address account) private {
        if (block.number - lastBalanceBlockOf[account] > 0) {
            lastBalanceOf[account] = balanceOf[account];
            lastBalanceBlockOf[account] = block.number;
        } 
    }
}
