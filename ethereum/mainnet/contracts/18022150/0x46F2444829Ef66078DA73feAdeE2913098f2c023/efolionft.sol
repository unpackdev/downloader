// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity =0.8.21;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/** 
 * @dev a library for sorting leaderboard
 * https://gist.github.com/taobun/198cb6b2d620f687cacf665a791375cc
 */
contract School is Ownable {
    mapping(address => uint256) public scores;
    mapping(address => address) _nextStudents;
    uint256 public listSize;
    address constant GUARD = address(1);

    constructor() {
        _nextStudents[GUARD] = GUARD;
    }

    function addStudent(address student, uint256 score) public onlyOwner {
        require(_nextStudents[student] == address(0), "addStudent");
        address index = _findIndex(score);
        scores[student] = score;
        _nextStudents[student] = _nextStudents[index];
        _nextStudents[index] = student;
        listSize++;
    }

    function increaseScore(address student, uint256 score) public onlyOwner {
        updateScore(student, scores[student] + score);
    }

    function reduceScore(address student, uint256 score) public onlyOwner {
        updateScore(student, scores[student] - score);
    }

    function updateScore(address student, uint256 newScore) public onlyOwner {
        require(_nextStudents[student] != address(0), "updateScore");
        address prevStudent = _findPrevStudent(student);
        address nextStudent = _nextStudents[student];
        if(_verifyIndex(prevStudent, newScore, nextStudent)){
            scores[student] = newScore;
        } else {
            removeStudent(student);
            addStudent(student, newScore);
        }
    }

    function removeStudent(address student) public onlyOwner {
        require(_nextStudents[student] != address(0), "removeStudent");
        address prevStudent = _findPrevStudent(student);
        _nextStudents[prevStudent] = _nextStudents[student];
        _nextStudents[student] = address(0);
        scores[student] = 0;
        listSize--;
    }

    function getTop(uint256 k) public view returns(address[] memory) {
        require(k <= listSize);
        address[] memory studentLists = new address[](k);
        address currentAddress = _nextStudents[GUARD];
        for(uint256 i = 0; i < k; ++i) {
            studentLists[i] = currentAddress;
            currentAddress = _nextStudents[currentAddress];
        }
        return studentLists;
    }

    function _verifyIndex(address prevStudent, uint256 newValue, address nextStudent)
        internal
        view
        returns(bool)
    {
        return (prevStudent == GUARD || scores[prevStudent] >= newValue) && 
            (nextStudent == GUARD || newValue > scores[nextStudent]);
    }

    function _findIndex(uint256 newValue) internal view returns(address) {
        address candidateAddress = GUARD;
        while(true) {
            if(_verifyIndex(candidateAddress, newValue, _nextStudents[candidateAddress]))
                return candidateAddress;
            candidateAddress = _nextStudents[candidateAddress];
        }
        return address(0);
    }

    function _isPrevStudent(address student, address prevStudent) internal view returns(bool) {
        return _nextStudents[prevStudent] == student;
    }

    function _findPrevStudent(address student) internal view returns(address) {
        address currentAddress = GUARD;
        while(_nextStudents[currentAddress] != GUARD) {
            if(_isPrevStudent(student, currentAddress))
                return currentAddress;
            currentAddress = _nextStudents[currentAddress];
        }
        return address(0);
    }
}

contract EFOLIONFT is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public totalSupply = 100;

    constructor() ERC721("EFOLIO NFT", "EFC") {
        school = new School();
    }

    function mint(uint256 from, uint256 to) public onlyOwner {
        require(to < totalSupply, "cant mint more than 100");
        for (uint256 i = from; i < to; i++) {
            super._mint(owner(), i);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, "nftmetadata.json") : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://edgefolioeth.com/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://edgefolioeth.com/contractmeta.json";
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(
            startSessionTime == 0 || block.timestamp <= startSessionTime + stakeWindowDuration, 
            "session is started, wait till end"
        );
        if (endSessionTime > 0) {
            require(block.timestamp > endSessionTime + rewardWindowDuration, "reward window is open, wait till end");
        }

        if (leaderboardEnabled && to != owner()) {
            try school.increaseScore(to, 1) {
            } catch {
                school.addStudent(to, 1);
            }
        
            if (from != owner()) {
                if (balanceOf(from) == 0) {
                    school.removeStudent(from);
                } else {
                    school.reduceScore(from, 1);
                }
            }
        }

        super._transfer(from, to, tokenId);
    }

    mapping(address => uint256) public lastClaim;

    uint256 public startSessionTime;
    uint256 public endSessionTime;

    School public school;

    bool public leaderboardEnabled = true;
    uint256 public stakeWindowDuration = 7 days;
    uint256 public rewardWindowDuration = 1 days;

    uint256 public totalReward;

    event SessionStarted(uint256);
    event SessionEnded(uint256);
    event Staked(address indexed account, uint256 amount);
    event ClaimedReward(address indexed account, uint256 value);
    event Unstaked(address indexed account, uint256 amount);

    function totalStaked() public view returns (uint256) {
        return totalSupply - balanceOf(owner());
    }

    function enableLeaderboard(bool enabled) external onlyOwner {
        leaderboardEnabled = enabled;
    }

    function updateStakeWindowDuration(uint256 duration) external onlyOwner {
        stakeWindowDuration = duration * (1 days);
    }

    function updateRewardWindowDuration(uint256 duration) external onlyOwner {
        rewardWindowDuration = duration * (1 days);
    }

    function startSession() external onlyOwner {
        require(startSessionTime == 0, "session is running");
        
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "transfer remained ETH failed");

        startSessionTime = block.timestamp;
        endSessionTime = 0;

        totalReward = 0;

        emit SessionStarted(startSessionTime);
    }

    function endSession() external payable onlyOwner {
        require(endSessionTime == 0, "no session");

        startSessionTime = 0;
        endSessionTime = block.timestamp;

        totalReward = msg.value;

        emit SessionEnded(endSessionTime);
    }

    function claimReward() external {
        address sender = _msgSender();
        require(sender != owner(), "owner, it's you?");
        require(endSessionTime > 0, "reward window is not open");
        require(block.timestamp <= endSessionTime + rewardWindowDuration, "you missed this reward, maybe another time");
        require(lastClaim[sender] < endSessionTime, "double claim");

        lastClaim[sender] = block.timestamp;
        uint256 stakedAmount = balanceOf(sender);
        require(stakedAmount > 0, "reward is only for stakers");

        // uint256 value = (totalReward * ((stakedAmount * 1e18) / totalStaked())) / 1e18;
        uint256 value = totalReward.mul((stakedAmount * 1e18).div(totalStaked())).div(1e18);
        (bool sent, ) = _msgSender().call{value: value}("");
        require(sent, "transfer reward failed");

        emit ClaimedReward(_msgSender(), value);
    }

    function getTop(uint256 k) public view returns(address[] memory) {
        return school.getTop(k);
    }

    function claimRemainedReward() external onlyOwner {
        require(block.timestamp > endSessionTime + rewardWindowDuration, "reward window is still open");

        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "transfer remained ETH failed");
    }
}
