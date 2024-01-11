//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IDB.sol";
import "./IUSDT.sol";
import "./Address.sol";
import "./Ownable.sol";

contract Database is Ownable, IDB {
    address private paymentFeeToken;
    address private recepient;
    address public adminWallet;

    uint256 private ownerFee;
    uint256 private polkaLokrFee;
    uint256 private bridgeFee;

    mapping(address => bool) private isFeePaid;

    event FeePaid(address depositor, uint256 amount);
    event FeeTokenUpdated(address updatedBy, address _newToken);

    constructor(address _feeToken, address _adminWallet) {
        paymentFeeToken = _feeToken;
        ownerFee = 5 ether;
        polkaLokrFee = 70 ether;
        bridgeFee = 0.000000003 ether;
        recepient = msg.sender;
        adminWallet = _adminWallet;
    }

    modifier zeroAddress(address _addr) {
        require(_addr != address(0), "ZERO_ADDRESS");
        _;
    }

    // Getter functions
    function getOwnerFee() external view override returns (uint256) {
        return ownerFee;
    }

    function getBridgerFee() external view returns (uint256) {
        return bridgeFee;
    }

    function getPolkaLokrFee() external view override returns (uint256) {
        return polkaLokrFee;
    }

    function getRecepient() external view override returns (address) {
        return recepient;
    }

    function getFeeStatus(address _tokenAddress) external view returns (bool) {
        return isFeePaid[_tokenAddress];
    }

    function getPaymentFeeToken() external view returns (address) {
        return paymentFeeToken;
    }

    // Setter functions
    function setOwnerFee(uint256 _ownerFee) external onlyOwner {
        ownerFee = _ownerFee;
    }

    function setPolkaLokrFee(uint256 _polkaFee) external onlyOwner {
        polkaLokrFee = _polkaFee;
    }

    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        bridgeFee = _bridgeFee;
    }

    function setRecepient(address _recepient)
        external
        zeroAddress(_recepient)
        onlyOwner
    {
        recepient = _recepient;
    }

    function setAdminWallet(address _newAdminWallet)
        external
        zeroAddress(_newAdminWallet)
        onlyOwner
    {
        adminWallet = _newAdminWallet;
    }

    function setPaymentFeeToken(address _newPaymentToken)
        external
        zeroAddress(_newPaymentToken)
        onlyOwner
    {
        paymentFeeToken = _newPaymentToken;
        emit FeeTokenUpdated(msg.sender, paymentFeeToken);
    }

    function payBridgeFee(address _tokenAddress) external {
        require(!isFeePaid[_tokenAddress], "FEES_ALREADY_PAID");
        if (bridgeFee != 0) {
            IUSDT(paymentFeeToken).transferFrom(
                msg.sender,
                adminWallet,
                bridgeFee
            );
        }
        isFeePaid[_tokenAddress] = true;

        emit FeePaid(msg.sender, bridgeFee);
    }

    function addBridge(address bridgeContract, address bridgeOwner)
        external
        override
    {
        emit BridgEdit(bridgeContract, bridgeOwner);
    }
}
