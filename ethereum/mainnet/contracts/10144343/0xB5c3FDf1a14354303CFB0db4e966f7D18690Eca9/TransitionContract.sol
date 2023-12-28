pragma solidity ^0.5.13;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
      if (a == 0) {
        return 0;
      }
      c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
      c = a + b;
      assert(c >= a);
      return c;
    }
}

contract EXCH {
    function distributePool(uint256 _amount) public;
}

contract TEWKEN {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function isMinter(address account) public view returns (bool);
    function renounceMinter() public;
    function mint(address account, uint256 amount) public returns (bool);
    function cap() public view returns (uint256);
}

contract ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external;
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;
    function stakeCount(address stakerAddr) external view returns (uint256);
    function stakeLists(address owner, uint256 stakeIndex) external view returns (uint40, uint72, uint72, uint16, uint16, uint16, bool);
    function currentDay() external view returns (uint256);
}

contract TransitionContract {
    using SafeMath for uint256;

    modifier onlyOwner() {
      require(msg.sender == owner);
      _;
    }

    modifier onlyCustodian() {
        require(msg.sender == custodianAddress);
        _;
    }

    event onTransform(
        address indexed customerAddress,
        uint256 incomingHEX,
        uint256 tokensMinted,
        uint256 timestamp
    );

    uint256 public totalMintedTewken = 0;
    uint256 public totalTransformHEX = 0;

    address public owner;
    address public custodianAddress;
    address public approvedAddress1;
    address public approvedAddress2;
    address public stakingAddress;

    EXCH infinihex;
    EXCH stakinghex;
    ERC20 erc20;
    TEWKEN tewken;

    constructor() public {
        owner = address(0x583A013373A9e91fB64CBFFA999668bEdfdcf87C);
        custodianAddress = address(0x20F9b4Cf601DC667C62A73c3FF8bAFEAee4C54d0);
        infinihex = EXCH(address(0x112536829069dDF8868De6F8283eA7C3cD3E6743));
        erc20 = ERC20(address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39));
        tewken = TEWKEN(address(0xb1359e949c32f2Fb61A10215e4D9a2276B0956Ce));
    }

    function() payable external {
        revert();
    }

    function checkAndTransferHEX(uint256 _amount) private {
        require(erc20.transferFrom(msg.sender, address(this), _amount) == true, "transfer must succeed");
    }

    function transform(uint256 _amount) public returns (uint256) {
        require(_amount >= 10000 && totalTransformHEX.add(_amount) <= 1000000000e8); // minimum 0.0001 hex to transform
        checkAndTransferHEX(_amount);

        uint256 _scaledToken = _amount.mul(1e10).div(952);
        require (_scaledToken > 0 && tewken.isMinter(address(this)) && tewken.totalSupply().add(_scaledToken) <= tewken.cap());
        tewken.mint(msg.sender, _scaledToken);

        totalMintedTewken += _scaledToken;
        totalTransformHEX += _amount;

        uint256 _externalFee = _amount.mul(10).div(100);
        erc20.approve(address(0x112536829069dDF8868De6F8283eA7C3cD3E6743), _externalFee);
        infinihex.distributePool(_externalFee);

        emit onTransform(msg.sender, _amount, _scaledToken, now);
    }

    function renounceMinter() onlyOwner public {
        tewken.renounceMinter();
    }

    function approveAddress1(address _proposedAddress) onlyOwner public
    {
        approvedAddress1 = _proposedAddress;
    }

    function approveAddress2(address _proposedAddress) onlyCustodian public
    {
        approvedAddress2 = _proposedAddress;
    }

    function setStakingAddress() onlyOwner public
    {
        require(approvedAddress1 != address(0) && approvedAddress1 == approvedAddress2);
        stakingAddress = approvedAddress1;
        stakinghex = EXCH(stakingAddress);
    }

    function addRewards() onlyOwner public {
        require(stakingAddress != address(0));
        uint256 _balance = erc20.balanceOf(address(this));
        erc20.approve(stakingAddress, _balance);
        stakinghex.distributePool(_balance);
    }
}