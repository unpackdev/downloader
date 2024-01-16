// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IFactory.sol";
import "./IPriceContract.sol";
import "./IBettingContract.sol";
import "./IFreeBettingContract.sol";
import "./IStandardPrizeBettingContract.sol";
import "./IGuaranteedPrizeBettingContract.sol";
import "./ICommunityBettingContract.sol";

contract BettingPool is Ownable {
    using SafeERC20 for IERC20;
    IPriceContract public priceContract;
    IFactory public factory;

    address public tokenPool;
    address[] public pool;
    mapping(address => address) public creator;
    uint256 public poolLength;
    mapping(address => bool) private existed;
    mapping(PrizeBetting => uint256[]) public rewardRate;

    uint256 private fee;
    uint256 public maxTimeWaitForRefunding = 5 * 60 * 60 * 24;

    enum PrizeBetting {
        GuaranteedPrizeBettingContract,
        StandardPrizeBettingContract,
        CommunityBettingContract,
        FreeBettingContract
    }

    event NewBetting(
        uint256 indexed _index,
        address indexed _address,
        PrizeBetting _typeBetting,
        uint256 _feeForPool
    );
    event UpdatePriceContract(address indexed _old, address indexed _new);
    event UpdateTokenPool(address indexed _old, address indexed _new);
    event UpDateFee(uint256 _old, uint256 _new);
    event UpdateFactory(address _old, address _new);
    event MaxTimeWaitFulfill(uint256 _old, uint256 _new);
    event UpdateRewardRate(RewardRate[] _rewardRateList);

    struct RewardRate {
        PrizeBetting _betting;
        uint256 _rewardForWinner;
        uint256 _rewardForCreator;
        uint256 _decimal;
    }

    constructor(
        address _priceContract,
        address _tokenPool,
        address _factory,
        uint256 _fee
    ) {
        priceContract = IPriceContract(_priceContract);
        tokenPool = _tokenPool;
        factory = IFactory(_factory);
        fee = _fee;
        rewardRate[PrizeBetting.GuaranteedPrizeBettingContract] = [95, 5, 0];
        rewardRate[PrizeBetting.StandardPrizeBettingContract] = [975, 25, 1];
    }

    modifier onlyExistedPool(address _pool) {
        require(existed[_pool], "BETTING_POOL: Pool not found");
        _;
    }

    modifier onlyBettingOwner(address _pool) {
        require(creator[_pool] == msg.sender, "BETTING_POOL: Only Creator");
        _;
    }

    modifier onlyRewardRateExists(PrizeBetting _type) {
        require(
            rewardRate[_type][0] + rewardRate[_type][1] ==
                10**(rewardRate[_type][2] + 2)
        );
        _;
    }

    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0));
        emit UpdateFactory(address(factory), _factory);
        factory = IFactory(_factory);
    }

    function setTokenPool(address _token) external onlyOwner {
        require(_token != address(0));
        emit UpdateTokenPool(tokenPool, _token);
        tokenPool = _token;
    }

    function setPriceContract(address _priceContract) external onlyOwner {
        require(_priceContract != address(0));
        emit UpdatePriceContract(address(priceContract), _priceContract);
        priceContract = IPriceContract(_priceContract);
    }

    function setMaxTimeWaitForRefunding(uint256 _time) external onlyOwner {
        emit MaxTimeWaitFulfill(maxTimeWaitForRefunding, _time);
        maxTimeWaitForRefunding = _time;
    }

    function setRewardRate(RewardRate[] memory _rewardRateList)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _rewardRateList.length; i++) {
            require(_rewardRateList[i]._decimal <= 18);
            require(
                _rewardRateList[i]._rewardForWinner +
                    _rewardRateList[i]._rewardForCreator ==
                    10**(_rewardRateList[i]._decimal + 2)
            );
            rewardRate[_rewardRateList[i]._betting] = [
                _rewardRateList[i]._rewardForWinner,
                _rewardRateList[i]._rewardForCreator,
                _rewardRateList[i]._decimal
            ];
        }
        emit UpdateRewardRate(_rewardRateList);
    }

    function setFee(uint256 _fee) external onlyOwner {
        emit UpDateFee(fee, _fee);
        fee = _fee;
    }

    function getFee() external view returns (uint256) {
        return fee;
    }

    function createNewFreeBetting(
        address _tokenBet,
        uint256 _award,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant,
        uint256 _maxEntrant
    ) public returns (address) {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewFreeBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.FreeBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            0,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        IFreeBettingContract(betting).setMinAndMaxEntrant(
            _minEntrant,
            _maxEntrant
        );
        IFreeBettingContract(betting).setAward(_award);
        IERC20(tokenPool).safeTransferFrom(msg.sender, betting, _award + fee);
        _start(betting);
        return betting;
    }

    function createNewCommunityBetting(
        address _tokenBet,
        uint256 _ticketPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant
    ) public returns (address) {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewCommunityBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.CommunityBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            _ticketPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        ICommunityBettingContract(betting).setMinEntrant(_minEntrant);
        IERC20(tokenPool).safeTransferFrom(msg.sender, betting, fee);
        _start(betting);
        return betting;
    }

    function createNewStandardPrizeBetting(
        address _tokenBet,
        uint256 _ticketPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant,
        uint256 _maxEntrant
    )
        public
        onlyRewardRateExists(PrizeBetting.StandardPrizeBettingContract)
        returns (address)
    {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewStandardBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            rewardRate[PrizeBetting.StandardPrizeBettingContract][0],
            rewardRate[PrizeBetting.StandardPrizeBettingContract][1],
            rewardRate[PrizeBetting.StandardPrizeBettingContract][2],
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.StandardPrizeBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            _ticketPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        IStandardPrizeBettingContract(betting).setMinAndMaxEntrant(
            _minEntrant,
            _maxEntrant
        );
        IERC20(tokenPool).safeTransferFrom(
            msg.sender,
            betting,
            IStandardPrizeBettingContract(betting).getUpfrontLockedFunds() + fee
        );
        _start(betting);
        return betting;
    }

    function createNewGuaranteedPrizeBetting(
        address _tokenBet,
        uint256 _ticketPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced,
        uint256 _minEntrant,
        uint256 _maxEntrant
    )
        public
        onlyRewardRateExists(PrizeBetting.GuaranteedPrizeBettingContract)
        returns (address)
    {
        // IERC20(tokenPool).safeTransferFrom(msg.sender, address(this), fee);
        address betting = factory.createNewGuaranteedBettingContract(
            payable(address(this)),
            payable(msg.sender),
            tokenPool,
            rewardRate[PrizeBetting.GuaranteedPrizeBettingContract][0],
            rewardRate[PrizeBetting.GuaranteedPrizeBettingContract][1],
            rewardRate[PrizeBetting.GuaranteedPrizeBettingContract][2],
            fee
        );
        pool.push(betting);
        existed[betting] = true;
        creator[betting] = msg.sender;
        poolLength = pool.length;
        emit NewBetting(
            poolLength - 1,
            betting,
            PrizeBetting.GuaranteedPrizeBettingContract,
            fee
        );
        setupBettingContract(
            betting,
            _tokenBet,
            _ticketPrice,
            _bracketsDecimals,
            _bracketsPrice,
            _priceValidationTimestamp,
            _lastBetPlaced
        );
        IGuaranteedPrizeBettingContract(betting).setMinAndMaxEntrant(
            _minEntrant,
            _maxEntrant
        );
        IERC20(tokenPool).safeTransferFrom(
            msg.sender,
            betting,
            IGuaranteedPrizeBettingContract(betting).getUpfrontLockedFunds() +
                fee
        );
        _start(betting);
        return betting;
    }

    function setupBettingContract(
        address _pool,
        address _tokenAddress,
        uint256 _tickerPrice,
        uint256 _bracketsDecimals,
        uint256[] memory _bracketsPrice,
        uint256 _priceValidationTimestamp,
        uint256 _lastBetPlaced
    ) internal returns (bool) {
        IBettingContract(_pool).setBracketsPrice(_bracketsPrice);
        IBettingContract(_pool).setBasic(
            _tokenAddress,
            _tickerPrice,
            _bracketsDecimals,
            _priceValidationTimestamp,
            _lastBetPlaced
        );

        return true;
    }

    function _start(address _pool) internal {
        IBettingContract(_pool).start{value: msg.value}(priceContract);
    }

    function buyTicket(address _betting, uint256 _guessValue)
        public
        onlyExistedPool(_betting)
    {
        uint256 totalFee = IBettingContract(_betting).getTicketPrice() +
            IBettingContract(_betting).getFee();
        if (totalFee > 0) {
            IERC20(tokenPool).safeTransferFrom(msg.sender, _betting, totalFee);
        }

        IBettingContract(_betting).buyTicket(_guessValue, msg.sender);
    }

    function withdrawToken(
        address _token_address,
        address _receiver,
        uint256 _value
    ) public onlyOwner {
        IERC20(_token_address).safeTransfer(_receiver, _value);
    }

    function checkBettingContractExist(address _pool)
        public
        view
        returns (bool)
    {
        return existed[_pool];
    }

    function checkRefund(address _betting) external view returns (bool) {
        (
            bytes32 _resultId,
            ,
            uint256 _priceValidationTimestamp
        ) = IBettingContract(_betting).getDataToCheckRefund();
        if (
            block.timestamp >
            (_priceValidationTimestamp + maxTimeWaitForRefunding) &&
            !priceContract.checkFulfill(_resultId)
        ) return true; //refund

        return false; //don't refund
    }
}
