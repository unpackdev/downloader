// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.23;

contract WethCustomOracle {

    uint256 ethValuePerToken;
    uint256 lastUpdateGlobal;

    address public master;
    uint80 public globalRoundId;

    uint8 decimalsETHValue = 18;

    mapping(uint80 => uint256) public timeStampByroundId;

    modifier onlyOwner() {
        require(
            msg.sender == master,
            "WethCustomOracle: NOT_MASTER"
        );
        _;
    }

    constructor(
        uint256 _ethValue,
        uint8 _decimals
    )
    {
        ethValuePerToken = _ethValue;
        decimalsETHValue = _decimals;

        master = msg.sender;
    }

    function renounceOwnership()
        external
        onlyOwner
    {
        master = address(0x0);
    }

    function latestAnswer()
        external
        view
        returns (uint256)
    {
        return ethValuePerToken;
    }

    function decimals()
        external
        view
        returns (uint8)
    {
        return decimalsETHValue;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answerdInRound
        )
    {
        updatedAt = lastUpdateGlobal;
        roundId = globalRoundId;

        return (
            roundId,
            int256(ethValuePerToken),
            startedAt,
            updatedAt,
            answerdInRound
        );
    }

    function setLastUpdateGlobal(
        uint256 _time
    )
        external
        onlyOwner
    {
        lastUpdateGlobal = _time;
    }

    function setValue(
        uint256 _ethValue
    )
        external
        onlyOwner
    {
        ethValuePerToken = _ethValue;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        updatedAt = timeStampByroundId[_roundId];

        return (
            _roundId,
            int256(ethValuePerToken),
            startedAt,
            updatedAt,
            answeredInRound
        );
    }

    function setRoundData(
        uint80 _roundId,
        uint256 _updateTime
    )
        external
        onlyOwner
    {
        timeStampByroundId[_roundId] = _updateTime;
    }

    function getTimeStamp()
        external
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function setGlobalAggregatorRoundId(
        uint80 _aggregatorRoundId
    )
        external
        onlyOwner
    {
        globalRoundId = _aggregatorRoundId;
    }
}