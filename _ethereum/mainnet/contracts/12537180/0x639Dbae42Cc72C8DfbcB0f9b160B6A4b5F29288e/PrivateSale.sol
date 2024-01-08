// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Context.sol";
import "./IWhitelist.sol";

contract PrivateSale is Context {
    /**
     * @dev `_usdt` represents the usdt smart contract address.
     * `_admin` is the account that controls the sale.
     */
    address private _usdt;
    address private _whitelist;
    address private _admin;

    /**
     * @dev stores the total unique investement addresses.
     */
    uint256 private _investors;
    mapping(uint256 => address) private _investor;

    /**
     * @dev stores the usdt invested by each account.
     */
    mapping(address => uint256) private _investment;

    /**
     * @dev checks if `caller` is `_admin`
     * reverts if the `caller` is not the `_admin` account.
     */
    modifier onlyAdmin() {
        require(_admin == msgSender(), "Error: caller not admin");
        _;
    }

    /**
     * @dev is emitted when a successful investment is made.
     */
    event Investment(address indexed from, uint256 amount);

    constructor(address _usdtAddress, address _whitelistOracle) {
        _admin = msgSender();
        _usdt = _usdtAddress;
        _whitelist = _whitelistOracle;
    }

    /**
     * @dev invests `_usdtAmount` to the vesting smart contract.
     *
     * Requirements:
     * `_usdtAmount` should be approved by `caller` account.
     * `_usdtAmount` should be greater or equal to balance of `caller` account
     */
    function invest(uint256 _usdtAmount) public virtual returns (bool) {
        require(IWhiteList(_whitelist).whitelisted(msgSender()), "Error: investor not elligible for purchase");

        uint256 balance = IERC20(_usdt).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdt).allowance(msgSender(), address(this));

        require(balance >= _usdtAmount, "Error: insufficient USDT Balance");
        require(
            allowance >= _usdtAmount,
            "Error: allowance less than spending"
        );
        
        if(_investment[msgSender()] == 0) { 
            _investors += 1; 
            _investor[_investors] = msgSender();
        }
        _investment[msgSender()] += _usdtAmount;

        emit Investment(msgSender(), _usdtAmount);
        IERC20(_usdt).transferFrom(msgSender(), address(this), _usdtAmount);
        return true;
    }

    /**
     * @dev returns the amount of usdt invested by `_user`
     */
    function investment(address _user) public view virtual returns (uint256) {
        return _investment[_user];
    }

    /**
     * @dev returns the usdt smart contract used for purchase.
     */
    function usdt() public view returns (address) {
        return _usdt;
    }

    /**
     * @dev returns the total number of investors.
     */
    function totalInvestors() public view returns (uint256) {
        return _investors;
    }

    /**
     * @dev returns individual investor address.
     */
    function investor(uint256 investorId) public view returns (address) {
        return _investor[investorId];
    }

    /**
     * @dev returns the admin account used for purchase.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev transfers ownership to a different account.
     *
     * Requirements:
     * `newAdmin` cannot be a zero address.
     * `caller` should be current admin.
     */
    function transferControl(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "Error: owner cannot be zero");
        _admin = newAdmin;
    }

    /**
     * @dev updates the usdc sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateUsdt(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: owner cannot be zero");
        _usdt = newAddress;
    }

    /**
     * @dev updates the whitelist oracle address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateOracle(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: owner cannot be zero");
        _whitelist = newAddress;
    }

    /**
     * @dev send usdt from SC to any EOA.
     *
     * `caller` should be admin account.
     * `to` cannot be zero address.
     */
    function sendUsdt(address to, uint256 amount)
        public
        virtual
        onlyAdmin
        returns (bool)
    {
        require(to != address(0), "Error: cannot send to zero addresss");
        IERC20(_usdt).transfer(to, amount);
        return true;
    }
}
