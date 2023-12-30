pragma solidity ^0.5.16;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y, uint base) internal pure returns (uint z) {
        z = add(mul(x, y), base / 2) / base;
    }

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    /*function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }*/
}

interface IDfTokenizedStrategy {

    function initialize(
        string calldata _tokenName,
        string calldata _tokenSymbol,
        address payable _owner,
        address _issuer,
        bool _onlyWithProfit,
        bool _transferDepositToOwner,
        uint[5] calldata _params,     // extraCoef [0], profitPercent [1], usdcToBuyEth [2], ethType [3], closingType [4]
        bytes calldata _exchangeData
    ) external payable;

    function strategyToken() external view returns(address);

    function dfFinanceClose() external view returns(address);

    function strategy() external view returns (
        uint initialEth,                    // in eth – max more 1.2 mln eth
        uint entryEthPrice,                 // in usd – max more 1.2 mln USD for 1 eth
        uint profitPercent,                 // min profit percent
        bool onlyWithProfit,                // strategy can be closed only with profitPercent profit
        bool transferDepositToOwner,        // deposit will be transferred to the owner after closing the strategy
        uint closingType,                   // strategy closing type
        bool isStrategyClosed               // strategy is closed
    );

    function migrateStrategies(address[] calldata _dfWallets) external;

    function collectAndCloseByUser(
        address _dfWallet,
        uint256 _ethForRedeem,
        uint256 _minAmountUsd,
        bool _onlyProfitInUsd,
        bytes calldata _exData
    ) external payable;

    function exitAfterLiquidation(
        address _dfWallet,
        uint256 _ethForRedeem,
        uint256 _minAmountUsd,
        bytes calldata _exData
    ) external payable;

    function depositEth(address _dfWallet) external payable;

}

interface IERC20Snapshot {

    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view returns(uint256);

    function snapshot() external returns (
        uint256 currentId
    );

}

contract DfTokenizedAdmin is Initializable, DSMath {

    struct Vote {
        uint32 expireTime;
        MethodType methodType;
        uint64 snapshotId;

        // params for CLOSE type
        uint80 maxEthForRedeem;
        uint64 minAmountUsd;
        bool onlyProfitInUsd;

        uint256 tokensVotedFor;
    }

    enum MethodType {
        CLOSE,
        MIGRATE
    }

    uint public constant MAX_VOTE_DURATION = 7 days;

    address public dfTokenizedStrategy;
    address public dfStrategyToken;

    mapping(uint => Vote) public votes;
    uint public voteCount;

    // is user voted for voteId (user => voteId)
    mapping(address => mapping(uint => bool)) public isUserVoted;

    // ** EVENTS **

    event VoteCreated(
        uint voteId, MethodType methodType, uint expireTime, uint snapshotId
    );

    // ** MODIFIERS **

    modifier isActive(uint _voteId) {
        uint expireTime = votes[_voteId].expireTime;
        require(expireTime > 0 && expireTime <= now, "Voting is not active");
        _;
    }

    modifier onlySuccess(uint _voteId) {
        require(isVoteSuccess(_voteId), "Vote is not success");
        _;
    }

    modifier onlyCloseCorrect(uint _voteId, uint _ethForRedeem, uint _minAmountUsd, bool _onlyProfitInUsd) {
        Vote memory vote = votes[_voteId];
        require(vote.methodType == MethodType.CLOSE, "Method Type error");
        require(vote.maxEthForRedeem >= _ethForRedeem &&
                vote.minAmountUsd <= _minAmountUsd &&
                vote.onlyProfitInUsd == _onlyProfitInUsd, "Invalid params");
        _;
    }

    modifier onlyMigrateCorrect(uint _voteId) {
        require(votes[_voteId].methodType == MethodType.MIGRATE, "Method Type error");
        _;
    }

    // ** INITIALIZER **

    function initialize(address _dfTokenizedStrategy) public initializer {
        dfTokenizedStrategy = _dfTokenizedStrategy;
        dfStrategyToken = IDfTokenizedStrategy(_dfTokenizedStrategy).strategyToken();
    }

    // ** PUBLIC VIEW functions **

    function isVoteSuccess(uint _voteId) public view returns (bool) {
        return (getVoteRatio(_voteId) * 100 > 50 * WAD);  // success if more than 50% tokens for method call
    }

    // get vote for ratio (decimals == 1e18)
    function getVoteRatio(uint _voteId) public view returns (uint ratio) {
        Vote memory vote = votes[_voteId];

        uint tokensVotedFor = vote.tokensVotedFor;
        uint tokenTotalSupply = IERC20Snapshot(dfStrategyToken).totalSupplyAt(vote.snapshotId);

        ratio = wdiv(tokensVotedFor, tokenTotalSupply);  // ex. 0.5e18 = 50%
    }

    // ** PUBLIC VOTE logic functions **

    function voteFor(uint _voteId) public
        isActive(_voteId)
    {
        address user = msg.sender;
        require(!isUserVoted[user][_voteId], "User has voted");

        Vote memory vote = votes[_voteId];

        uint userTokenBalance = IERC20Snapshot(dfStrategyToken).balanceOfAt(user, vote.snapshotId);
        require(userTokenBalance > 0, "User's token balance cannot be zero");

        // UPD states
        votes[_voteId].tokensVotedFor = add(vote.tokensVotedFor, userTokenBalance);
        isUserVoted[user][_voteId] = true;
    }

    function cancelVote(uint _voteId) public
        isActive(_voteId)
    {
        address user = msg.sender;
        require(isUserVoted[user][_voteId], "User has not voted");

        Vote memory vote = votes[_voteId];

        uint userTokenBalance = IERC20Snapshot(dfStrategyToken).balanceOfAt(user, vote.snapshotId);
        require(userTokenBalance > 0, "User's token balance cannot be zero");

        // UPD states
        votes[_voteId].tokensVotedFor = sub(vote.tokensVotedFor, userTokenBalance);
        isUserVoted[user][_voteId] = false;
    }

    // ** PUBLIC CREATE VOTE logic functions **

    function createVoteForClose(
        uint _maxEthForRedeem,
        uint _minAmountUsd,
        bool _onlyProfitInUsd
    ) public returns (
        uint voteId
    ) {
        voteId = _createVote(MethodType.CLOSE, _maxEthForRedeem, _minAmountUsd, _onlyProfitInUsd);
    }

    function createVoteForMigrate() public returns (
        uint voteId
    ) {
        voteId = _createVote(MethodType.MIGRATE, 0, 0, false);
    }

    // ** PUBLIC ONLY_CONFIRMED functions **

    function collectAndCloseByUser(
        uint _voteId,
        address _dfWallet,
        uint256 _ethForRedeem,
        uint256 _minAmountUsd,
        bool _onlyProfitInUsd,
        bytes memory _exData
    ) public payable
        isActive(_voteId)
        onlySuccess(_voteId)
        onlyCloseCorrect(_voteId, _ethForRedeem, _minAmountUsd, _onlyProfitInUsd)
    {

        IDfTokenizedStrategy(dfTokenizedStrategy)
            .collectAndCloseByUser
            .value(msg.value)
            (
                _dfWallet,
                _ethForRedeem,
                _minAmountUsd,
                _onlyProfitInUsd,
                _exData
            );

    }

    function migrateStrategies(
        uint _voteId,
        address[] memory _dfWallets
    ) public
        isActive(_voteId)
        onlySuccess(_voteId)
        onlyMigrateCorrect(_voteId)
    {
        IDfTokenizedStrategy(dfTokenizedStrategy).migrateStrategies(_dfWallets);
    }

    // ** PUBLIC functions **

    function exitAfterLiquidation(
        address _dfWallet,
        uint256 _ethForRedeem,
        uint256 _minAmountUsd,
        bytes memory _exData
    ) public payable {

        IDfTokenizedStrategy(dfTokenizedStrategy)
            .exitAfterLiquidation
            .value(msg.value)
            (
                _dfWallet,
                _ethForRedeem,
                _minAmountUsd,
                _exData
            );

    }

    // TODO: add additional token mint logic
    function depositEth(address _dfWallet) public payable {

        IDfTokenizedStrategy(dfTokenizedStrategy)
            .depositEth
            .value(msg.value)
            (
                _dfWallet
            );

    }

    // ** INTERNAL functions **

    function _createVote(
        MethodType _methodType,
        uint _maxEthForRedeem,
        uint _minAmountUsd,
        bool _onlyProfitInUsd
    ) internal returns (
        uint voteId
    ) {
        voteId = voteCount;
        uint expireTime = now + MAX_VOTE_DURATION;
        uint snapshotId = IERC20Snapshot(dfStrategyToken).snapshot();

        // UPD states
        votes[voteId] = Vote({
            expireTime: uint32(expireTime),
            methodType: _methodType,
            snapshotId: uint64(snapshotId),
            // params for CLOSE type
            maxEthForRedeem: uint80(_maxEthForRedeem),
            minAmountUsd: uint64(_minAmountUsd),
            onlyProfitInUsd: _onlyProfitInUsd,
            // vote for counter
            tokensVotedFor: 0
        });
        voteCount += 1;     // increment vote counter

        emit VoteCreated(voteId, _methodType, expireTime, snapshotId);
    }

    // **FALLBACK function**
    function() external payable {}

}