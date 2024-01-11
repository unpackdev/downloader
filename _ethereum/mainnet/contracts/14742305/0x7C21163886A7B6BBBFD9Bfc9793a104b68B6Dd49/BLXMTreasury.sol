// SPDX-License-Identifier: GPL-3.0 License

pragma solidity >=0.8.0;

import "./BLXMMultiOwnable.sol";
import "./IBLXMTreasury.sol";

import "./IERC20.sol";
import "./TransferHelper.sol";
import "./BLXMLibrary.sol";


contract BLXMTreasury is BLXMMultiOwnable, IBLXMTreasury {

    address public override BLXM;
    address public override SSC;

    mapping(address => bool) public override whitelist;

    uint public override totalBlxm;
    uint public override totalRewards;
    mapping(address => uint) public override balanceOf;


    modifier onlySsc() {
        require(msg.sender == SSC, 'NOT_SSC');
        _;
    }

    function initialize(address _BLXM, address _SSC) public initializer {
        __BLXMMultiOwnable_init();
        
        SSC = _SSC;
        BLXM = _BLXM;
    }

    function addRewards(uint amount) external override onlySsc {
        require(amount != 0, 'INSUFFICIENT_AMOUNT');
        totalRewards += amount;
    }

    function addBlxmTokens(uint amount, address to) external override onlySsc {
        BLXMLibrary.validateAddress(to);
        balanceOf[to] += amount;
        totalBlxm += amount;
    }

    function retrieveBlxmTokens(address from, uint amount, uint rewardAmount, address to) external override onlySsc {
        BLXMLibrary.validateAddress(from);
        BLXMLibrary.validateAddress(to);

        uint _balance = balanceOf[from];
        require(_balance >= amount, 'INSUFFICIENT_BALANCE');
        uint _totalBlxm = totalBlxm;
        require(_totalBlxm >= amount, 'INSUFFICIENT_BLXM');
        uint _totalRewards = totalRewards;
        require(totalRewards >= rewardAmount, 'INSUFFICIENT_REWARDS');
        uint totalTransfer = rewardAmount + amount;
        require(IERC20(BLXM).balanceOf(address(this)) >= totalTransfer, 'INSUFFICIENT_CONTRACT_BALANCE');

        totalBlxm = _totalBlxm - amount;
        balanceOf[from] = _balance - amount;
        totalRewards = _totalRewards - rewardAmount;
        TransferHelper.safeTransfer(BLXM, to, totalTransfer);
    }

    function addWhitelist(address wallet) external override onlyOwner {
        BLXMLibrary.validateAddress(wallet);
        require(!whitelist[wallet], 'IS_WHITELIST');
        whitelist[wallet] = true;
        emit Whitelist(msg.sender, true, wallet);
    }

    function removeWhitelist(address wallet) external override onlyOwner {
        BLXMLibrary.validateAddress(wallet);
        require(whitelist[wallet], 'NOT_WHITELIST');
        whitelist[wallet] = false;
        emit Whitelist(msg.sender, false, wallet);
    }

    function sendTokensToWhitelistedWallet(uint amount, address to) external override onlyOwner {
        require(whitelist[to], 'NOT_IN_WHITELIST');
        require(IERC20(BLXM).balanceOf(address(this)) >= amount, 'NOT_ENOUGH_AMOUNT');

        TransferHelper.safeTransfer(BLXM, to, amount);
        emit SendTokensToWhitelistedWallet(msg.sender, amount, to);
    }

    /**
    * This empty reserved space is put in place to allow future versions to add new
    * variables without shifting down storage in the inheritance chain.
    * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    */
    uint256[50] private __gap;
}