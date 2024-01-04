// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.6.12;

contract Ownable {
    address payable public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

abstract contract ProxyKyberSwap {
    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    ) virtual external view returns (uint256 expectedRate, uint256 worstRate);
}
contract StrongWalletPresale is Ownable {
    using SafeMath for uint256;

    uint public presaleAmount = 3000000 ether;
    ProxyKyberSwap public proxyKyberSwap = ProxyKyberSwap(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);
    ERC20 public STRONG = ERC20(0xf217f7df49f626f83f40D7D5137D663B1ec4EE6E);
    ERC20 constant public ETH_TOKEN_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    ERC20 constant public USDT_TOKEN_ADDRESS = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    mapping(address => uint) public sellers;

    address[] public lengthSeller;
    // event
    event DepositETH();
    event DepositUSDT();
    event DepositETHWithSeller(address receiver, uint amount, uint amountStrong, address _seller);
    event DepositUSDTWithSeller(address receiver, uint amount, uint amountStrong, address _seller);
    event LogWithdrawal(address _to, uint _amountStrong);

    constructor() public {}
    function getRate(uint _usdtAmount) public pure returns(uint _rate) {
        if(_usdtAmount <= 100 ether) _rate = 160;
        else if(_usdtAmount <= 1000 ether) _rate = 150;
        else if(_usdtAmount <= 5000 ether) _rate = 135;
        else if(_usdtAmount <= 10000 ether) _rate = 125;
        else if(_usdtAmount <= 50000 ether) _rate = 115;
        else  _rate = 100;
    }
    function USDT2Strong(uint _usdtAmount) public pure returns(uint _amountStrong) {
        return _usdtAmount.mul(1000).div(getRate(_usdtAmount));
    }
    function ETH2USDT() public view returns (uint _amountUsdt){
        (_amountUsdt,) = proxyKyberSwap.getExpectedRate(ETH_TOKEN_ADDRESS, USDT_TOKEN_ADDRESS, 1 ether);
    }
    function ETH2STRONG(uint _amountETH) public view returns(uint _amountStrong) {
        uint256 usdtAmount = ETH2USDT().mul(_amountETH).div(1 ether);
        _amountStrong = USDT2Strong(usdtAmount);
    }
    function depositEth() public payable {
        owner.transfer(msg.value);
        STRONG.transfer(msg.sender, ETH2STRONG(msg.value));
        emit DepositETH();
    }
    function depositUSDT(uint256 _amountUsdt) public {
        require(USDT_TOKEN_ADDRESS.transferFrom(msg.sender, owner, _amountUsdt));
        STRONG.transfer(msg.sender,  USDT2Strong(_amountUsdt));
        emit DepositUSDT();
    }

    function depositEthWithSeller(address _seller) public payable {
        require(msg.sender != _seller);
        uint amountStrong = ETH2STRONG(msg.value);
        owner.transfer(msg.value);
        STRONG.transfer(msg.sender, amountStrong);
        uint bonusPercent = 2;
        if(sellers[_seller] == 0) {
            bonusPercent = 5;
            sellers[_seller] += amountStrong;
        }
        STRONG.transfer(_seller, amountStrong.mul(bonusPercent).div(100));
        
        emit DepositETHWithSeller(msg.sender, msg.value, amountStrong, _seller);
    }
    function depositUSDTWithSeller(uint256 _amountUsdt, address _seller) public {
        require(msg.sender != _seller);
        require(USDT_TOKEN_ADDRESS.transferFrom(msg.sender, owner, _amountUsdt));
        STRONG.transfer(msg.sender,  USDT2Strong(_amountUsdt));
        uint amountStrong = USDT2Strong(_amountUsdt);
        uint bonusPercent = 2;
        if(sellers[_seller] == 0) {
            bonusPercent = 5;
            sellers[_seller] += amountStrong;
        }
        STRONG.transfer(_seller, amountStrong.mul(bonusPercent).div(100));
        emit DepositUSDTWithSeller(msg.sender, _amountUsdt, amountStrong, _seller);
    }
    /**
    * @dev Withdraw the amount of token that is remaining in this contract.
    * @param _address The address of EOA that can receive token from this contract.
    */
    function withdraw(address _address) public onlyOwner {
        uint tokenBalanceOfContract = getRemainingToken();
        STRONG.transfer(_address, tokenBalanceOfContract);
        emit LogWithdrawal(_address, tokenBalanceOfContract);
    }

    /**
    * @dev Get the remaining amount of token user can receive.
    * @return Uint256 the amount of token that user can reveive.
    */
    function getRemainingToken() public view returns (uint256) {
        return STRONG.balanceOf(address(this));
    }
}