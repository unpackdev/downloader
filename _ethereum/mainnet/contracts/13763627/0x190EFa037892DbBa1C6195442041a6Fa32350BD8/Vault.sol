
// contracts/Cruise.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract Vault is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Items {
        IERC20 token;
        address withdrawer;
        uint256 amount;
        uint256 unlockTimestamp;
        bool withdrawn;
        bool deposited;
    }

    uint256 public depositsCount;
    mapping (address => uint256[]) public depositsByTokenAddress;
    mapping (address => uint256[]) public depositsByWithdrawers;
    mapping (uint256 => Items) public lockedToken;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;

    address public helpiMarketingAddress;

    event Withdraw(address withdrawer, uint256 amount);

    constructor() {

    }

    function lockTokens(IERC20 _token, address _withdrawer, uint256 _amount, uint256 _unlockTimestamp) external returns (uint256 _id) {
        require(_amount > 500, 'Token amount too low!');
        require(_unlockTimestamp < 10000000000, 'Unlock timestamp is not in seconds!');
        require(_unlockTimestamp > block.timestamp, 'Unlock timestamp is not in the future!');
        require(_token.allowance(msg.sender, address(this)) >= _amount, 'Approve tokens first!');
        _token.safeTransferFrom(msg.sender, address(this), _amount);

        walletTokenBalance[address(_token)][msg.sender] = walletTokenBalance[address(_token)][msg.sender].add(_amount);

        _id = ++depositsCount;
        lockedToken[_id].token = _token;
        lockedToken[_id].withdrawer = _withdrawer;
        lockedToken[_id].amount = _amount;
        lockedToken[_id].unlockTimestamp = _unlockTimestamp;
        lockedToken[_id].withdrawn = false;
        lockedToken[_id].deposited = true;

        depositsByTokenAddress[address(_token)].push(_id);
        depositsByWithdrawers[_withdrawer].push(_id);
        return _id;
    }

    function withdrawTokens(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTimestamp, 'Tokens are still locked!');
        require(msg.sender == lockedToken[_id].withdrawer, 'You are not the withdrawer!');
        require(lockedToken[_id].deposited, 'Tokens are not yet deposited!');
        require(!lockedToken[_id].withdrawn, 'Tokens are already withdrawn!');

        lockedToken[_id].withdrawn = true;

        walletTokenBalance[address(lockedToken[_id].token)][msg.sender] = walletTokenBalance[address(lockedToken[_id].token)][msg.sender].sub(lockedToken[_id].amount);

        emit Withdraw(msg.sender, lockedToken[_id].amount);
        lockedToken[_id].token.safeTransfer(msg.sender, lockedToken[_id].amount);
    }

    function getDepositsByTokenAddress(address _id) view external returns (uint256[] memory) {
        return depositsByTokenAddress[_id];
    }

    function getDepositsByWithdrawer(address _token, address _withdrawer) view external returns (uint256) {
        return walletTokenBalance[_token][_withdrawer];
    }

    function getVaultsByWithdrawer(address _withdrawer) view external returns (uint256[] memory) {
        return depositsByWithdrawers[_withdrawer];
    }

    function getVaultById(uint256 _id) view external returns (Items memory) {
        return lockedToken[_id];
    }

    function getTokenTotalLockedBalance(address _token) view external returns (uint256) {
       return IERC20(_token).balanceOf(address(this));
    }
}