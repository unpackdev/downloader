pragma solidity ^0.6.2;

/*
    TENSET IS THE BEST !!!
    DIAMOND HANDS
*/

import "./SafeMath.sol";
import "./IERC20.sol";

import "./Package.sol";
import "./RetrieveTokensFeature.sol";

contract InfinityDeposit is RetrieveTokensFeature, Package {
    using SafeMath for uint256;

    IERC20 public Tenset;
    struct Deposit {
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        uint256 idxPackage;
        bool    withdrawn;
    }

    uint256 public depositId;
    uint256[] public allDepositIds;
    uint256 public totalUsersBalance;

    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Deposit) public lockedToken;
    mapping(address => uint256) public walletTokenBalance;

    event LogWithdrawal(uint256 Id, uint256 IndexPackage, address WithdrawalAddress, uint256 Amount);
    event LogDeposit(uint256 Id, uint256 IndexPackage, address WithdrawalAddress, uint256 Amount, uint256 BonusAmount, uint256 UnlockTime);

    constructor(address addrToken) public {
        Tenset = IERC20(addrToken);
    }

    function makeDeposit(address _withdrawalAddress, uint256 _idxPackage, uint256 _amount) public canBuy(_idxPackage, _amount) returns(uint256 _id) {
        //update balance in address
        uint256 tensetFixedBalance = _amount.sub(_decreaseAmountFee(_amount));

        walletTokenBalance[_withdrawalAddress] = walletTokenBalance[_withdrawalAddress].add(tensetFixedBalance);
        totalUsersBalance += tensetFixedBalance;

        _id = ++depositId;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = tensetFixedBalance;
        lockedToken[_id].unlockTime = _deltaTimestamp(_idxPackage);
        lockedToken[_id].idxPackage = _idxPackage;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);

        // transfer tokens into contract
        require(Tenset.transferFrom(msg.sender, address(this), _amount));
        // Count bonus from package without decrease fee
        uint256 WithBonusAmount = tensetFixedBalance.mul(availablePackage[_idxPackage].dailyPercentage).div(100).add(tensetFixedBalance);
        emit LogDeposit(_id, _idxPackage, _withdrawalAddress, tensetFixedBalance, WithBonusAmount, lockedToken[_id].unlockTime);
    }

    /**
     *Extend lock Duration
    */
    function extendLockDuration(uint256 _id) public {
        require(!lockedToken[_id].withdrawn);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        require(activePackage(lockedToken[_id].idxPackage), "Package is not active");

        //set new unlock time
        lockedToken[_id].unlockTime = _deltaTimestamp(lockedToken[_id].idxPackage);
    }

    /**
     *withdraw tokens
    */
    function withdrawTokens(uint256 _id) public {
        require(block.timestamp >= lockedToken[_id].unlockTime);
        require(msg.sender == lockedToken[_id].withdrawalAddress);
        require(!lockedToken[_id].withdrawn);

        lockedToken[_id].withdrawn = true;
        uint256 _idPackage = lockedToken[_id].idxPackage;
        //update balance in address
        walletTokenBalance[msg.sender] = walletTokenBalance[msg.sender].sub(lockedToken[_id].tokenAmount);
        totalUsersBalance -= lockedToken[_id].tokenAmount;

        //remove this id from this address
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;

        for (j=0; j<arrLength; j++) {
            if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].pop();
                break;
            }
        }

        // transfer tokens to wallet address
        require(Tenset.transfer(msg.sender, lockedToken[_id].tokenAmount));
        LogWithdrawal(_id, _idPackage, msg.sender, lockedToken[_id].tokenAmount);
    }

    function getTotalTokenBalance() view public returns (uint256) {
        return Tenset.balanceOf(address(this));
    }

    /*get total token balance by address*/
    function getTokenBalanceByAddress(address _walletAddress) view public returns (uint256) {
        return walletTokenBalance[_walletAddress];
    }

    /*get allDepositIds*/
    function getAllDepositIds() view public returns (uint256[] memory) {
        return allDepositIds;
    }

    /*get getDepositDetails*/
    function getDepositDetails(uint256 _id) view public returns (address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _withdrawn) {
        return(lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount, lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }

    /*get DepositsByWithdrawalAddress*/
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory) {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }

    function retrieveTokensFromStaking(address to) public onlyOwner() {
        RetrieveTokensFeature.retrieveTokens(to, address(Tenset), getStakingPool());
    }

    function getStakingPool() public view returns(uint256 _pool) {
        _pool = getTotalTokenBalance().sub(totalUsersBalance);
    }
}