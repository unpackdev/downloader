// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Create2.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./PredictionMarket.sol";

contract PredictionMarketFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    event MarketCreated(address indexed tokenAddress);

    address public constant _automate =
        0xB3f5503f93d5Ef84b06993a1975B9D21B962892F;

    EnumerableSet.AddressSet private _markets;
    EnumerableSet.AddressSet private _tokens;

    address public feeToken;
    uint256 public fee;

    uint256 public totalEthPaidOut;

    modifier onlyMarket() {
        require(_markets.contains(msg.sender), "Not an allowed market");
        _;
    }

    function setFeeToken(address _newFeeToken) public onlyOwner {
        feeToken = _newFeeToken;
    }

    function setFee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }

    function addEthPayout(uint256 value) public onlyMarket {
        totalEthPaidOut += value;
    }

    function deployMarket(address _token, address _owner) public payable {
        require(msg.value >= 0 ether, "Not enough gas to pay rounds");
        require(!_tokens.contains(_token), "Makret already exists");

        if (feeToken != address(0) && fee > 0) {
            IERC20(feeToken).transferFrom(msg.sender, owner(), fee);
        }

        PredictionMarket predictionMarket = new PredictionMarket{
            value: msg.value
        }(_token, _automate, _owner);

        predictionMarket.transferOwnership(_owner);
        _markets.add(address(predictionMarket));
        _tokens.add(_token);

        emit MarketCreated(address(predictionMarket));
    }

    function getAllMarkets() public view returns (address[] memory) {
        return _markets.values();
    }
}
