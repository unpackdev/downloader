// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IAXYSNFT.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

contract AXYSPaymaster is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    // USDT token instance
    IERC20Upgradeable usdtToken;

    // Use for USDT token transfer safely
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Boolean variables to control specific functionalities
    bool public isTransactionFeeAllowed;

    // Integers state variables
    uint256 public transactionFee;
    uint256 public creatorPercentage;
    uint256 public custodyWalletPercentage;

    // Addresses for admin wallet & different receivers
    address public adminWallet;
    address public creatorAddress;
    address public fixedAmountReceiver;
    address public custodyWalletAddress;
    address public transactionFeeReceiver;

    // Addresses for different contracts
    address public axysNftContractAddress;
    address public usdtContractAddress;

    // Event emitted upon transfer amount
    event AmountTransfered(
        bool isUSDT,
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

    // Event emitted upon when transfer fee send in blockchian native token
    event SentTransactionFeeInNativeTokens(
        uint256 totalAmount,
        uint256 Tranacationfee,
        address sender,
        address transactionFeeReceiver
    );

    // Event emitted upon when transfer fee send in USDT
    event SentTransactionFeeInUSDT(
        uint256 totalAmount,
        uint256 Tranacationfee,
        address sender,
        address transactionFeeReceiver
    );

    // Modifier to ensure required addresses are not set to zero address
    modifier amountReceivers() {
        require(
            creatorAddress != address(0) &&
                fixedAmountReceiver != address(0) &&
                custodyWalletAddress != address(0),
            "Zero address not allowed"
        );
        _;
    }

    // Modifier to restrict access to only the contract owner or admin wallet
    modifier onlyOwnerOrAdmin() {
        require(
            _msgSender() == owner() || _msgSender() == adminWallet,
            "Access denied"
        );
        _;
    }

    // Modifier to prevent functions from being called with zero address arguments
    modifier restrictZeroAddress(address _address) {
        require(_address != address(0), "Invalid Address");
        _;
    }

    /**
     * @dev Initializes the contract with initial values.
     * @param _creatorAddress Address of the creator.
     * @param _fixedAmountReceiver Address to receive fixed amounts.
     * @param _custodyWalletAddress Address for custody wallet.
     * @param _transactionFeeReceiver Address to receive transaction fees.
     */
    function initialize(
        address _creatorAddress,
        address _fixedAmountReceiver,
        address _custodyWalletAddress,
        address _transactionFeeReceiver,
        address _usdtContractAddress
    ) public initializer {
        require(
            _creatorAddress != address(0) &&
                _fixedAmountReceiver != address(0) &&
                _custodyWalletAddress != address(0) &&
                _transactionFeeReceiver != address(0) &&
                _usdtContractAddress != address(0),
            "Zero address not allowed"
        );
        transactionFee = 5; // 0.5% transaction fee
        creatorPercentage = 600; // receive 60 percent amount
        custodyWalletPercentage = 400; // receive 40 percent amount
        creatorAddress = _creatorAddress;
        fixedAmountReceiver = _fixedAmountReceiver;
        custodyWalletAddress = _custodyWalletAddress;
        transactionFeeReceiver = _transactionFeeReceiver;
        usdtContractAddress = _usdtContractAddress;
        usdtToken = IERC20Upgradeable(usdtContractAddress);
        __Ownable_init();
    }

    /**
     * @dev Sets whether transaction fees are allowed or not.
     * @param _isTransactionFeeAllowed Boolean value to allow transaction fees.
     */
    function setIsTransactionFeeAllowed(
        bool _isTransactionFeeAllowed
    ) public onlyOwner {
        require(
            _isTransactionFeeAllowed != isTransactionFeeAllowed,
            "Revert with same value"
        );
        isTransactionFeeAllowed = _isTransactionFeeAllowed;
    }

    /**
     * @dev Sets the address for the USDT contract and initializes the token.
     * @param _usdtContractAddress Address of the USDT contract.
     */
    function setUsdtContractAddress(
        address _usdtContractAddress
    ) public onlyOwner restrictZeroAddress(_usdtContractAddress) {
        usdtContractAddress = _usdtContractAddress;
    }

    /**
     * @dev Sets addresses for fixed amount receiver, creator, and custody wallet.
     * @param _fixedAmountReceiver Address to receive fixed amounts.
     * @param _creator Address of the creator.
     * @param _custodyWallet Address for custody wallet.
     */
    function setAmountReceiverAddresses(
        address _fixedAmountReceiver,
        address _creator,
        address _custodyWallet
    ) public onlyOwner {
        require(
            _fixedAmountReceiver != address(0) &&
                _creator != address(0) &&
                _custodyWallet != address(0),
            "Invalid Address"
        );
        creatorAddress = _creator;
        custodyWalletAddress = _custodyWallet;
        fixedAmountReceiver = _fixedAmountReceiver;
    }

    /**
     * @dev Sets the admin wallet address.
     * @param _adminWallet Address of the admin wallet.
     */
    function setAdminWallet(
        address _adminWallet
    ) public onlyOwner restrictZeroAddress(_adminWallet) {
        adminWallet = _adminWallet;
    }

    /**
     * @dev Sets the percentage amounts for creator and custody wallet.
     * @param _creatorPercentage Percentage for the creator.
     * @param _custodyWalletPercentage Percentage for the custody wallet.
     */
    function setReceiveingAmountPercentage(
        uint256 _creatorPercentage,
        uint256 _custodyWalletPercentage
    ) public onlyOwner {
        creatorPercentage = _creatorPercentage;
        custodyWalletPercentage = _custodyWalletPercentage;
    }

    /**
     * @dev Sets the NFT contract address.
     * @param _axysNftContract Address of the NFT contract address.
     */
    function setAXYSNftContract(
        address _axysNftContract
    ) public onlyOwner restrictZeroAddress(_axysNftContract) {
        axysNftContractAddress = _axysNftContract;
    }

    /**
     * @notice Sets the transaction fee percentage.
     * @param _transactionFee Transaction fee percentage.
     */
    function setTransactionFee(uint256 _transactionFee) public onlyOwner {
        transactionFee = _transactionFee;
    }

    /**
     * @notice Sets the address to receive transaction fees.
     * @param _transactionFeeReceiver Address to receive transaction fees.
     */
    function setTransactionFeeReceiver(
        address _transactionFeeReceiver
    ) public onlyOwner restrictZeroAddress(_transactionFeeReceiver) {
        transactionFeeReceiver = _transactionFeeReceiver;
    }

    /**
     * @notice Handles minting of NFTs with ETH, including fee calculation and transfer.
     * @param _to Address to receive the minted NFT.
     * @param _randomString Random string for NFT mintng.
     * @param _uri URI for NFT metadata.
     * @param _price Price in ETH for the NFT.
     * @param _fixedAmount Fixed amount to be deducted.
     */
    function lazyMintWithNativeTokens(
        address _to,
        bytes32 _randomString,
        string memory _uri,
        uint256 _price,
        uint256 _fixedAmount
    ) public payable whenNotPaused amountReceivers {
        uint256 fee = 0;
        if (isTransactionFeeAllowed)
            fee = paymasterFeeCalculator(_price, transactionFee);
        require(msg.value == _price + fee, "Invalid price");
        _lazyMint(_to, _randomString, _uri, _price, _fixedAmount, fee, false);
        emit SentTransactionFeeInNativeTokens(
            msg.value,
            fee,
            _msgSender(),
            transactionFeeReceiver
        );
    }

    /**
     * @notice Handles minting of NFTs with USDT, including fee calculation and transfer.
     * @param _to Address to receive the minted NFT.
     * @param _randomString Random string for NFT minting.
     * @param _uri URI for NFT metadata.
     * @param _price Price in USDT for the NFT.
     * @param _fixedAmount Fixed amount to be deducted.
     */
    function lazyMintWithUSDT(
        address _to,
        bytes32 _randomString,
        string memory _uri,
        uint256 _price,
        uint256 _fixedAmount,
        uint256 _totalPrice
    ) public payable whenNotPaused amountReceivers {
        uint256 fee = 0;
        bool _isUSDT = true;
        require(_fixedAmount < _price, 'Invalid fixed amount');
        if (isTransactionFeeAllowed)
            fee = paymasterFeeCalculator(_price, transactionFee);
        require(_totalPrice == _price + fee, "Invalid USDT price");
        require(
            usdtToken.balanceOf(_msgSender()) >= _totalPrice / 10 ** 12,
            "Insufficient USDT balance"
        );
        _lazyMint(_to, _randomString, _uri, _price, _fixedAmount, fee, _isUSDT);
        emit SentTransactionFeeInUSDT(
            _totalPrice,
            fee,
            _msgSender(),
            transactionFeeReceiver
        );
    }

    /**
     * @notice mints an NFT in special scenario when free minting allowed by owner.
     * @param _to Address to receive the pre-minted NFT.
     * @param _randomString Random string for NFT metadata.
     * @param _uri URI for NFT metadata.
     */
    function preMintNft(
        address _to,
        bytes32 _randomString,
        string memory _uri
    ) public whenNotPaused {
        IAXYSNFT(axysNftContractAddress).preMintNft(_to, _randomString, _uri);
    }

    /**
     * @notice Mints an NFT by admins.
     * @param _to Address to receive the minted NFT.
     * @param _randomString Random string for NFT metadata.
     * @param _uri URI for NFT metadata.
     */
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

    /**
     * @notice Internal function for minting NFTs, fee calculation, and transfers.
     * @param _isUSDT Boolean indicating whether USDT is used.
     * @param _to Address to receive the minted NFT.
     * @param _randomString Random string for NFT metadata.
     * @param _uri URI for NFT metadata.
     * @param _price Price in ETH or USDT for the NFT.
     * @param _fixedAmount Fixed amount to be deducted.
     * @param _fee Fee amount for the transaction.
     */
    function _lazyMint(
        address _to,
        bytes32 _randomString,
        string memory _uri,
        uint256 _price,
        uint256 _fixedAmount,
        uint256 _fee,
        bool _isUSDT
    ) internal whenNotPaused amountReceivers {
        IAXYSNFT(axysNftContractAddress).lazyMint(
            _to,
            _randomString,
            _uri,
            _price
        );
        if (_price != 0) _transferAmount(_isUSDT, _price, _fixedAmount, _fee);
    }

    /**
     * @notice Internal function for transferring amounts based on the payment method.
     * @param _isUSDT Boolean indicating whether USDT is used.
     * @param _price Price in ETH or USDT for the NFT.
     * @param _fixedAmount Fixed amount to be deducted.
     * @param _fee Fee amount for the transaction.
     */
    function _transferAmount(
        bool _isUSDT,
        uint256 _price,
        uint256 _fixedAmount,
        uint256 _fee
    ) internal whenNotPaused nonReentrant {
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
            paymasterFeeTransfer(_isUSDT, _fixedAmount, fixedAmountReceiver);
        if (_fee != 0)
            paymasterFeeTransfer(_isUSDT, _fee, transactionFeeReceiver);
        paymasterFeeTransfer(_isUSDT, _creatorPrice, creatorAddress);
        paymasterFeeTransfer(
            _isUSDT,
            _custodyWalletPrice,
            custodyWalletAddress
        );
        paymasterFeeTransfer(
            _isUSDT,
            _creatorTransactionFee,
            transactionFeeReceiver
        );
        emit AmountTransfered(
            _isUSDT,
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

    /**
     * @notice Internal function to calculate the transaction fee.
     * @param _percentage Percentage to calculate the fee.
     * @param _amount Amount to apply the percentage on.
     */
    function paymasterFeeCalculator(
        uint256 _percentage,
        uint256 _amount
    ) internal pure returns (uint256) {
        uint256 fee = (_amount * _percentage) / 1000;
        return fee;
    }

    /**
     * @notice Internal function to transfer fees based on the payment method.
     * @param isUSDT Boolean indicating whether USDT is used.
     * @param _amount Amount to transfer.
     * @param _receiver Address to receive the transferred amount.
     */
    function paymasterFeeTransfer(
        bool isUSDT,
        uint256 _amount,
        address _receiver
    ) internal {
        if (!isUSDT)
            payable(_receiver).transfer(_amount);
        else
            IERC20Upgradeable(usdtContractAddress).safeTransferFrom(
                _msgSender(),
                _receiver,
                _amount
            );
    }

    /**
     * @notice Internal function to get the usdt allowance for paymaster contract.
     */
    function getAllowance() internal view returns (uint256) {
        return usdtToken.allowance(msg.sender, address(this));
    }

    /**
     * @notice Calculate the fee and amount and return the both value.
     * @param _percentage Percentage to calculate the fee.
     * @param _price Amount to apply the percentage on
     */
    function amountCalculator(
        uint256 _percentage,
        uint256 _price
    ) public pure returns (uint256, uint256, uint256) {
        uint256 fee = (_price * _percentage) / 1000;
        uint256 totalPrice = _price + fee;
        return (totalPrice, _price, fee);
    }

    /**
     * @notice Pauses certain functionalities of the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses certain functionalities of the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}