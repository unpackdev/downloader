// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract TokenLock is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        uint256 blockTime;
        uint256 lockedTime;
        bool withdrawn;
    }

    uint256 public depositId;

    address payable admin;
    uint256 public initFee;

    mapping(address => mapping(address => uint256)) public walletTokenBalance;
    mapping(uint256 => Items) public lockedToken;
    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(address => uint256[]) public depositsByTokenAddress;

    event LockedToken(address indexed tokenAddress, uint256 indexed amount, uint256 indexed unlockTime);
    event ExtendLockDuration(uint256 indexed id, uint256 indexed unlockTime);
    event WithdrawToken(address indexed recipient, uint256 indexed amount);

    function setAdminAddress(address payable _admin) external onlyOwner {
        admin = _admin;
    }

    function setInitFee(uint256 _initFee) external onlyOwner {
        initFee = _initFee;
    }

    function lockToken(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) external payable returns (uint256 _id){
        require(_amount > 0, 'TokenLock: amount > 0');

        // check fee amount calculate
        require(msg.value >= initFee, 'TokenLock: fee invalid');

        require(!address(msg.sender).isContract(), 'TokenLock: sender invalid');

        // transfer tokens into contract
        IERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        // transfer fee amount to admin address
        
        // transfer remain fee
        if (msg.value > initFee) {
            uint256 remainFee = msg.value.sub(initFee);
            msg.sender.transfer(remainFee);
        }

        admin.transfer(initFee);
        // update balance of address
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);

        _id = depositId;

        Items memory newLockItem;
        newLockItem.tokenAddress = _tokenAddress;
        newLockItem.withdrawalAddress = _withdrawalAddress;
        newLockItem.tokenAmount = _amount;
        newLockItem.unlockTime = _unlockTime;
        newLockItem.lockedTime = block.timestamp;
        newLockItem.blockTime = block.timestamp;
        newLockItem.withdrawn = false;
        lockedToken[_id] = newLockItem;

        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        depositsByTokenAddress[_tokenAddress].push(_id);
        
        depositId ++;

        emit LockedToken(_tokenAddress, _amount, _unlockTime);
    }

    // Extend lock Duration
    function extendLockDuration(uint256 _id, uint256 _unlockTime) external {
        require(!lockedToken[_id].withdrawn, 'TokenLock: withdrawable is false');
        require(msg.sender == lockedToken[_id].withdrawalAddress, 'TokenLock: not accessible');

        // set new unlock time
        lockedToken[_id].unlockTime = lockedToken[_id].unlockTime.add(_unlockTime.mul(1 days));
        lockedToken[_id].blockTime = block.timestamp;

        emit ExtendLockDuration(_id, _unlockTime);
    }

    // withdraw token
    function withdrawToken(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTime, 'TokenLock: not expired yet');
        require(msg.sender == lockedToken[_id].withdrawalAddress, 'TokenLock: not accessible');
        require(!lockedToken[_id].withdrawn, 'TokenLock: withdrawable not accepct');

        // transfer tokens to wallet address
        IERC20(lockedToken[_id].tokenAddress).safeTransfer(msg.sender, lockedToken[_id].tokenAmount);
        Items memory lockItem =  lockedToken[_id];
        lockItem.withdrawn = true;
        lockItem.blockTime = block.timestamp;
        lockedToken[_id] = lockItem;
        // update balance of addresss
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = 0;
        emit WithdrawToken(msg.sender, lockedToken[_id].tokenAmount);
    }

    // Get total token balance of wallet address
    function getTotalTokenBalanceByWithdrawAddress(address _tokenAddress, address _withdrawalAddress) public view returns (uint256) {
        return walletTokenBalance[_tokenAddress][_withdrawalAddress];
    }

    // Get deposit detail
    function getDepositDetails(uint256 _id) public view returns (address _tokenAddress, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _withdrawn, uint256 _blockTime, uint256 _lockedTime) {
        return (
            lockedToken[_id].tokenAddress,
            lockedToken[_id].withdrawalAddress,
            lockedToken[_id].tokenAmount,
            lockedToken[_id].unlockTime,
            lockedToken[_id].withdrawn,
            lockedToken[_id].blockTime,
            lockedToken[_id].lockedTime
        );
    }

    // Get deposits by withdraw address
    function getDepositsByWithdrawAddress(address _withdrawAddress) public view returns (uint256[] memory) {
        return depositsByWithdrawalAddress[_withdrawAddress];
    }

    // Get deposits by token address
    function getDepositsByTokenAddress(address _tokenAddress) public view returns (uint256[] memory) {
        return depositsByTokenAddress[_tokenAddress];
    }
}