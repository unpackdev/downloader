//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./IERC20.sol";

/**
 * @notice prize distribution handler
 */
contract PrizeDistribution is Ownable, ReentrancyGuard {
    using Address for address payable;

    /// @notice Event emitted only on construction. To be used by indexers
    event PrizeSent(
      address indexed from,
      uint256 indexed amount,
      uint256 indexed rewardType,
      uint256 sendAt
    );

    /// @notice store used nonce from backend verification step
    mapping(uint256 => bool) private nonceToValidated;

    /// ECDSA verification recover key
    address public signingKey;

    /// Prizewallet address to send prizes from 
    address public prizeWallet;

    /// @notice for switching off prize distribution
    bool public isPaused;

    /// @notice ERC20 currency for prize
    IERC20 cbcContract;

    /// @notice ERC20 APE for prize
    IERC20 apeContract;

    modifier whenNotPaused() {
        require(!isPaused, "Function is currently paused");
        _;
    }

    constructor(
        address _prizeWallet,
        address _cbcContractAddress,
        address _apeContractAddress,
        address _signingKey
    ) {
        prizeWallet = _prizeWallet;
        cbcContract = IERC20(_cbcContractAddress);
        apeContract = IERC20(_apeContractAddress);
        signingKey = _signingKey;
        isPaused = false;
    }

    /**
    @notice create new offer with a set of nfts
    @param _prize how much will be claimed
    @param _rewardType reward type for cbc or ape
    @param _backendNonce nonce of this payment
    @param _expirationTime the time we should no longer accept this signature
    @param _signature signature for ECDASA verification
   */
    function askPrize(
        uint256 _prize,
        uint256 _rewardType,
        uint256 _backendNonce,
        uint256 _expirationTime,
        bytes memory _signature
    ) external whenNotPaused {
        require(
            _msgSender() != address(0),
            "PrizeDistribution.askPrize: sender address is ZERO"
        );

        require(!nonceToValidated[_backendNonce], "PrizeDistribution.askPrize: this nonce was already used");
        uint currentTime = _getNow();

        require( _expirationTime >= currentTime, "This transaction signature is expired");

        // validate the transaction with the backend
        address recovered = ECDSA.recover(keccak256(abi.encodePacked(_prize, _rewardType, _backendNonce, _expirationTime, msg.sender)), _signature);
        require(recovered == signingKey, "PrizeDistribution.askPrize: Verification Failed");

        // mark nonce used
        nonceToValidated[_backendNonce] = true;

        _makeTransfer(msg.sender,  _prize, _rewardType);

        emit PrizeSent(
            msg.sender,
            _prize,
            _rewardType,
            currentTime
        );
    }

    function _makeTransfer(
        address buyer,
        uint256 price,
        uint256 rewardType
    ) internal {
        // Work out platform fee from above reserve amount
        if (rewardType == 0) {
            bool platformTransferSuccess = cbcContract.transferFrom(
                prizeWallet,
                buyer,
                price
            );

            require(
                platformTransferSuccess,
                "BaboonsPrize: Failed to send platform fee in CBC"
            );
        } else {
            bool platformTransferSuccess = apeContract.transferFrom(
                prizeWallet,
                buyer,
                price
            );

            require(
                platformTransferSuccess,
                "BaboonsPrize: Failed to send platform fee in CBC"
            );
        }
    }

    /**
    @notice Method for updating prize source address
    @dev Only admin
    @param _prizeWallet payable address the address to sends the funds to
    */
    function updatePrizeWallet(address payable _prizeWallet)
        external
        onlyOwner
    {
        require(
            _prizeWallet != address(0),
            "BaboonsPrize.updatePrizeWallet: Zero address"
        );

        prizeWallet = _prizeWallet;
    }

    /**
       @notice Method for toggling isPaused
       @dev Only Admin
       @param _isPaused bool to set internal variable to
    **/
    function setIsPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }
   
    /**
     * @notice set signing key for ECDSA verification
     * @param _key signing key
     */
    function setSigningKey(address _key) external onlyOwner {
      signingKey = _key;
    }

    /**
     * @notice set contract address
     * @param _contractAddress contract address
     */
    function setContractAddress(address _contractAddress) external onlyOwner {
        cbcContract = IERC20(_contractAddress);
    }

    /////////////////////////
    // Internal and Private /
    /////////////////////////

    function _getNow() internal view virtual returns (uint) {
        return block.timestamp;
    }
}