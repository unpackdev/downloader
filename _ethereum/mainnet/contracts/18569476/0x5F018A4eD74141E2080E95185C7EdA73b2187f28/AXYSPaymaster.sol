// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IAXYSNFT.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract AXYSPaymaster is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bool public isTransactionFeeAllowed;

    uint256 public transactionFee;
    uint256 public creatorPercentage;
    uint256 public custodyWalletPercentage;

    address public adminWallet;
    address public creatorAddress;
    address public fixedAmountReceiver;
    address public custodyWalletAddress;
    address public transactionFeeReceiver;
    address public axysNftContractAddress;

    event AmountTransfered(
        uint256 totalAmount,
        uint256 creatorTotalAmount,
        uint256 fixedAmount,
        uint256 creatorAmount,
        uint256 creatorTransactionFee,
        uint256 custodyAmount,
        address creatorAddress,
        address transactionFeeReceiver,
        address fixedAmountReceiver,
        address custodyWalletAddress
    );

    event SentTransactionFee(
        uint256 totalAmount,
        uint256 Tranacationfee,
        address sender,
        address transactionFeeReceiver
    );

    modifier amountReceivers() {
        require(
            creatorAddress != address(0) &&
                fixedAmountReceiver != address(0) &&
                custodyWalletAddress != address(0),
            "Zero address not allowed"
        );
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            _msgSender() == owner() || _msgSender() == adminWallet,
            "Access denied"
        );
        _;
    }

    function initialize(
        address _creatorAddress,
        address _fixedAmountReceiver,
        address _custodyWalletAddress,
        address _transactionFeeReceiver
    ) public initializer {
        transactionFee = 5; // 0.5% transaction fee
        creatorPercentage = 600; // receive 60 percent amount
        custodyWalletPercentage = 400; // receive 40 percent amount
        creatorAddress = _creatorAddress;
        fixedAmountReceiver = _fixedAmountReceiver;
        custodyWalletAddress = _custodyWalletAddress;
        transactionFeeReceiver = _transactionFeeReceiver;
        __Ownable_init();
    }

    function lazyMint(
        address _to,
        bytes32 _randomString,
        string memory _uri,
        uint256 _price,
        uint256 _fixedAmount
    ) public payable whenNotPaused amountReceivers {
        uint256 fee;
        if (isTransactionFeeAllowed)
            fee = paymasterFeeCalculator(_price, transactionFee);
        require(msg.value == _price + fee, "Invalid price");
        IAXYSNFT(axysNftContractAddress).lazyMint(
            _to,
            _randomString,
            _uri,
            _price
        );
        if (_price != 0) _transferAmount(_price, _fixedAmount, fee);
        emit SentTransactionFee(
            msg.value,
            fee,
            _msgSender(),
            transactionFeeReceiver
        );
    }

    function setIsTransactionFeeAllowed(
        bool _isTransactionFeeAllowed
    ) public onlyOwner {
        isTransactionFeeAllowed = _isTransactionFeeAllowed;
    }

    function preMintNft(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) public whenNotPaused {
        IAXYSNFT(axysNftContractAddress).preMintNft(_to, _randomString, _uri);
    }

    function mintNftByAdmins(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) public onlyOwnerOrAdmin {
        IAXYSNFT(axysNftContractAddress).mintNftByAdmins(
            _to,
            _randomString,
            _uri
        );
    }

    function setAmountReceiverAddresses(
        address _fixedAmountReceiver,
        address _creator,
        address _custodyWallet
    ) public onlyOwner {
        creatorAddress = _creator;
        custodyWalletAddress = _custodyWallet;
        fixedAmountReceiver = _fixedAmountReceiver;
    }

    function setAdminWallet(address _adminWallet) public onlyOwner {
        adminWallet = _adminWallet;
    }

    function setReceiveingAmountPercentage(
        uint256 _creatorPercentage,
        uint256 _custodyWalletPercentage
    ) public onlyOwner {
        creatorPercentage = _creatorPercentage;
        custodyWalletPercentage = _custodyWalletPercentage;
    }

    function setAXYSNftContract(address _axysNftContract) public onlyOwner {
        axysNftContractAddress = _axysNftContract;
    }

    function setTransactionFee(uint256 _transactionFee) public onlyOwner {
        transactionFee = _transactionFee;
    }

    function setTransactionFeeReceiver(
        address _transactionFeeReceiver
    ) public onlyOwner {
        transactionFeeReceiver = _transactionFeeReceiver;
    }

    function _transferAmount(
        uint256 _price,
        uint256 _fixedAmount,
        uint256 _fee
    ) private whenNotPaused nonReentrant {
        require(_fixedAmount >= 0, "Invalid discount value");
        uint256 _updatedPrice = _price - _fixedAmount;
        uint256 _creatorTotalPrice = paymasterFeeCalculator(
            _updatedPrice,
            creatorPercentage
        );
        uint256 _creatorTransactionFee = paymasterFeeCalculator(
            _creatorTotalPrice,
            transactionFee
        );
        uint256 _creatorPrice = _creatorTotalPrice - _creatorTransactionFee;
        uint256 _custodyWalletPrice = paymasterFeeCalculator(
            _updatedPrice,
            custodyWalletPercentage
        );
        if (_fixedAmount != 0)
            paymasterFeeTransfer(_fixedAmount, fixedAmountReceiver);
        if (_fee != 0) paymasterFeeTransfer(_fee, transactionFeeReceiver);
        paymasterFeeTransfer(_creatorPrice, creatorAddress);
        paymasterFeeTransfer(_custodyWalletPrice, custodyWalletAddress);
        paymasterFeeTransfer(_creatorTransactionFee, transactionFeeReceiver);

        emit AmountTransfered(
            _price,
            _creatorTotalPrice,
            _fixedAmount,
            _creatorPrice,
            _creatorTransactionFee,
            _custodyWalletPrice,
            creatorAddress,
            transactionFeeReceiver,
            fixedAmountReceiver,
            custodyWalletAddress
        );
    }

    function paymasterFeeCalculator(
        uint256 _percentage,
        uint256 _amount
    ) internal pure returns (uint256) {
        uint256 fee = (_amount * _percentage) / 1000;
        return fee;
    }

    function paymasterFeeTransfer(uint256 _amount, address _receiver) internal {
        payable(_receiver).transfer(_amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
