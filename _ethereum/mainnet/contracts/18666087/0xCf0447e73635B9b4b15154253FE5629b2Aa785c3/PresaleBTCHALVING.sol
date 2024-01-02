/**
 *Submitted for verification at BscScan.com on 2023-11-17
*/

/**
 *Submitted for verification at basescan.org on 2023-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)
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
}
contract PresaleBTCHALVING is ReentrancyGuard{
    uint256 public totalTokensSold;
    uint256 public startTime;
    uint256 public endTime;
    IBEP20 public saleToken;
    IBEP20 public USDTInterface;
    mapping(address => uint256) public commitments;
    mapping(address => uint256) public missedEmissions;
    uint256 public totalCommitments;
    AggregatorV3Interface public priceFeed;
    uint256 public TokenperUSDT;
    address public owner;
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address _saleToken,
        uint256 _TokenperUSDT
    ){
        require(
            _startTime >= block.timestamp,
            "Start time must be in the future."
        );
        require(
            _endTime > _startTime,
            "End time must be greater than start time."
        );
        startTime = _startTime;
        endTime = _endTime;
        saleToken = IBEP20(_saleToken);
        USDTInterface = IBEP20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        TokenperUSDT = _TokenperUSDT;
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price* (10 ** 10));
    }
    function calculatePrice(uint256 _amount) public view returns (uint256){
        uint256 USDTAmount;
        USDTAmount = (_amount*getLatestPrice())/(10**18);
        return USDTAmount;
    }
    function buyHelper(uint256 _amount) public view returns (uint256){
        uint256 TokenAmount;
        TokenAmount = _amount*TokenperUSDT;
        return  TokenAmount;
    }
    function buyWithBNB() external payable nonReentrant returns (bool) {
        require(block.timestamp >= startTime && block.timestamp <= endTime, 'Invalid time for buying');
        commitments[msg.sender] += calculatePrice(msg.value);
        missedEmissions[msg.sender] += calculatePrice(msg.value)*TokenperUSDT;
        totalCommitments += calculatePrice(msg.value);
        totalTokensSold += calculatePrice(msg.value)*TokenperUSDT;
        saleToken.transfer(msg.sender, calculatePrice(msg.value)*TokenperUSDT);
        return true;
    }
    function buyWithUSDT(uint256 _amount) external nonReentrant returns (bool) {
        require(block.timestamp >= startTime && block.timestamp <= endTime, 'Invalid time for buying');
        USDTInterface.transferFrom(msg.sender, address(this), _amount);
        commitments[msg.sender] += _amount;
        missedEmissions[msg.sender] += _amount*TokenperUSDT;
        totalCommitments += _amount;
        totalTokensSold += _amount*TokenperUSDT;
        saleToken.transfer(msg.sender, _amount*TokenperUSDT);
        return true;
    }
    function changeSaleTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, 'Invalid parameters');
        if (_startTime > 0) {
            require(block.timestamp < startTime, 'Sale already started');
            require(block.timestamp < _startTime, 'Sale time in past');
            startTime = _startTime;
        }
        if (_endTime > 0) {
            require(_endTime > startTime, 'Invalid endTime');
            endTime = _endTime;
        }
    }
    function changeowner(address _newowner) external onlyOwner{
        owner = _newowner;
    }
    function changesaleToken(address _newToken) external onlyOwner{
        saleToken = IBEP20(_newToken);
    }
    function changeTokenperUSDT(uint256 _value) external onlyOwner{
        TokenperUSDT = _value;
    }
    function withdrawETH() external onlyOwner{
        (bool success, ) = owner.call{
                value: address(this).balance
            }("");
            require(success, "Failed to transfer ether");
    }
    function withdrawUSDT() external onlyOwner{
        USDTInterface.transfer(owner, USDTInterface.balanceOf(address(this)));
    }
    function withdrawToken() external onlyOwner{
        saleToken.transfer(owner, saleToken.balanceOf(address(this)));
    }
    receive() external payable {}
}