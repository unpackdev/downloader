// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./ONFT721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

/**
* @author Zerius
* @title ZeriusONFT721
*/
contract ZeriusONFT721 is ONFT721, ERC721Enumerable {

    /************
    *   ERRORS  *
    ************/

    /**
    * @notice Contract error codes, used to specify the error
    * CODE LIST:
    * E1    "Invalid token URI lock state"
    * E2    "Mint exceeds the limit"
    * E3    "Invalid mint fee"
    * E4    "Invalid token ID"
    * E5    "Invalid fee collector address"
    * E6    "Invalid earned fee amount: nothing to claim"
    * E7    "Caller is not a fee collector"
    * E8    "Invalid referral bips: value is too high"
    * E9    "Invalid referer address"
    */
    uint8 public constant ERROR_INVALID_URI_LOCK_STATE = 1;
    uint8 public constant ERROR_MINT_EXCEEDS_LIMIT = 2;
    uint8 public constant ERROR_MINT_INVALID_FEE = 3;
    uint8 public constant ERROR_INVALID_TOKEN_ID = 4;
    uint8 public constant ERROR_INVALID_COLLECTOR_ADDRESS = 5;
    uint8 public constant ERROR_NOTHING_TO_CLAIM = 6;
    uint8 public constant ERROR_NOT_FEE_COLLECTOR = 7;
    uint8 public constant ERROR_REFERRAL_BIPS_TOO_HIGH = 8;
    uint8 public constant ERROR_INVALID_REFERER = 9;

    /**
    * @notice Basic error, thrown every time something goes wrong according to the contract logic.
    * @dev The error code indicates more details.
    */
    error ZeriusONFT721_CoreError(uint256 errorCode);

    /************
    *   EVENTS  *
    ************/

    /**
    * State change
    */
    event MintFeeChanged(uint256 indexed oldMintFee, uint256 indexed newMintFee);
    event BridgeFeeChanged(uint256 indexed oldBridgeFee, uint256 indexed newBridgeFee);
    event ReferralEarningBipsChanged(uint256 indexed oldReferralEarningBips, uint256 indexed newReferralEarningBips);
    event EarningBipsForReferrerChanged(address indexed referrer, uint256 newEraningBips);
    event EarningBipsForReferrersChanged(address[] indexed referrers, uint256 newEraningBips);
    event FeeCollectorChanged(address indexed oldFeeCollector, address indexed newFeeCollector);
    event TokenURIChanged(string indexed oldTokenURI, string indexed newTokenURI, string fileExtension);
    event TokenURILocked(bool indexed newState);

    /**
    * Mint / bridge / claim
    */
    event ONFTMinted(
        address indexed minter,
        uint256 indexed itemId,
        uint256 feeEarnings,
        address indexed referrer,
        uint256 referrerEarnings
    );

    event BridgeFeeEarned(
        address indexed from,
        uint16 indexed dstChainId,
        uint256 amount
    );

    event FeeEarningsClaimed(address indexed collector, uint256 claimedAmount);
    event ReferrerEarningsClaimed(address indexed referrer, uint256 claimedAmount);

    /***************
    *   CONSTANTS  *
    ***************/
    uint256 public constant ONE_HUNDRED_PERCENT = 10000; // 100%
    uint256 public constant FIFTY_PERCENT = 5000; // 50%
    uint256 public constant DENOMINATOR = ONE_HUNDRED_PERCENT; // 100%

    /***********************
    *   VARIABLES / STATES *
    ***********************/

    /// TOKEN ID ///
    uint256 public immutable startMintId;
    uint256 public immutable maxMintId;

    uint256 public tokenCounter;

    /// FEE ///
    uint256 public mintFee;
    uint256 public bridgeFee;
    address public feeCollector;

    uint256 public feeEarnedAmount;
    uint256 public feeClaimedAmount;

    /// REFERRAL FEE ///
    uint256 public referralEarningBips;
    mapping (address => uint256) public referrersEarningBips;
    mapping (address => uint256) public referredTransactionsCount;
    mapping (address => uint256) public referrersEarnedAmount;
    mapping (address => uint256) public referrersClaimedAmount;

    /// TOKEN URI ///
    string private _tokenURIExtension;
    string private _tokenBaseURI;
    bool public tokenBaseURILocked;

    /***************
    *   MODIFIERS  *
    ***************/

    /**
    * @dev Protects functions available only to the fee collector, e.g. fee claiming
    */
    modifier onlyFeeCollector() {
        _checkFeeCollector();
        _;
    }

    /*****************
    *   CONSTRUCTOR  *
    *****************/

    /**
    * @param _minGasToTransfer min amount of gas required to transfer, and also store the payload. See {ONFT721Core}
    * @param _lzEndpoint LayerZero endpoint address
    * @param _startMintId min token ID that can be mined
    * @param _endMintId max token ID that can be mined
    * @param _mintFee fee amount to be sent as message value when calling the mint function
    * @param _bridgeFee fee amount to be sent as part of the value message when calling the mint function
    * @param _feeCollector the address to which the fee claiming is authorized
    */
    constructor(
        uint256 _minGasToTransfer,
        address _lzEndpoint,
        uint256 _startMintId,
        uint256 _endMintId,
        uint256 _mintFee,
        uint256 _bridgeFee,
        address _feeCollector,
        uint256 _referralEarningBips
    ) ONFT721("ZeriusONFT Minis", "ZRSM", _minGasToTransfer, _lzEndpoint) {
        require(_startMintId < _endMintId, "Invalid mint range");
        require(_endMintId < type(uint256).max, "Incorrect max mint ID");
        require(_feeCollector != address(0), "Invalid fee collector address");
        require(_referralEarningBips <= FIFTY_PERCENT, "Invalid referral earning shares");

        startMintId = _startMintId;
        maxMintId = _endMintId;
        mintFee = _mintFee;
        bridgeFee = _bridgeFee;
        feeCollector = _feeCollector;
        referralEarningBips = _referralEarningBips;
        tokenCounter = _startMintId;
    }

    /***********************
    *   SETTERS / GETTERS  *
    ***********************/

    /**
    * @notice ADMIN Change minting fee
    * @param _mintFee new minting fee
    *
    * @dev emits {ZeriusONFT721-MintFeeChanged}
    */
    function setMintFee(uint256 _mintFee) external onlyOwner {
        uint256 oldMintFee = mintFee;
        mintFee = _mintFee;
        emit MintFeeChanged(oldMintFee, _mintFee);
    }

    /**
    * @notice ADMIN Change bridge fee
    * @param _bridgeFee new bridge fee
    *
    * @dev emits {ZeriusONFT721-BridgeFeeChanged}
    */
    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        uint256 oldBridgeFee = bridgeFee;
        bridgeFee = _bridgeFee;
        emit BridgeFeeChanged(oldBridgeFee, _bridgeFee);
    }

    /**
    * @notice ADMIN Change referral earning share
    * @param _referralEarninBips new referral earning share
    *
    * @dev emits {ZeriusONFT721-ReferralEarningBipsChanged}
    */
    function setReferralEarningBips(uint256 _referralEarninBips) external onlyOwner {
        _validate(_referralEarninBips <= FIFTY_PERCENT, ERROR_REFERRAL_BIPS_TOO_HIGH);
        uint256 oldReferralEarningsShareBips = referralEarningBips;
        referralEarningBips = _referralEarninBips;
        emit ReferralEarningBipsChanged(oldReferralEarningsShareBips, _referralEarninBips);
    }

    /**
    * @notice ADMIN Change referral earning share for specific referrer
    * @param referrer address for which a special share is set
    * @param earningBips new referral earning share for referrer
    *
    * @dev emits {ZeriusONFT721-EarningBipsForReferrerChanged}
    */
    function setEarningBipsForReferrer(
        address referrer,
        uint256 earningBips
    ) external onlyOwner {
        _validate(earningBips <= ONE_HUNDRED_PERCENT, ERROR_REFERRAL_BIPS_TOO_HIGH);
        referrersEarningBips[referrer] = earningBips;
        emit EarningBipsForReferrerChanged(referrer, earningBips);
    }

    /**
    * @notice ADMIN Change referral earning share for specific referrers
    * @param referrers addresses for which a special share is set
    * @param earningBips new referral earning share for referrers
    *
    * @dev emits {ZeriusONFT721-EarningBipsForReferrersChanged}
    */
    function setEarningBipsForReferrersBatch(
        address[] calldata referrers,
        uint256 earningBips
    ) external onlyOwner {
        _validate(earningBips <= ONE_HUNDRED_PERCENT, ERROR_REFERRAL_BIPS_TOO_HIGH);
        for (uint256 i; i < referrers.length; i++) {
            referrersEarningBips[referrers[i]] = earningBips;
        }
        emit EarningBipsForReferrersChanged(referrers, earningBips);
    }

    /**
    * @notice ADMIN Change fee collector address
    * @param _feeCollector new address for the collector
    *
    * @dev emits {ZeriusONFT721-FeeCollectorChanged}
    */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        _validate(_feeCollector != address(0), ERROR_INVALID_COLLECTOR_ADDRESS);
        address oldFeeCollector = feeCollector;
        feeCollector = _feeCollector;
        emit FeeCollectorChanged(oldFeeCollector, _feeCollector);
    }

    /**
    * @notice ADMIN Change base URI
    * @param _newTokenBaseURI new URI
    * @param _fileExtension file extension in format ".<ext>"
    *
    * @dev emits {ZeriusONFT721-TokenURIChanged}
    */
    function setTokenBaseURI(
        string calldata _newTokenBaseURI,
        string calldata _fileExtension
    ) external onlyOwner {
        _validate(!tokenBaseURILocked, ERROR_INVALID_URI_LOCK_STATE);
        string memory oldTokenBaseURI = _tokenBaseURI;
        _tokenBaseURI = _newTokenBaseURI;
        _tokenURIExtension = _fileExtension;
        emit TokenURIChanged(oldTokenBaseURI, _newTokenBaseURI, _fileExtension);
    }

    /**
    * @notice ADMIN Lock / unlock base URI
    * @param locked lock token URI if true, unlock otherwise
    *
    * @dev emits {ZeriusONFT721-TokenURILocked}
    */
    function setTokenBaseURILocked(bool locked) external onlyOwner {
        _validate(tokenBaseURILocked != locked, ERROR_INVALID_URI_LOCK_STATE);
        tokenBaseURILocked = locked;
        emit TokenURILocked(locked);
    }

    /**
    * @notice Retrieving token URI by its ID
    * @param tokenId identifier of the token
    *
    * @dev emits {ZeriusONFT721-TokenURILocked}
    */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _validate(_exists(tokenId), ERROR_INVALID_TOKEN_ID);
        return string(abi.encodePacked(_tokenBaseURI, Strings.toString(tokenId), _tokenURIExtension));
    }

    /************
    *   MINT    *
    ************/

    /**
    * @notice Mint new Zerius ONFT
    *
    * @dev new token ID must be in range [startMintId - maxMintId]
    * @dev tx value must be equal to mintFee. See {ZeriusONFT721-mintFee}
    * @dev emits {ZeriusONFT721-ONFTMinted}
    */
    function mint() external payable nonReentrant {
        uint256 newItemId = tokenCounter;
        uint256 feeEarnings = mintFee;

        _validate(newItemId < maxMintId, ERROR_MINT_EXCEEDS_LIMIT);
        _validate(msg.value >= feeEarnings, ERROR_MINT_INVALID_FEE);

        ++tokenCounter;

        feeEarnedAmount += feeEarnings;

        _safeMint(_msgSender(), newItemId);
        emit ONFTMinted(
            _msgSender(),
            newItemId,
            feeEarnings,
            address(0),
            0
        );
    }

    /**
    * @notice Mint new Zerius ONFT by referral
    * @param referrer referral address
    *
    * @dev new token ID must be in range [startMintId - maxMintId]
    * @dev tx value must be equal to mintFee. See {ZeriusONFT721-mintFee}
    * @dev referrer address must be non-zero
    * @dev emits {ZeriusONFT721-ONFTMinted}
    */
    function mint(address referrer) public payable nonReentrant {
        uint256 newItemId = tokenCounter;
        uint256 _mintFee = mintFee;

        _validate(newItemId < maxMintId, ERROR_MINT_EXCEEDS_LIMIT);
        _validate(msg.value >= _mintFee, ERROR_MINT_INVALID_FEE);
        _validate(referrer != _msgSender() && referrer != address(0), ERROR_INVALID_REFERER);

        ++tokenCounter;

        uint256 referrerBips = referrersEarningBips[referrer];
        uint256 referrerShareBips = referrerBips == 0
            ? referralEarningBips
            : referrerBips;
        uint256 referrerEarnings = (_mintFee * referrerShareBips) / DENOMINATOR;
        uint256 feeEarnings = _mintFee - referrerEarnings;

        referrersEarnedAmount[referrer] += referrerEarnings;
        ++referredTransactionsCount[referrer];

        feeEarnedAmount += feeEarnings;

        _safeMint(_msgSender(), newItemId);
        emit ONFTMinted(
            _msgSender(),
            newItemId,
            feeEarnings,
            referrer,
            referrerEarnings
        );
    }

    /**************
    *   BRIDGE    *
    **************/

    /**
    * @notice Estimate fee to send token to another chain
    * @param _dstChainId destination LayerZero chain ID
    * @param _toAddress address on destination
    * @param _tokenId token to be sent
    * @param _useZro flag to use ZRO as fee
    * @param _adapterParams relayer adapter parameters
    *
    * @dev See {ONFT721Core-estimateSendFee}
    * @dev Overridden to add bridgeFee to native fee
    */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override(ONFT721Core, IONFT721Core) returns (uint nativeFee, uint zroFee) {
        return this.estimateSendBatchFee(
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _useZro,
            _adapterParams
        );
    }

    /**
    * @notice Estimate fee to send batch of tokens to another chain
    * @param _dstChainId destination LayerZero chain ID
    * @param _toAddress address on destination
    * @param _tokenIds tokens to be sent
    * @param _useZro flag to use ZRO as fee
    * @param _adapterParams relayer adapter parameters
    *
    * @dev See {ONFT721Core-estimateSendBatchFee}
    * @dev Overridden to add bridgeFee to native fee
    */
    function estimateSendBatchFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        bool _useZro,
        bytes memory _adapterParams
    ) public view override(ONFT721Core, IONFT721Core) returns (uint256 nativeFee, uint256 zroFee) {
        (nativeFee, zroFee) = super.estimateSendBatchFee(
            _dstChainId,
            _toAddress,
            _tokenIds,
            _useZro,
            _adapterParams
        );
        nativeFee += bridgeFee;
        return (nativeFee, zroFee);
    }

    /**
    * @notice Send token to another chain
    * @param _from sender address, token owner or approved address
    * @param _dstChainId destination LayerZero chain ID
    * @param _toAddress address on destination
    * @param _tokenId token to be sent
    * @param _refundAddress address that would receive remaining funds
    * @param _zroPaymentAddress address that would pay fees in zro
    * @param _adapterParams relayer adapter parameters
    *
    * @dev See {ONFT721Core-sendFrom}
    * @dev Overridden to collect bridgeFee
    */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable override(ONFT721Core, IONFT721Core) {
        _handleSend(
            _from,
            _dstChainId,
            _toAddress,
            _toSingletonArray(_tokenId),
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
    * @notice Send token to another chain
    * @param _from sender address, token owner or approved address
    * @param _dstChainId destination LayerZero chain ID
    * @param _toAddress address on destination
    * @param _tokenIds tokens to be sent
    * @param _refundAddress address that would receive remaining funds
    * @param _zroPaymentAddress address that would pay fees in zro
    * @param _adapterParams relayer adapter parameters
    *
    * @dev See {ONFT721Core-sendBatchFrom}
    * @dev Overridden to collect bridgeFee
    */
    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override(ONFT721Core, IONFT721Core) {
        _handleSend(
            _from,
            _dstChainId,
            _toAddress,
            _tokenIds,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    /**
    * @notice Internal function to handle send to another chain
    * @param _from sender address, token owner or approved address
    * @param _dstChainId destination LayerZero chain ID
    * @param _toAddress address on destination
    * @param _tokenIds tokens to be sent
    * @param _refundAddress address that would receive remaining funds
    * @param _zroPaymentAddress address that would pay fees in zro
    * @param _adapterParams relayer adapter parameters
    *
    * @dev emits {ZeriusONFT721-BridgeFeeEarned}
    */
    function _handleSend(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) private {
        uint256 _bridgeFee = bridgeFee;
        uint256 _nativeFee = msg.value - _bridgeFee;

        feeEarnedAmount += _bridgeFee;

        _send(
            _from,
            _dstChainId,
            _toAddress,
            _tokenIds,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams,
            _nativeFee
        );

        emit BridgeFeeEarned(_from, _dstChainId, _bridgeFee);
    }

    /**
    * @notice Internal function to handle send to another chain
    * @param _from sender address, token owner or approved address
    * @param _dstChainId destination LayerZero chain ID
    * @param _toAddress address on destination
    * @param _tokenIds tokens to be sent
    * @param _refundAddress address that would receive remaining funds
    * @param _zroPaymentAddress address that would pay fees in zro
    * @param _adapterParams relayer adapter parameters
    * @param _nativeFee fee amount to be sent to LayerZero (without bridgeFee)
    *
    * @dev Mimics the behavior of {ONFT721Core}
    * @dev emits {IONFT721Core-SendToChain}
    */
    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint256 _nativeFee
    ) internal virtual {
        // allow 1 by default
        require(_tokenIds.length > 0, "tokenIds[] is empty");
        require(
            _tokenIds.length == 1 ||
                _tokenIds.length <= dstChainIdToBatchLimit[_dstChainId],
            "batch size exceeds dst batch limit"
        );

        for (uint i = 0; i < _tokenIds.length; i++) {
            _debitFrom(_from, _dstChainId, _toAddress, _tokenIds[i]);
        }

        bytes memory payload = abi.encode(_toAddress, _tokenIds);

        _checkGasLimit(
            _dstChainId,
            FUNCTION_TYPE_SEND,
            _adapterParams,
            dstChainIdToTransferGas[_dstChainId] * _tokenIds.length
        );
        _lzSend(
            _dstChainId,
            payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams,
            _nativeFee
        );
        emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds);
    }

    /*************
    *   CLAIM    *
    *************/

    /**
    * @notice FEE_COLLECTOR Claim earned fee (mint + bridge)
    *
    * @dev earned amount must be more than zero to claim
    * @dev emits {ZeriusONFT721-FeeEarningsClaimed}
    */
    function claimFeeEarnings() external onlyFeeCollector nonReentrant {
        uint256 _feeEarnedAmount = feeEarnedAmount;
        _validate(_feeEarnedAmount != 0, ERROR_NOTHING_TO_CLAIM);

        uint256 currentEarnings = _feeEarnedAmount;
        feeEarnedAmount = 0;
        feeClaimedAmount += currentEarnings;

        address _feeCollector = feeCollector;
        (bool success, ) = payable(_feeCollector).call{value: currentEarnings}("");
        require(success, "Failed to send Ether");
        emit FeeEarningsClaimed(_feeCollector, currentEarnings);
    }

    /**
    * @notice Claim earned fee from referral mint
    *
    * @dev earned amount must be more than zero to claim
    * @dev emits {ZeriusONFT721-ReferrerEarningsClaimed}
    */
    function claimReferrerEarnings() external {
        uint256 earnings = referrersEarnedAmount[_msgSender()];
        _validate(earnings != 0, ERROR_NOTHING_TO_CLAIM);

        referrersEarnedAmount[_msgSender()] = 0;
        referrersClaimedAmount[_msgSender()] += earnings;

        (bool sent, ) = payable(_msgSender()).call{value: earnings}("");
        require(sent, "Failed to send Ether");

        emit ReferrerEarningsClaimed(_msgSender(), earnings);
    }

    /*****************
    *   OVERRIDES    *
    *****************/

    /**
    * @dev See {ERC721-_beforeTokenTransfer}
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    /**
    * @dev See {ERC721-supportsInterface}
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ONFT721) returns (bool) {
        return interfaceId == type(IONFT721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /***************
    *   HELPERS    *
    ***************/

    /**
    * @notice Checks if address is current fee collector
    */
    function _checkFeeCollector() internal view {
        _validate(feeCollector == _msgSender(), ERROR_NOT_FEE_COLLECTOR);
    }

    /**
    * @notice Checks if the condition is met and reverts with an error if not
    * @param _clause condition to be checked
    * @param _errorCode code that will be passed in the error
    */
    function _validate(bool _clause, uint8 _errorCode) internal pure {
        if (!_clause) revert ZeriusONFT721_CoreError(_errorCode);
    }
}
