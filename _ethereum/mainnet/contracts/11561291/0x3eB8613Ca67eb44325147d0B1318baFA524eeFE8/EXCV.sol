pragma solidity >=0.6.6;

import "./IExcavoERC20.sol";
import "./ICAVO.sol";
import "./Math.sol";
import "./xEXCV.sol";

contract EXCV is IEXCV, IExcavoERC20, ReentrancyGuard {
    using SafeMath for uint;

    string public constant override name = 'EXCV';
    string public constant override symbol = 'EXCV';
    uint8 public constant override decimals = 18;

    uint public constant override MAX_SUPPLY = 10**9 * 10**18;
    // TODO: make sure, it's OK
    uint public constant override CREATOR_SUPPLY = 600 * 5 * 10**18;

    address public override immutable xEXCVToken;
    address public override factory;

    uint public override totalSupply;
    mapping(address => uint) public override balanceOf;
    mapping(address => mapping(address => uint)) public override allowance;
    address private immutable creator;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        creator = msg.sender;
        address _xEXCV;
        bytes memory bytecode = type(xEXCV).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("xEXCV"));
        assembly {
            _xEXCV := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        xEXCVToken = _xEXCV;
    }

    function initialize(address _factory) external override nonReentrant {
        require(factory == address(0) && msg.sender == creator, "EXCV: FORBIDDEN");
        factory = _factory;
        IxEXCV(xEXCVToken).initialize(_factory);
        _mint(ICAVO(creator).creator(), CREATOR_SUPPLY);
    }

    function _mint(address to, uint value) internal {
        uint _value = Math.min(value, MAX_SUPPLY.sub(totalSupply));
        totalSupply = totalSupply.add(_value);
        balanceOf[to] = balanceOf[to].add(_value);
        emit Transfer(address(0), to, _value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function mint(address to, uint value) external override nonReentrant {
        require(msg.sender == xEXCVToken, "EXCV: FORBIDDEN");
        _mint(to, value);
    }

    function approve(address spender, uint value) external virtual override nonReentrant returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual override nonReentrant returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}