// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC20.sol";
import "./IETHPool.sol";
import "./IStrongPool.sol";
import "./PlatformFees.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract ETHPoolV3 is IETHPool, IStrongPool, ReentrancyGuard, PlatformFees {

    using SafeMath for uint256;
    bool public initialized;

    uint256 public epochId;
    uint256 public totalStaked;
    mapping(address => bool) public poolContracts;

    mapping(uint256 => address) public stakeOwner;
    mapping(uint256 => uint256) public stakeAmount;
    mapping(uint256 => uint256) public stakeTimestamp;
    mapping(uint256 => bool) public stakeStatus;

    uint256 private stakeId;
    IERC20 private strongTokenContract;
    mapping(address => mapping(uint256 => uint256)) private _ownerIdIndex;
    mapping(address => uint256[]) private _ownerIds;

    event FallBackLog(address sender, uint256 value);
    event PaymentProcessed(address receiver, uint256 amount);

    function init(
        address strongAddress_,
        uint256 stakeFeeNumerator_,
        uint256 stakeFeeDenominator_,
        uint256 unstakeFeeNumerator_,
        uint256 unstakeFeeDenominator_,
        uint256 minStakeAmount_,
        uint256 stakeTxLimit_,
        address payable feeWallet_,
        address serviceAdmin_
    ) external {
        require(!initialized, "ETH2.0Pool: init done");
        PlatformFees.init(
            stakeFeeNumerator_,
            stakeFeeDenominator_,
            unstakeFeeNumerator_,
            unstakeFeeDenominator_,
            minStakeAmount_,
            stakeTxLimit_,
            feeWallet_,
            serviceAdmin_
        );
        ReentrancyGuard.init();

        epochId = 1;
        stakeId = 1;
        strongTokenContract = IERC20(strongAddress_);
        initialized = true;
    }

    function stake(uint256 amount_) external payable nonReentrant override {
        require(amount_.mul(stakeFeeNumerator).div(stakeFeeDenominator) == msg.value, "ETH2.0Pool: Value can not be greater or less than staking fee");
        stake_(amount_, msg.sender);
        require(strongTokenContract.transferFrom(msg.sender, address(this), amount_), "ETH2.0Pool: Insufficient funds");
        processPayment(feeWallet, msg.value);
    }

    function mineFor(address userAddress_, uint256 amount_) external override {
        require(poolContracts[msg.sender], "ETH2.0Pool: Caller not authorised to call this function");
        stake_(amount_, userAddress_);
        require(strongTokenContract.transferFrom(msg.sender, address(this), amount_), "ETH2.0Pool: Insufficient funds");
    }

    function unStake(uint256[] memory stakeIds_) external payable nonReentrant override {
        require(stakeIds_.length <= stakeTxLimit, "ETH2.0Pool: Input array length is greater than approved length");
        uint256 userTokens = 0;

        for (uint256 i = 0; i < stakeIds_.length; i++) {
            require(stakeOwner[stakeIds_[i]] == msg.sender, "ETH2.0Pool: Only owner can unstake");
            require(stakeStatus[stakeIds_[i]], "ETH2.0Pool: Transaction already unStaked");

            stakeStatus[stakeIds_[i]] = false;
            userTokens = userTokens.add(stakeAmount[stakeIds_[i]]);
            if (_ownerIdExists(msg.sender, stakeIds_[i])) {
                _deleteOwnerId(msg.sender, stakeIds_[i]);
            }
            emit Unstaked(msg.sender, stakeIds_[i], stakeAmount[stakeIds_[i]], block.timestamp);
        }

        if (userTokens.mul(unstakeFeeNumerator).div(unstakeFeeDenominator) != msg.value) {
            revert("ETH2.0Pool: Value can not be greater or less than unstaking fee");
        }

        totalStaked = totalStaked.sub(userTokens);
        require(strongTokenContract.transfer(msg.sender, userTokens), "ETH2.0Pool: Insufficient Strong tokens");
        processPayment(feeWallet, userTokens.mul(unstakeFeeNumerator).div(unstakeFeeDenominator));
    }

    function stake_(uint256 amount_, address userAddress_) internal {
        require(_ownerIds[userAddress_].length < stakeTxLimit, "ETH2.0Pool: User can not exceed stake tx limit");
        require(amount_ >= minStakeAmount, "ETH2.0Pool: Amount can not be less than minimum staking amount");
        require(userAddress_ != address(0), "ETH2.0Pool: Invalid user address");

        stakeOwner[stakeId] = userAddress_;
        stakeAmount[stakeId] = amount_;
        stakeTimestamp[stakeId] = block.timestamp;
        stakeStatus[stakeId] = true;
        totalStaked = totalStaked.add(amount_);

        if (!_ownerIdExists(userAddress_, stakeId)) {
            _addOwnerId(userAddress_, stakeId);
        }
        emit Staked(userAddress_,stakeId, amount_, block.timestamp);
        incrementStakeId();
    }

    function addVerifiedContract(address contractAddress_) external anyAdmin {
        require(contractAddress_ != address(0), "ETH2.0Pool: Invalid contract address");
        poolContracts[contractAddress_] = true;
    }

    function removeVerifiedContract(address contractAddress_) external anyAdmin {
        require(poolContracts[contractAddress_], "ETH2.0Pool: Contract address not verified");
        poolContracts[contractAddress_] = false;
    }

    function getUserIds(address user_) external view returns (uint256[] memory) {
        return _ownerIds[user_];
    }

    function getUserIdIndex(address user_, uint256 id_) external view returns (uint256) {
        return _ownerIdIndex[user_][id_];
    }

    // function to transfer eth to recipient account.
    function processPayment(address payable recipient_, uint256 amount_) private {
        (bool sent,) = recipient_.call{value : amount_}("");
        require(sent, "ETH2.0Pool: Failed to send Ether");

        emit PaymentProcessed(recipient_, amount_);
    }

    // function to increment the id counter of Staking entries
    function incrementStakeId() private {
        stakeId = stakeId.add(1);
    }

    function _deleteOwnerId(address owner_, uint256 id_) internal {
        uint256 lastIndex = _ownerIds[owner_].length.sub(1);
        uint256 lastId = _ownerIds[owner_][lastIndex];

        if (id_ == lastId) {
            _ownerIdIndex[owner_][id_] = 0;
            _ownerIds[owner_].pop();
        } else {
            uint256 indexOfId = _ownerIdIndex[owner_][id_];
            _ownerIdIndex[owner_][id_] = 0;
            _ownerIds[owner_][indexOfId] = lastId;
            _ownerIdIndex[owner_][lastId] = indexOfId;
            _ownerIds[owner_].pop();
        }
    }

    function _addOwnerId(address owner, uint256 id) internal {
        uint256 len = _ownerIds[owner].length;
        _ownerIdIndex[owner][id] = len;
        _ownerIds[owner].push(id);
    }

    function _ownerIdExists(address owner, uint256 id) internal view returns (bool) {
        if (_ownerIds[owner].length == 0) return false;

        uint256 index = _ownerIdIndex[owner][id];
        return id == _ownerIds[owner][index];
    }

    function setTokenContract(IERC20 tokenAddress) external onlyOwner {
        strongTokenContract = tokenAddress;
    }

    function withdrawToken(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        require(token.transfer(recipient, amount));
    }

    fallback() external payable {
        emit FallBackLog(msg.sender, msg.value);
    }

    receive() external nonReentrant payable {
        processPayment(feeWallet, msg.value);
        emit FallBackLog(msg.sender, msg.value);
    }
}
