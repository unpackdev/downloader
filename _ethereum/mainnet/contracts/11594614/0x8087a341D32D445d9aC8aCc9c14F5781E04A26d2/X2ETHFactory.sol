// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./IX2ETHFactory.sol";
import "./IX2Token.sol";
import "./IChi.sol";

import "./X2ETHMarket.sol";
import "./X2Token.sol";

contract X2ETHFactory is IX2ETHFactory {
    using SafeMath for uint256;

    uint256 public constant MAX_FEE_BASIS_POINTS = 40; // max 0.4% fee
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public gov;
    address public distributor;
    address public override feeReceiver;

    address[] public markets;
    bool public freeMarketCreation = false;

    mapping (address => uint256) public feeBasisPoints;

    event CreateMarket(
        address priceFeed,
        uint256 multiplierBasisPoints,
        uint256 maxProfitBasisPoints,
        uint256 index
    );

    event GovChange(address gov);
    event FeeChange(address market, uint256 fee);
    event FeeReceiverChange(address feeReceiver);
    event DistributorChange(address token, address distributor);
    event InfoChange(address token, string name, string symbol);
    event FundingChange(address market, uint256 fundingPoints, uint256 fundingInterval);

    modifier onlyGov() {
        require(msg.sender == gov, "X2Factory: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function marketsLength() external view returns (uint256) {
        return markets.length;
    }

    function enableFreeMarketCreation() external onlyGov {
        freeMarketCreation = true;
    }

    function setDistributor(address _token, address _distributor) external onlyGov {
        IX2Token(_token).setDistributor(_distributor);
        emit DistributorChange(_token, _distributor);
    }

    function setFunding(address _market, uint256 _fundingPoints, uint256 _fundingInterval) external onlyGov {
        IX2Market(_market).setFunding(_fundingPoints, _fundingInterval);
        emit FundingChange(_market, _fundingPoints, _fundingInterval);
    }

    function setInfo(
        address _bullToken,
        string calldata _bullName,
        string calldata _bullSymbol,
        address _bearToken,
        string calldata _bearName,
        string calldata _bearSymbol
    ) external onlyGov {
        IX2Token(_bullToken).setInfo(_bullName, _bullSymbol);
        IX2Token(_bearToken).setInfo(_bearName, _bearSymbol);
        emit InfoChange(_bullToken, _bullName, _bullSymbol);
        emit InfoChange(_bearToken, _bearName, _bearSymbol);
    }

    function setChi(address _market, IChi _chi) external onlyGov {
        X2ETHMarket(_market).setChi(_chi);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
        emit GovChange(gov);
    }

    function setFee(address _market, uint256 _feeBasisPoints) external onlyGov {
        require(_feeBasisPoints <= MAX_FEE_BASIS_POINTS, "X2Factory: fee exceeds allowed limit");
        feeBasisPoints[_market] = _feeBasisPoints;
        emit FeeChange(_market, _feeBasisPoints);
    }

    function setFeeReceiver(address _feeReceiver) external onlyGov {
        feeReceiver = _feeReceiver;
        emit FeeReceiverChange(feeReceiver);
    }

    function getFee(address _market, uint256 _amount) external override view returns (uint256) {
        return _amount.mul(feeBasisPoints[_market]).div(BASIS_POINTS_DIVISOR);
    }

    function createMarket(
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        uint256 _maxProfitBasisPoints
    ) external returns (address, address, address) {
        if (!freeMarketCreation) {
            require(msg.sender == gov, "X2Factory: forbidden");
        }

        X2ETHMarket market = new X2ETHMarket();
        market.initialize(
            address(this),
            _priceFeed,
            _multiplierBasisPoints,
            _maxProfitBasisPoints
        );

        X2Token bullToken = new X2Token();
        bullToken.initialize(address(this), address(market));

        X2Token bearToken = new X2Token();
        bearToken.initialize(address(this), address(market));

        market.setBullToken(address(bullToken));
        market.setBearToken(address(bearToken));

        markets.push(address(market));

        emit CreateMarket(
            _priceFeed,
            _multiplierBasisPoints,
            _maxProfitBasisPoints,
            markets.length - 1
        );

        return (address(market), address(bullToken), address(bearToken));
    }
}
