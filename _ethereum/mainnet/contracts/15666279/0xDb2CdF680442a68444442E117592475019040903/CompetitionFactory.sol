// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ICompetitionFactory.sol";
import "./IRegularCompetitionContract.sol";
import "./IGuaranteedCompetitionContract.sol";
import "./IP2PCompetitionContract.sol";
import "./ICompetitionPool.sol";
import "./ISportManager.sol";
import "./CompetitionProxy.sol";

/* ERROR MESSAGE */

// CF01: Game is not supported
// CF02: Exceed limit
// CF03: Address 0x00

contract CompetitionFactory is Ownable, ICompetitionFactory {
    ISportManager public sportManager;
    address public oracle;
    mapping(CompetitionType => address) public typeToAddress;

    uint256 public limitOption = 10;
    uint256 public p2pDistanceAcceptTime = 15 minutes;
    uint256 public p2pDistanceConfirmTime = 15 minutes;
    uint256 public p2pdistanceVoteTime = 45 minutes;
    uint256 public p2pMaximumRefundTime = 24 hours;
    uint256 public regularGapValidatitionTime = 6 hours;
    uint256 public minimumBetime = 1 hours;

    constructor(
        address _p2p,
        address _regular,
        address _guarantee,
        address _sportManager,
        address _chainlinkOracleSportData
    ) {
        require(
            _p2p != address(0) &&
                _regular != address(0) &&
                _guarantee != address(0) &&
                _sportManager != address(0) &&
                _chainlinkOracleSportData != address(0),
            "CF03"
        );
        typeToAddress[CompetitionType.P2PCompetition] = _p2p;
        typeToAddress[CompetitionType.RegularCompetition] = _regular;
        typeToAddress[CompetitionType.GuaranteedCompetition] = _guarantee;
        sportManager = ISportManager(_sportManager);
        oracle = _chainlinkOracleSportData;
    }

    function setCompetitionFactory(
        address _p2p,
        address _regular,
        address _guarantee
    ) external onlyOwner {
        require(
            _p2p != address(0) &&
                _regular != address(0) &&
                _guarantee != address(0),
            "CF03"
        );
        typeToAddress[CompetitionType.P2PCompetition] = _p2p;
        typeToAddress[CompetitionType.RegularCompetition] = _regular;
        typeToAddress[CompetitionType.GuaranteedCompetition] = _guarantee;
        emit UpdateCompetitionFactory(_p2p, _regular, _guarantee);
    }

    function setTypeToAddress(CompetitionType _type, address _newAddr)
        external
        onlyOwner
    {
        require(_newAddr != address(0), "CF03");
        typeToAddress[_type] = _newAddr;
        emit UpdateTypeToAddress(_type, _newAddr);
    }

    function setSportManager(address _sportManager) external onlyOwner {
        require(_sportManager != address(0), "CF03");
        emit UpdateSportManager(address(sportManager), _sportManager);
        sportManager = ISportManager(_sportManager);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "CF03");
        emit UpdateOracle(oracle, _oracle);
        oracle = _oracle;
    }

    function setLimitOption(uint256 _limit) external onlyOwner {
        limitOption = _limit;
    }

    function setGapvalidationTime(uint256 _gapTime) external onlyOwner {
        regularGapValidatitionTime = _gapTime;
    }

    function setMinimumBetTime(uint256 _minimumBetime) external onlyOwner {
        minimumBetime = _minimumBetime;
    }

    function setP2PDistanceTime(
        uint256 _p2pDistanceAcceptTime,
        uint256 _p2pDistanceConfirmTime,
        uint256 _p2pdistanceVoteTime,
        uint256 _p2pMaximumRefundTime
    ) external onlyOwner {
        p2pDistanceAcceptTime = _p2pDistanceAcceptTime;
        p2pDistanceConfirmTime = _p2pDistanceConfirmTime;
        p2pdistanceVoteTime = _p2pdistanceVoteTime;
        p2pMaximumRefundTime = _p2pMaximumRefundTime;
    }

    function createRegularCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _minEntrant,
        uint256 _sportTypeAlias,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external override returns (address) {
        require(_creator != address(0), "CF03");
        require(sportManager.checkSupportedGame(_sportTypeAlias), "CF01");
        require(_betOptions.length <= limitOption, "CF02");

        address proxyAddress = _createCompetitionProxy(typeToAddress[CompetitionType.RegularCompetition], _creator);
        IRegularCompetitionContract competition = IRegularCompetitionContract(proxyAddress);

        if (_time.startBetTime < block.timestamp) {
            _time.startBetTime = block.timestamp;
        }
        competition.setBasic(
            _time.startBetTime,
            _time.endBetTime,
            _entryFee,
            _minEntrant,
            _time.scheduledStartMatchTime,
            minimumBetime
        );
        competition.setCompetition(
            _competitionId,
            _team1,
            _team2,
            _sportTypeAlias,
            address(sportManager)
        );
        competition.setOracle(oracle);
        competition.setBetOptions(_betOptions);
        competition.setGapvalidationTime(regularGapValidatitionTime);
        return proxyAddress;
    }

    function createP2PCompetitionContract(
        address _creator,
        address _player2,
        uint256 _entryFee,
        uint256 _startBetTime,
        uint256 _startP2PTime,
        uint256 _sportTypeAlias,
        bool _head2head
    ) external override returns (address) {
        require(_creator != address(0) && _player2 != address(0), "CF03");
        if (block.timestamp > _startBetTime) {
            _startBetTime = block.timestamp;
        }
        address implementationAddress = typeToAddress[CompetitionType.P2PCompetition];
        address proxyAddress = _createCompetitionProxy(implementationAddress, _creator);
        IP2PCompetitionContract competition = IP2PCompetitionContract(proxyAddress);

        if (_startBetTime < block.timestamp) {
            _startBetTime = block.timestamp;
        }
        competition.setStartAndEndTimestamp(
            _startBetTime,
            _startP2PTime - 1,
            _startP2PTime,
            minimumBetime
        );
        uint256 _minEntrant = _head2head ? 0 : 2;
        competition.setBasic(
            _player2,
            _creator,
            _minEntrant,
            _sportTypeAlias,
            address(sportManager),
            _head2head
        );

        competition.setEntryFee(_entryFee);

        competition.setDistanceTime(
            p2pDistanceAcceptTime,
            p2pDistanceConfirmTime,
            p2pdistanceVoteTime,
            p2pMaximumRefundTime
        );
        return proxyAddress;
    }

    function createNewGuaranteedCompetitionContract(
        address _creator,
        string memory _competitionId,
        Time memory _time,
        uint256 _entryFee,
        string memory _team1,
        string memory _team2,
        uint256 _sportTypeAlias,
        uint256 _guaranteedFee,
        Entrant memory _entrant,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    ) external override returns (address) {
        require(_creator != address(0), "CF03");
        require(sportManager.checkSupportedGame(_sportTypeAlias), "CF01");

        address proxyAddress = _createCompetitionProxy(typeToAddress[CompetitionType.GuaranteedCompetition], _creator);

        if (_time.startBetTime < block.timestamp) {
            _time.startBetTime = block.timestamp;
        }

        IGuaranteedCompetitionContract(proxyAddress).setBasic(
            _time.startBetTime,
            _time.endBetTime,
            _entryFee,
            _entrant.minEntrant,
            _time.scheduledStartMatchTime,
            minimumBetime
        );
        IGuaranteedCompetitionContract(proxyAddress).setMaxEntrantAndGuaranteedFee(_guaranteedFee, _entrant.maxEntrant);
        IGuaranteedCompetitionContract(proxyAddress).setCompetition(
            _competitionId,
            _team1,
            _team2,
            _sportTypeAlias,
            address(sportManager)
        );
        IGuaranteedCompetitionContract(proxyAddress).setOracle(oracle);
        IGuaranteedCompetitionContract(proxyAddress).setBetOptions(_betOptions);
        IGuaranteedCompetitionContract(proxyAddress).setGapvalidationTime(regularGapValidatitionTime);
        return proxyAddress;
    }

    function _createCompetitionProxy(address _implementation, address _creator) private returns(address) {
        ICompetitionPool pool = ICompetitionPool(msg.sender);
        bytes4 initializeSelector = bytes4(keccak256("initialize(address,address,address,address,uint256)"));
        bytes memory data = abi.encodeWithSelector(
            initializeSelector, 
            msg.sender,
            _creator,
            pool.tokenAddress(),
            address(this),
            pool.fee());
        CompetitionProxy proxy = new CompetitionProxy(_implementation, data);
        return address(proxy);
    }
}
