// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
import "./ChainlinkClient.sol";
import "./String.sol";
import "./SafeERC20.sol";
import "./IBettingPool.sol";
import "./IPriceContract.sol";
import "./Ownable.sol";

contract ChainLinkPrice is ChainlinkClient, Ownable, IPriceContract {
    using Chainlink for Chainlink.Request;
    using SafeERC20 for IERC20;
    using String for string;
    using String for uint256;

    mapping(bytes32 => bool) public isRequest;
    mapping(bytes32 => bool) public isResponse;
    mapping(bytes32 => Price) public price;
    IBettingPool public bettingPool;

    uint256 public fee;
    bytes32 public jobId;

    constructor(
        address _oracle,
        address _linkToken,
        uint256 _fee,
        string memory _jobId,
        address _bettingPool
    ) public {
        setChainlinkOracle(_oracle);
        setChainlinkToken(_linkToken);
        jobId = _jobId.stringToBytes32();
        fee = _fee;
        bettingPool = IBettingPool(_bettingPool);
    }

    function setBettingPool(address _bettingPool) external onlyOwner {
        require(_bettingPool != address(0));
        bettingPool = IBettingPool(_bettingPool);
    }

    function setJobId(
        address _oracle,
        string memory _jobId,
        uint256 _fee
    ) public onlyOwner {
        setChainlinkOracle(_oracle);
        jobId = _jobId.stringToBytes32();
        fee = _fee;
    }

    function setLinkToken(address _linkToken) public onlyOwner {
        require(_linkToken != address(0));
        setChainlinkToken(_linkToken);
    }

    function updatePrice(
        uint256 _timestamp,
        address _tokens,
        uint256 _priceDecimals
    ) external override returns (bytes32) {
        require(_priceDecimals <= 18, "Price decimals over");
        require(
            bettingPool.checkBettingContractExist(msg.sender),
            "You don't have right call updatePrice"
        );
        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        string memory symbol = IERC20(_tokens).symbol();
        (symbol, ) = symbol.trim();
        request.add("symbol", symbol);
        request.add("time", _timestamp.toString());
        int256 times = int256(10**_priceDecimals);
        request.addInt("times", times);
        bytes32 requestId = sendChainlinkRequest(request, fee);
        isRequest[requestId] = true;
        price[requestId].decimals = _priceDecimals;
        emit GetPrice(requestId, symbol, _timestamp, _priceDecimals);
        return requestId;
    }

    function fulfill(bytes32 _requestId, uint256 _price)
        public
        recordChainlinkFulfillment(_requestId)
    {
        require(
            msg.sender == chainlinkOracleAddress(),
            "ChainLinkContract: Only called by ChainlinkOracle"
        );
        require(
            isRequest[_requestId],
            "ChainLinkContract: Request is not exist"
        );
        require(
            !isResponse[_requestId],
            "ChainLinkContract: Request was received response"
        );
        price[_requestId].value = _price;
        isResponse[_requestId] = true;
        emit ReceivePrice(
            _requestId,
            price[_requestId].value,
            price[_requestId].decimals
        );
    }

    function getPrice(bytes32 _id)
        external
        view
        override
        returns (uint256 value, uint256 decimals)
    {
        require(isRequest[_id], "ChainLinkContract: Cannot request price");
        require(
            isResponse[_id],
            "ChainLinkContract: Have not received any feedback about the price"
        );
        return (price[_id].value, price[_id].decimals);
    }

    function getBalanceLinkToken() public view returns (uint256) {
        return IERC20(chainlinkTokenAddress()).balanceOf(address(this));
    }

    function checkFulfill(bytes32 _requestId) external view returns (bool) {
        return isResponse[_requestId];
    }

    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(owner, _amount);
    }
}
