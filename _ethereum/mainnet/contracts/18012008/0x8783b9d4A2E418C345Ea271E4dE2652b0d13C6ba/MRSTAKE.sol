//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface NFTMINT1155 {
    function mint(address wallet, uint256 id, uint256 amount) external;
}


contract MRSTAKE is Context, Ownable {
    using SafeMath for uint256;
    IERC20 public token;
    mapping(uint256 => uint256) public minStakeAmount;
    mapping(uint256 => uint256) public stakeTime;
    NFTMINT1155 public nftToken;

    struct Stake {
        uint256 nftId; //nft collection id to be minted
        uint256 stakeId; //array position of stakes array of a wallet
        uint256 unlockTime; // timestamp when the stake will be unlocked
        uint256 stakedAmount; // amount of token being staked
        address owner; // owner of the stake
    }

    mapping(address => Stake[]) private stakeInfo;

    constructor(
        address _token,
        address _nftToken
    ){
        token = IERC20(_token);
        nftToken = NFTMINT1155(_nftToken);
    }

    /**
    * @dev Stake the stakeAmount of token and mint new nft
    * Mint new NFT to msg.sender
    * Emits a {Staked} event
    */
    event Staked(
        address indexed account, 
        uint256 stakeAmount, 
        uint256 _nftId
    );

    function stake(uint256 nftId, uint256 amountToMint) external {
        require(amountToMint != 0, "Mint amount can not be zero");
        require(minStakeAmount[nftId] != 0, "Minimum staking amount is not set for the collection");
        require(stakeTime[nftId] != 0, "Stake time is not set for the collection");

        uint256 _stakeAmount = amountToMint.mul(minStakeAmount[nftId]);
        token.transferFrom(_msgSender(), address(this), _stakeAmount);
        nftToken.mint(_msgSender(), nftId, amountToMint);

        Stake memory _stakeInfo = Stake(0, 0, 0, 0, address(0));
        _stakeInfo.stakeId = stakeInfo[_msgSender()].length;
        _stakeInfo.nftId = nftId;
        _stakeInfo.unlockTime = block.timestamp.add(stakeTime[nftId]);
        _stakeInfo.stakedAmount = _stakeAmount;
        _stakeInfo.owner = _msgSender();
        stakeInfo[_msgSender()].push(_stakeInfo);
        emit Staked(_msgSender(), _stakeAmount, nftId);
    }

    /**
    * @dev Restake if the unlock time is over 
    * Mint new NFT to msg.sender
    * Emits a {Staked} event
     */
    function reStake(
        uint256 stakeId
    ) external {
        Stake memory _stakeInfo = stakeInfo[_msgSender()][stakeId];
        require(_stakeInfo.owner == _msgSender(), "caller is not the owner of stake");
        require(
            _stakeInfo.unlockTime != 0 && 
            _stakeInfo.nftId != 0 &&
            _stakeInfo.stakeId == stakeId &&
            _stakeInfo.stakedAmount != 0, 
            "stake not found"
        );

        require(block.timestamp >= _stakeInfo.unlockTime, "lock is not completed");
        uint256 _stakedAmount = _stakeInfo.stakedAmount;
        uint256 _amountToMint = _stakedAmount.div(minStakeAmount[_stakeInfo.nftId]);

        if(_amountToMint == 0) {
            _amountToMint = 1;
        }

        nftToken.mint(_msgSender(), _stakeInfo.nftId, _amountToMint);
        _stakeInfo.unlockTime = block.timestamp.add(stakeTime[_stakeInfo.nftId]);
        stakeInfo[_msgSender()][stakeId] = _stakeInfo;
        emit Staked(_msgSender(), _stakedAmount, _stakeInfo.nftId);
    }

    /**
    * @dev Unstake based on nft id only if unlock time is over
    * Transfer staked amount of token to the msg.sender
    * Emits a {Unstaked} event
     */
    event Unstaked(
        address indexed account,
        uint256 stakeAmount,
        uint256 nftId
    );

    function unstake(
        uint256 stakeId
    ) external {
        Stake memory _stakeInfo = stakeInfo[_msgSender()][stakeId];
        require(_stakeInfo.owner == _msgSender(), "caller is not the owner of the stake");
        require(
            _stakeInfo.nftId != 0 && 
            _stakeInfo.unlockTime != 0 &&
            _stakeInfo.stakeId == stakeId &&
            _stakeInfo.stakedAmount != 0, 
            "stake not found"
        );
        require(block.timestamp >= _stakeInfo.unlockTime, "lock is not completed.");
        uint256 _stakedAmount = _stakeInfo.stakedAmount;
        _removeStakeInfo(stakeId, _msgSender());
        token.transfer(_msgSender(), _stakedAmount);
        emit Unstaked(_msgSender(), _stakedAmount, _stakeInfo.nftId);
    }

    function _removeStakeInfo(
        uint256 _stakeId, 
        address wallet
    ) internal{
        stakeInfo[wallet][_stakeId] = stakeInfo[wallet][stakeInfo[wallet].length - 1];
        stakeInfo[wallet][_stakeId].stakeId = _stakeId;
        stakeInfo[wallet].pop();
    }

    /**
    * @dev Update the token address
    * Emits a {UpdateToken} event
     */
    event UpdateToken(address indexed _newToken);
    function updateToken(
        address newToken
    ) external onlyOwner {
        token = IERC20(newToken);
        emit UpdateToken(newToken);
    }

    /**
    * @dev Update min token stake amount
    * Emits a {UpdateStakeAmount} event 
     */
    event UpdateMinStakeAmount(uint256 _nftId, uint256 _stakeAmount);
    function updateMinStakeAmount(
        uint256 _minStakeAmount,
        uint256 _nftId
    ) external onlyOwner {
        minStakeAmount[_nftId] = _minStakeAmount;
        emit UpdateMinStakeAmount(_nftId, _minStakeAmount);
    }

    /**
    * @dev Update token stake time
    * Emits a {UpdateStakeTime} event
     */
    event UpdateStakeTime(uint256 _nftId, uint256 _stakeTime);
    function updateStakeTime(
        uint256 _stakeTime,
        uint256 _nftId
    ) external onlyOwner {
        stakeTime[_nftId] = _stakeTime;
        emit UpdateStakeTime(_nftId, _stakeTime);
    }

    /**
    * @dev Take any `_token` from the contract
     */
    function withdrawToken(
        address _token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(_token).transfer(to, amount);
    }


    /**
    * @dev Take `_amount` of eth out from the contract to `_to` wallet address
     */
    function withdrawETH(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "eth sending failed.");
    }

    /**
    * @dev Get stake detail based on minted nft id
     */
    function getStakeInfo(
        address wallet
    ) external view returns(Stake[] memory) {
        return stakeInfo[wallet];
    }

    /**
    * @dev Update the NFT address
    * Emits a {UpdateNftAddress} event
     */
    event UpdateNftAddress(address indexed _nftAddress);
    function updateNftAddress(
        address _nftAddress
    ) external onlyOwner {
        nftToken = NFTMINT1155(_nftAddress);
        emit UpdateNftAddress(_nftAddress);
    }

}