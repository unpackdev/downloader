pragma solidity ^0.6.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

import "./IMint.sol";

contract SimpleXBEInflation is Ownable, Initializable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IMint public token;

    uint256 public totalMinted;
    uint256 public targetMinted;
    uint256 public periodicEmission;
    uint256 public startInflationTime;

    uint256 public periodDuration; // seconds

    mapping(address => uint256) public weights; // in points relative to sumWeight
    uint256 public sumWeight;

    EnumerableSet.AddressSet internal xbeReceivers;

    // """
    // @notice Contract constructor
    // @param _name Token full name
    // @param _symbol Token symbol
    // @param _decimals Number of decimals for token
    // @param _targetMinted max amount minted during
    // """
    function configure(
        IMint _token,
        uint256 _targetMinted,
        uint256 _periodsCount,
        uint256 _periodDuration
    ) external onlyOwner initializer {
        token = _token;
        targetMinted = _targetMinted;
        periodicEmission = _targetMinted.div(_periodsCount);
        periodDuration = _periodDuration;
        require(periodDuration > 0, "periodDuration=0");
        startInflationTime = block.timestamp;
    }

    // """
    // @notice Current number of tokens in existence (claimed or unclaimed)
    // """
    function availableSupply() external view returns (uint256) {
        return totalMinted;
    }

    function setXBEReceiver(address _xbeReceiver, uint256 _weight)
        external
        onlyOwner
    {
        if (!xbeReceivers.contains(_xbeReceiver)) {
            xbeReceivers.add(_xbeReceiver);
        }

        uint256 oldWeight = weights[_xbeReceiver];
        sumWeight = sumWeight.add(_weight).sub(oldWeight);
        weights[_xbeReceiver] = _weight;
    }

    function removeXBEReceiver(address _xbeReceiver) external onlyOwner {
        sumWeight = sumWeight.sub(weights[_xbeReceiver]);
        xbeReceivers.remove(_xbeReceiver);
    }

    function receiversCount() external view returns (uint256) {
        return xbeReceivers.length();
    }

    function receiverAt(uint256 index) external view returns (address) {
        return xbeReceivers.at(index);
    }

    function _getPeriodsPassed() internal view returns (uint256) {
        return block.timestamp.sub(startInflationTime).div(periodDuration);
    }

    // """
    // @notice Mint part of available supply of tokens and assign them to approved contracts
    // @dev Emits a Transfer event originating from 0x00
    // @return bool success
    // """u
    function mintForContracts() external {
        require(totalMinted <= targetMinted, "inflationEnded");
        if (xbeReceivers.length() > 0) {
            require(sumWeight > 0, "sumWeights=0");
        }

        // distribute prepaid amount for the upfront period
        uint256 periodsToPay = _getPeriodsPassed().add(1);
        // if we missed a payment, the amount will be multiplied

        uint256 plannedToMint = periodsToPay.mul(periodicEmission);
        require(totalMinted < plannedToMint, "availableSupplyDistributed");
        uint256 amountToPay = plannedToMint.sub(totalMinted);

        totalMinted = totalMinted.add(amountToPay);

        for (uint256 i = 0; i < xbeReceivers.length(); i++) {
            address _to = xbeReceivers.at(i);
            require(_to != address(0), "!zeroAddress");

            uint256 toMint = amountToPay.mul(weights[_to]).div(sumWeight);
            token.mint(_to, toMint);
        }
    }
}
