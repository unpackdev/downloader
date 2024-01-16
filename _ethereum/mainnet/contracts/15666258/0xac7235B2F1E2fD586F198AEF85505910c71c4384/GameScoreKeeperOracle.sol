// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
import "./ChainlinkClient.sol";
import "./ConfirmedOwner.sol";
import "./ReentrancyGuard.sol";
import "./String.sol";
import "./IChainLinkOracleSportData.sol";
import "./ICompetitionPool.sol";
import "./IRegularCompetitionContract.sol";
import "./ISportManager.sol";

/*
CLC01: You don't have right call requestData
CLC02: Address 0x00
CLC03: Exceed rate limit
CLC04: Request is not exist
CLC05: Request was received response
CLC06: Cannot request price
CLC07: Have not received any feedback about the price
CLC08: Unable to transfer
*/

contract GameScoreKeeperOracle is
    ChainlinkClient,
    ConfirmedOwner,
    IChainLinkOracleSportData,
    ReentrancyGuard
{
    using Chainlink for Chainlink.Request;
    using String for string;
    using String for uint256;

    struct Result {
        bytes resultInBytes;
        uint256[] resultInUint;
        address regularAddress;
    }
    event GetData(bytes32 _id);
    event ReceiveData(bytes32 _id, bytes _data);

    mapping(bytes32 => bool) public isRequest;
    mapping(bytes32 => bool) public isResponse;
    mapping(bytes32 => Result) public results;
    mapping(address => uint256) public lastTime;
    mapping(ISportManager.ProviderGameData => bytes32) public jobId;

    uint256 private constant BYTES32_LENGTH = 32;
    uint256 private constant START_INDEX = 96;

    uint256 public payment = (1 * LINK_DIVISIBILITY) / 100;
    uint256 public times = 30 minutes;

    ICompetitionPool public pool;
    address public sportManager;

    constructor(
        address _oracle,
        string memory _jobIdGameScoreKeeper,
        string memory _jobIdSportRadar,
        address _linkToken,
        address _pool,
        address _sportManager
    ) ConfirmedOwner(msg.sender) {
        require(_oracle != address(0) && _sportManager != address(0), "CLC02");
        setChainlinkOracle(_oracle);
        if (_linkToken == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_linkToken);
        }
        jobId[
            ISportManager.ProviderGameData.GameScoreKeeper
        ] = _jobIdGameScoreKeeper.toBytes32();
        jobId[ISportManager.ProviderGameData.SportRadar] = _jobIdSportRadar
            .toBytes32();
        pool = ICompetitionPool(_pool);
        sportManager = _sportManager;
    }

    modifier onlyPermission(address _user) {
        require(pool.isCompetitionExisted(_user), "CLC01");
        _;
    }

    function setJobId(
        ISportManager.ProviderGameData _provider,
        string memory _jobId
    ) external onlyOwner {
        jobId[_provider] = _jobId.toBytes32();
    }

    function setSportManager(address _sportManager) external onlyOwner {
        require(_sportManager != address(0), "CLC02");
        sportManager = _sportManager;
    }

    function setCompetitionPool(address _pool) external onlyOwner {
        require(_pool != address(0), "CLC02");
        pool = ICompetitionPool(_pool);
    }

    function setTimesRequest(uint256 _timesRequest) external onlyOwner {
        times = _timesRequest;
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "CLC02");
        setChainlinkOracle(_oracle);
    }

    function setPayment(uint256 _payment) external onlyOwner {
        payment = _payment;
    }

    function setToken(address _linkToken) external onlyOwner {
        setChainlinkToken(_linkToken);
    }

    function getToken() external view returns (address) {
        return chainlinkTokenAddress();
    }

    function getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }

    function requestData(
        string memory _matchId,
        uint256 _sportId,
        IRegularCompetitionContract.BetOption[] memory _betOptions
    )
        external
        override
        onlyPermission(msg.sender)
        nonReentrant
        returns (bytes32)
    {
        require(block.timestamp > lastTime[msg.sender] + times, "CLC03");
        ISportManager.Game memory game = ISportManager(sportManager)
            .getGameById(_sportId);
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId[game.provider],
            address(this),
            this.fulfill.selector
        );
        string memory queryString = getQueryString(_betOptions);
        request.add("matchId", _matchId);
        request.add("sportId", _sportId.toString());
        request.add("queryString", queryString);
        bytes32 myId = sendChainlinkRequest(request, payment);
        isRequest[myId] = true;
        results[myId].regularAddress = msg.sender;
        lastTime[msg.sender] = block.timestamp;
        emit GetData(myId);
        return myId;
    }

    function fulfill(bytes32 _requestId, bytes memory _data)
        public
        recordChainlinkFulfillment(_requestId)
    {
        require(isRequest[_requestId], "CLC04");
        require(!isResponse[_requestId], "CLC05");
        results[_requestId].resultInBytes = _data;
        results[_requestId].resultInUint = bytesToUint256Array(_data);
        isResponse[_requestId] = true;
        emit ReceiveData(_requestId, _data);
        address regularAddress = results[_requestId].regularAddress;
        IRegularCompetitionContract(regularAddress).setIsResult();
    }

    function getQueryString(
        IRegularCompetitionContract.BetOption[] memory betOptions
    ) public pure returns (string memory) {
        string memory queryString = "";
        for (uint256 i = 0; i < betOptions.length; i++) {
            IRegularCompetitionContract.BetOption memory betOption = betOptions[
                i
            ];
            string memory s;
            s = string(
                abi.encodePacked(
                    uint256(betOption.mode).toString(),
                    ",",
                    uint256(betOption.attribute).toString(),
                    ",",
                    betOption.id,
                    i != betOptions.length - 1 ? "-" : ""
                )
            );
            queryString = queryString.append(s);
        }
        return queryString;
    }

    function getData(bytes32 _id)
        external
        view
        override
        returns (uint256[] memory, address)
    {
        require(isRequest[_id], "CLC06");
        require(isResponse[_id], "CLC07");
        return (results[_id].resultInUint, results[_id].regularAddress);
    }

    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "CLC08"
        );
    }

    function getPayment() external view override returns (uint256) {
        return payment;
    }

    function checkFulfill(bytes32 _requestId)
        external
        view
        override
        returns (bool)
    {
        return isResponse[_requestId];
    }

    function bytesToUint256Array(bytes memory data)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 dataNb = data.length / BYTES32_LENGTH;
        uint256[] memory dataList = new uint256[](dataNb - 2);
        uint256 index = 0;
        for (
            uint256 i = START_INDEX;
            i <= data.length;
            i = i + BYTES32_LENGTH
        ) {
            bytes32 temp;
            assembly {
                temp := mload(add(data, i))
            }
            dataList[index] = uint256(temp);
            index++;
        }
        return (dataList);
    }
}
