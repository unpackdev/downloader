// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: contracts/FriendFundTechBonding.sol


pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract Bonding is ReentrancyGuard {

    address public owner;
    uint256 public TOKENS_PER_ETH;
    bool public canBond;
    IERC20 token;

    struct BondEntry {
        uint256 ethAmount;
        uint256 withdrawTime;
        address referrer;
    }
    mapping (address => BondEntry) public bonds;
    mapping (address => address) refers;
    mapping (address => uint256) totalReferred;

    constructor(address _owner, address _token, uint256 _tokens_per_eth) {
        owner = _owner;
        token = IERC20(_token);
        TOKENS_PER_ETH = _tokens_per_eth;
        canBond = false;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function changeTokensPerEth(uint256 _tokens_per_eth) public onlyOwner {
        TOKENS_PER_ETH = _tokens_per_eth;
    }

    function changeBondingStatus(bool _canBond) public onlyOwner {
        canBond = _canBond;
    }

    function bond(address ref) public payable nonReentrant {
        require(canBond);
        require(msg.value >= 0.1 ether, "Min bond is 0.1 eth");
        require(ref != msg.sender, "Cannot refer to self");
        BondEntry memory currentBond = bonds[msg.sender];
        if(currentBond.withdrawTime == 0) {
            BondEntry memory b = BondEntry(
                msg.value,
                block.timestamp + 1 hours,
                ref
            );
            bonds[msg.sender] = b;
        } else {
            currentBond.ethAmount += msg.value;
            currentBond.withdrawTime = block.timestamp + 1 hours;
            currentBond.referrer = ref;
        }
        
    }

    function withdrawTokens() public nonReentrant {
        require(canBond);
        require(bonds[msg.sender].ethAmount > 0, "must have bonded amount");
        require(block.timestamp > bonds[msg.sender].withdrawTime, "must be able to withdraw");
        uint256 bondAmount = getTokenOut(
            bonds[msg.sender].ethAmount
        );
        if(bonds[msg.sender].referrer != address(0)) {
            uint256 refAmount = getRefAmount(bondAmount);
            token.transfer(bonds[msg.sender].referrer, refAmount);
            totalReferred[msg.sender] += refAmount;
        }
        token.transfer(msg.sender, bondAmount);
        bonds[msg.sender].ethAmount = 0;
    }

    function withdrawEth(address payable _to) public onlyOwner {
        (bool sent, bytes memory data) = _to.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    function emergencyWithdrawTokensToOwner(address to, uint256 amount) public onlyOwner {
        require(token.transfer(to, amount), "Token transfer failed");
    }

    function getRefAmount(uint256 _amount) public pure returns (uint256) {
        return _amount * 500 / 10_000;
    }
    function getTokenOut(uint256 _amount) public view returns(uint256) {
        if(_amount == 0) {
            return 0;
        }
        return (_amount * TOKENS_PER_ETH);
    }

    function getTotalReferred(address _address) public view returns (uint256) {
        return totalReferred[_address];
    }
    function getWithdrawInfo() public view  returns(bool, uint256, uint256) {
        BondEntry memory currentBond = bonds[msg.sender];
        return (currentBond.withdrawTime > 0 ,currentBond.withdrawTime, getTokenOut(currentBond.ethAmount));
    }
}