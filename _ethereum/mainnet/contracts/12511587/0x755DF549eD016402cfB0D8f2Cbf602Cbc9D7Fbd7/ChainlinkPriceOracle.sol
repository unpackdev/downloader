/*
 * Curio StableCoin System
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./ChainlinkClient.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

/** 
 *  Ferrari F12 TDF price oracle
 */
contract ChainlinkPriceOracle is Ownable, ChainlinkClient {
    using SafeERC20 for IERC20;

    string public constant ORACLE_NAME = "Ferrari F12 TDF price oracle";

    address public oracle;
    bytes32 public jobId;
    uint256 public fee;

    struct PriceData {
        uint128 latestPrice;
        uint32 priceUpdateTime; // timestamp
    }
    PriceData public priceData;

    mapping(address => bool) public admins;

    event FulfilledPrice(bytes32 requestId, uint128 price, uint32 timestamp);

    event SetOracle(address oracle);
    event SetJobId(bytes32 jobId);
    event SetFee(uint256 fee);
    event SetAdminStatus(address admin, bool status);

    modifier onlyAdmin() {
        require(admins[msg.sender], "Caller is not the admin");
        _;
    }

    constructor() public {
    	setPublicChainlinkToken();

        // MAINNET SETTINGS
    	oracle = 0x240BaE5A27233Fd3aC5440B5a598467725F7D1cd; // oracle address
    	jobId = "fe62ccd5abe74bf28ef3518b174ae8b5"; // job id - Ferrari F12 TDF price - One Fault
    	fee = 0.5 * 10 ** 18; // 0.5 LINK

        admins[msg.sender] = true;
    }


    function latestPrice() external view returns (uint256) {
        return priceData.latestPrice;
    }

    function priceUpdateTime() external view returns (uint256) {
        return priceData.priceUpdateTime;
    }

    // current version compatibility
    function latestAnswer() external view returns (int256) {
        return int256(priceData.latestPrice);
    }


    // onlyAdmin function
    function requestPrice() external onlyAdmin returns (bytes32 requestId) {
    	Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfillPrice.selector);
    	return sendChainlinkRequestTo(oracle, req, fee);
    }
    
    // callback oracle function
    function fulfillPrice(bytes32 _requestId, uint256 _price) external recordChainlinkFulfillment(_requestId) {
        uint32 curTimestamp = uint32(block.timestamp);
    	priceData.latestPrice = uint128(_price);
        priceData.priceUpdateTime = curTimestamp;
        emit FulfilledPrice(_requestId, uint128(_price), curTimestamp);
    }


    // onlyOwner functions

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit SetOracle(_oracle);
    }

    function setJobId(bytes32 _jobId) external onlyOwner {
        jobId = _jobId;
        emit SetJobId(_jobId);
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }

    function setAdminStatus(address _admin, bool _status) external onlyOwner {
        admins[_admin] = _status;
        emit SetAdminStatus(_admin, _status);
    }

    function withdrawTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(owner(), _amount);
    }
}