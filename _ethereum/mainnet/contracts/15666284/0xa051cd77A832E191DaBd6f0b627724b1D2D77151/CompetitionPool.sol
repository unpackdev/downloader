// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ICompetitionFactory.sol";
import "./IRegularCompetitionContract.sol";
import "./IGuaranteedCompetitionContract.sol";
import "./IChainLinkOracleSportData.sol";
import "./IP2PCompetitionContract.sol";
import "./ICompetitionContract.sol";
import "./ICompetitionPool.sol";
import "./Metadata.sol";

/*
CP01: Pool not found
CP02: Only P2P
CP03: Address 0x00
*/

contract CompetitionPool is
    Ownable,
    ReentrancyGuard,
    Metadata,
    ICompetitionPool
{
    using SafeERC20 for IERC20;

    address public override tokenAddress;
    ICompetitionFactory public competitionFactory;

    address[] public pools;
    mapping(address => address) public creator;
    mapping(address => Pool) public existed;

    uint256 public override fee;
    uint256 private maxTimeWaitForRefunding = 24 hours;

    event CreatedNewRegularCompetition(
        address indexed _creator,
        address _contracts,
        uint256 fee
    );
    event CreatedNewP2PCompetition(
        address indexed _creator,
        address _contracts,
        uint256 fee
    );
    event CreatedNewGuaranteedCompetition(
        address indexed _creator,
        address _contracts,
        uint256 fee
    );
    event Factory(address _factory);
    event UpDateFee(uint256 _old, uint256 _new);
    event MaxTimeWaitFulfill(uint256 _old, uint256 _new);

    constructor(
        address _competitionFactory,
        address _tokenAddress,
        uint256 _fee
    ) {
        require(
            _competitionFactory != address(0) && _tokenAddress != address(0),
            "CP03"
        );
        competitionFactory = ICompetitionFactory(_competitionFactory);
        tokenAddress = _tokenAddress;
        fee = _fee;
    }

    modifier onlyExistedPool(address _pool) {
        require(existed[_pool].existed, "CP01");
        _;
    }

    modifier onlyP2P(address _p2pCompetition) {
        require(existed[_p2pCompetition].competitonType == Type.P2P, "CP02");
        _;
    }

    // <Admin features>
    function setFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "CP03");
        competitionFactory = ICompetitionFactory(_factory);
        emit Factory(_factory);
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "CP03");
        tokenAddress = _tokenAddress;
    }

    function setFee(uint256 _fee) external onlyOwner {
        emit UpDateFee(fee, _fee);
        fee = _fee;
    }

    function setMaxTimeWaitForRefunding(uint256 _time) external onlyOwner {
        emit MaxTimeWaitFulfill(maxTimeWaitForRefunding, _time);
        maxTimeWaitForRefunding = _time;
    }

    function withdrawToken(
        address _token_address,
        address _receiver,
        uint256 _value
    ) external onlyOwner nonReentrant {
        IERC20(_token_address).safeTransfer(_receiver, _value);
    }

    // </Admin features>

    // <Bettor features>
    function betSlip(Bet[] memory _betSlipList) external nonReentrant {
        for (uint256 i = 0; i < _betSlipList.length; i++) {
            _placeBet(
                msg.sender,
                _betSlipList[i].competionContract,
                _betSlipList[i].betIndexs
            );
        }
    }

    function acceptP2P(address _p2pCompetition)
        external
        onlyP2P(_p2pCompetition)
        nonReentrant
    {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, _p2pCompetition, fee);
        IP2PCompetitionContract(_p2pCompetition).acceptBetting(msg.sender);
    }

    function voteP2P(
        address _p2pCompetition,
        bool _player1Win,
        bool _player2Win
    ) external onlyP2P(_p2pCompetition) nonReentrant {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, _p2pCompetition, fee);
        IP2PCompetitionContract(_p2pCompetition).vote(
            msg.sender,
            _player1Win,
            _player2Win
        );
    }

    // </Bettor features>

    // <Creator features>
    function createNewRegularCompetition(
        string memory _competitionId,
        ICompetitionFactory.Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external nonReentrant {
        address competitionContract = competitionFactory
            .createRegularCompetitionContract(
                msg.sender,
                _competitionId,
                _time,
                _entryFee,
                _team1,
                _team2,
                _minEntrant,
                _sportTypeAlias,
                _betOptions
            );
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.Regular, true);
        creator[competitionContract] = msg.sender;
        emit CreatedNewRegularCompetition(msg.sender, competitionContract, fee);
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            competitionContract,
            fee
        );
        IRegularCompetitionContract(competitionContract).start();
    }

    function createNewGuaranteedCompetition(
        string memory _competitionId,
        ICompetitionFactory.Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        ICompetitionFactory.Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external nonReentrant {
        address competitionContract = competitionFactory
            .createNewGuaranteedCompetitionContract(
                msg.sender,
                _competitionId,
                _time,
                _entryFee,
                _team1,
                _team2,
                _sportTypeAlias,
                _guaranteedFee,
                _entrant,
                _betOptions
            );
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.Guarantee, true);
        creator[competitionContract] = msg.sender;
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            competitionContract,
            fee + _guaranteedFee
        );
        IGuaranteedCompetitionContract(competitionContract).start();
        emit CreatedNewGuaranteedCompetition(
            msg.sender,
            competitionContract,
            fee + _guaranteedFee
        );
    }

    function createNewP2PCompetition(
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head
    ) external nonReentrant {
        address competitionContract = competitionFactory
            .createP2PCompetitionContract(
                msg.sender,
                _player2,
                _entryFee,
                _startBetTime,
                _startP2PTime,
                _sportTypeAlias,
                _head2head
            );
        pools.push(competitionContract);
        existed[competitionContract] = Pool(Type.P2P, true);
        creator[competitionContract] = msg.sender;
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            competitionContract,
            fee
        );
        emit CreatedNewP2PCompetition(msg.sender, competitionContract, fee);
    }

    // </Creator features>

    // <View functions>
    function refundable(address _regular)
        external
        view
        override
        returns (bool)
    {
        IRegularCompetitionContract betting = IRegularCompetitionContract(
            _regular
        );
        (bytes32 _resultId, uint256 _priceValidationTimestamp) = betting
            .getDataToCheckRefund();
        if (
            block.timestamp >
            (_priceValidationTimestamp + maxTimeWaitForRefunding) &&
            !IChainLinkOracleSportData(betting.oracle()).checkFulfill(_resultId)
        ) return true; //refund

        return false; //don't refund
    }

    function isCompetitionExisted(address _pool)
        external
        view
        override
        returns (bool)
    {
        return existed[_pool].existed;
    }

    function getMaxTimeWaitForRefunding()
        external
        view
        override
        returns (uint256)
    {
        return maxTimeWaitForRefunding;
    }

    // </View functions>

    // <Internal function>
    function _placeBet(
        address _user,
        address _competitionContract,
        uint256[] memory betIndexs
    ) private onlyExistedPool(_competitionContract) {
        ICompetitionContract competitionContract = ICompetitionContract(
            _competitionContract
        );
        uint256 totalFee = competitionContract.getEntryFee() +
            competitionContract.getFee();

        IERC20(tokenAddress).safeTransferFrom(
            _user,
            _competitionContract,
            totalFee
        );
        competitionContract.placeBet(_user, betIndexs);
    }
    // </Internal function>
}
