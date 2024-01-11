// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract FeeManager is Ownable {
    using SafeMath for uint256;

    /// @notice Fees Information for Factory
    struct FactoryFeeInfo {
        bool isFeeDistributor;
        address feeToken;
        uint256 feeAmount;
        uint256 totalFeesAcquired;
    }

    mapping(address => FactoryFeeInfo) public factoryFeeInfos;

    address payable public feeBeneficiary;

    event FeesUpdated(
        address indexed factoryAddress,
        uint256 indexed feeAmount,
        address indexed feeToken
    );

    event FetchedFees(
        address indexed factoryAddress,
        uint256 indexed feeAmount,
        address indexed feeToken
    );

    constructor(address payable _beneficiary) {
        feeBeneficiary = _beneficiary;
    }

    /**
     * @notice Fetch fees from valid feeDistributors contract when called externally
     */
    function fetchFees() external payable returns (uint256 fetchedFees) {
        fetchedFees = _fetchFees(false, 0);
    }

    /**
     * @notice It determines fees to be taken based on `_exactFees`.
     */
    function _fetchFees(bool _exactFees, uint256 _feeAmount)
        private
        returns (uint256 fetchedFees)
    {
        FactoryFeeInfo storage feeInfo = factoryFeeInfos[msg.sender];
        require(feeInfo.isFeeDistributor, "Invalid Fee Distributor");

        fetchedFees = _exactFees ? _feeAmount : feeInfo.feeAmount;

        if (feeInfo.feeToken == address(0)) {
            require(msg.value == fetchedFees, "Invalid Fee Amount");
        } else {
            TransferHelper.safeTransferFrom(
                feeInfo.feeToken,
                msg.sender,
                address(this),
                fetchedFees
            );
        }
        feeInfo.totalFeesAcquired = feeInfo.totalFeesAcquired.add(fetchedFees);

        emit FetchedFees(msg.sender, fetchedFees, feeInfo.feeToken);
    }

    /**
     * @notice Fetch fees from valid feeDistributors contract when called externally
     */
    function fetchExactFees(uint256 _feeAmount)
        external
        payable
        returns (uint256 fetchedFees)
    {
        fetchedFees = _fetchFees(true, _feeAmount);
    }

    /**
     * @notice Updates or Create a new Information for a Factory Contract
     */
    function updateFactoryFeesInfo(
        address _factory,
        uint256 _feeAmount,
        address _feeToken
    ) external onlyOwner {
        require(_factory != address(0), "Factory cant be zero address");
        FactoryFeeInfo storage feeInfo = factoryFeeInfos[_factory];
        feeInfo.feeAmount = _feeAmount;
        feeInfo.feeToken = _feeToken;
        feeInfo.isFeeDistributor = true;
        emit FeesUpdated(_factory, _feeAmount, _feeToken);
    }

    function setFeeBeneficiary(address payable _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary cant be zero address");
        feeBeneficiary = _beneficiary;
    }

    function withdrawAcquiredFees(address _token, uint256 _amount)
        external
        onlyOwner
    {
        if (_token == address(0)) {
            TransferHelper.safeTransferETH(feeBeneficiary, _amount);
        } else {
            TransferHelper.safeTransfer(_token, feeBeneficiary, _amount);
        }
    }

    function getFactoryFeeInfo(address _factory)
        external
        view
        returns (uint256 _feeAmount, address _feeToken)
    {
        FactoryFeeInfo memory feeInfo = factoryFeeInfos[_factory];
        return (feeInfo.feeAmount, feeInfo.feeToken);
    }
}
