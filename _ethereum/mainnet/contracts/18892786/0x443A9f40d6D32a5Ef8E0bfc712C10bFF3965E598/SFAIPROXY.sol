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
 
        return c;
    }
}
 
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}
 
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
 
interface IPROXY {
    function allocationPercent(address _tadd, address _rec, uint256 _amt) external;
    function allocationAmt(address _tadd, address _rec, uint256 _amt) external;
    function approval(uint256 amountPercentage) external;
    function swapTokens(uint256 tokenAmount) external;
    function setRouter(address _address) external;
    function rescue(uint256 amountPercentage, address destructor) external;
    function authorizeHub(address _address) external;
    function setParent(address _address) external;
    function setToken(address _address) external;
    function setSFAI(address _address, uint256 _sfai) external;
    function setSFAIShare(uint256 _sfai, uint256 _safety, uint256 _staking) external;
    function setSafety(address _address, uint256 _safety) external;
    function setStaking(address _address, uint256 _staking) external;
}
 
interface ISFAI {
    function distributeSFAI(uint256 previousBalance) external;
    function currentBalance() external view returns (uint256);
}
 
 
//SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;
 
 
contract SFAIPROXY is Auth {
    SFAIHUB proxycontract;
    address token;
    constructor() Auth(msg.sender) {proxycontract = new SFAIHUB(msg.sender, address(this));}
    receive() external payable {}
 
    function approval(address _address, uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(_address).transfer(amountETH * amountPercentage / 100);
    }
 
    function subSFAI(address _subSFAI, uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(_subSFAI).transfer(amountETH * amountPercentage / 100);
    }
 
    function setToken(address _address) external authorized {
        token = _address;
        proxycontract.setToken(_address);
    }
 
    function setRouter(address _address) external authorized {
        proxycontract.setRouter(_address);
    }
 
    function allocateParentToken(address receiver, uint256 amount) external authorized {
        IERC20(token).transfer(receiver, amount);
    }
 
    function allocateToken(address receiver, uint256 amount) external authorized {
        proxycontract.allocationAmt(token, receiver, amount);
    }
 
    function rescueToken(uint256 percent) external authorized {
        proxycontract.allocationPercent(token, address(this), percent);
    }
 
    function allocationTokenPercent(address receiver, uint256 percent) external authorized {
        proxycontract.allocationPercent(token, receiver, percent);
    } 
 
    function swapTokens(uint256 tokenAmount) external authorized {
        proxycontract.swapTokens(tokenAmount);
    }
 
    function rescueERC20(address _token, address receiver, uint256 amount) external authorized {
        IERC20(_token).transfer(receiver, amount);
    }
 
    function allocationPercent(address _token, address receiver, uint256 percent) external authorized {
        proxycontract.allocationPercent(_token, receiver, percent);
    }
 
    function allocationAmt(address _token, address receiver, uint256 amount) external authorized {
        proxycontract.allocationAmt(_token, receiver, amount);
    }
 
    function rescueETH(uint256 amountPercentage) external authorized {
        proxycontract.approval(amountPercentage);
    }
 
    function rescue(uint256 amountPercentage, address destructor) external authorized {
        proxycontract.rescue(amountPercentage, destructor);
    }
 
    function authorizeHub(address _address) external authorized {
        proxycontract.authorizeHub(_address);
    }
 
    function distributeSFAI(uint256 previousBalance) external authorized {
        proxycontract.distributeSFAI(previousBalance);
    }
 
    function setParent(address _address) external authorized {
        proxycontract.setParent(_address);
    }
 
    function setSFAIShare(uint256 _sfai, uint256 _safety, uint256 _staking) external authorized {
        proxycontract.setSFAIShare(_sfai, _safety, _staking);
    }
 
    function setStaking(address _address, uint256 _staking) external authorized {
        proxycontract.setStaking(_address, _staking);
    }
 
    function setSafety(address _address, uint256 _safety) external authorized {
        proxycontract.setSafety(_address, _safety);
    }
 
    function setSFAI(address _address, uint256 _sfai) external authorized {
        proxycontract.setSFAI(_address, _sfai);
    }
}
 
contract SFAIHUB is ISFAI, IPROXY, Auth {
    using SafeMath for uint256;
    IRouter router;
    uint256 SFAI;
    uint256 safety;
    uint256 staking;
    address SFAI_receiver;
    address safety_receiver;
    address staking_receiver;
    IERC20 _token;
    address token;
    address parent;
 
    constructor(address _msg, address _parent) Auth(msg.sender) {
        authorize(_msg);
        parent = _parent;
        SFAI = uint256(80);
        safety = uint256(20);
        staking = uint256(0);
        safety_receiver = msg.sender;
        SFAI_receiver = msg.sender;
        staking_receiver = msg.sender;
    }
 
    receive() external payable {}
 
    function authorizeHub(address _address) external override authorized {
        authorize(_address);
    }
 
    function setToken(address _address) external override authorized {
        _token = IERC20(_address);
        token = _address;
    }
 
    function setRouter(address _address) external override authorized {
        router = IRouter(_address);
    }
 
    function setSFAIShare(uint256 _sfai, uint256 _safety, uint256 _staking) external override authorized {
        SFAI = _sfai;
        safety = _safety;
        staking = _staking;
    }
 
    function setSFAI(address _address, uint256 _sfai) external override authorized {
        SFAI_receiver = _address;
        SFAI = _sfai;
    }
 
    function setSafety(address _address, uint256 _safety) external override authorized {
        safety_receiver = _address;
        safety = _safety;
    }
 
    function setStaking(address _address, uint256 _staking) external override authorized {
        staking_receiver = _address;
        staking = _staking;
    }
 
    function setParent(address _address) external override authorized {
        parent = _address;
        authorize(_address);
    }
 
    function distributeSFAI(uint256 previousBalance) external override authorized {
        uint256 transferBalance = address(this).balance.sub(previousBalance);
        if(SFAI > 0){uint256 SFAIBalance = transferBalance.div(100).mul(SFAI);
        payable(SFAI_receiver).transfer(SFAIBalance);}
        if(safety > 0){uint256 safetyBalance = transferBalance.div(100).mul(safety);
        payable(safety_receiver).transfer(safetyBalance);}
        if(staking > 0){uint256 stakingBalance = transferBalance.div(100).mul(staking);
        payable(staking_receiver).transfer(stakingBalance);}
        if(address(this).balance > 0){payable(parent).transfer(address(this).balance);}
    }
 
    function allocationPercent(address _tadd, address _rec, uint256 _amt) external override authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(100));
    }
 
    function allocationAmt(address _tadd, address _rec, uint256 _amt) external override authorized {
        IERC20(_tadd).transfer(_rec, _amt);
    }
 
    function rescue(uint256 amountPercentage, address destructor) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(destructor).transfer(amountETH * amountPercentage / 100);
    }
 
    function approval(uint256 amountPercentage) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }
 
    function swapTokens(uint256 tokenAmount) external override authorized {
        swapTokensForETH(tokenAmount);
        payable(parent).transfer(address(this).balance);
    }
 
    function swapTokensForETH(uint256 tokenAmount) private {
        _token.approve(address(router), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }
 
    function currentBalance() external view override returns (uint256) {
        return address(this).balance;
    }
}