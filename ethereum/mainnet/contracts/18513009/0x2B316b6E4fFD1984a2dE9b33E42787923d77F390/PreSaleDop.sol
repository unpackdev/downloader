// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./MessageHashUtils.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./Rounds.sol";
import "./IPreSaleDop.sol";

import "./Common.sol";

/// @title PreSaleDop contract
/// @notice Implements the preSale of Dop Token
/// @dev The presale contract allows you to purchase dop token with allowed tokens,
/// and there will be certain rounds.
/// @dev The recorded DOP tokens and NFT claims will be distributed later using another distributor contract.

contract PreSaleDop is IPreSaleDop, Rounds, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Thrown when address is blacklisted
    error Blacklisted();

    /// @notice Thrown when buy is disabled
    error BuyNotEnable();

    /// @notice Thrown when sign deadline is expired
    error DeadlineExpired();

    /// @notice Thrown when Sign is invalid
    error InvalidSignature();

    /// @notice Thrown when Eth price suddenly drops while purchasing with ETH
    error UnexpectedPriceDifference();

    /// @notice Thrown when value to transfer is zero
    error ZeroValue();

    /// @notice Thrown when price from pricefeed is zero
    error PriceNotFound();

    /// @notice Thrown when caller is not claimsContract
    error OnlyClaims();

    /// @notice Thrown when investment is less than nft prices combined
    error InvalidInvestment();

    /// @notice Thrown when both pricefeed and reference price are non zero
    error CodeSyncIssue();

    /// @notice That buyEnable or not
    bool public buyEnable = true;

    /// @notice The address of signerWallet
    address public signerWallet;

    /// @notice The address of claimsContract
    address public claimsContract;

    /// @notice The address of fundsWallet
    address public fundsWallet;

    /// @notice The array of prices of each nft
    uint256[] public nftPricing;

    /// @notice Gives claim info of user in every round
    mapping(address => mapping(uint32 => uint256)) public claims;

    /// @notice Gives info about address's permission
    mapping(address => bool) public blacklistAddress;

    /// @notice Gives claim info of user nft in every round
    mapping(address => mapping(uint32 => ClaimNFT[])) public claimNFT;

    /// @member nftAmounts The nft amounts
    /// @member roundPrice The round number
    struct ClaimNFT {
        uint256[] nftAmounts;
        uint256 roundPrice;
    }

    /// @member price The price of token from priceFeed
    /// @member normalizationFactorForToken The normalization factor to achieve return value of 18 decimals ,while calculating dop token purchases and always with different token decimals
    /// @member normalizationFactorForNFT The normalization factor is the value which helps us to convert decimals of USDT to investment token decimals and always with different token decimals
    struct TokenInfo {
        uint256 latestPrice;
        uint8 normalizationFactorForToken;
        uint8 normalizationFactorForNFT;
    }

    /// @dev Emitted when dop is purchased with ETH
    event InvestedWithETH(
        address indexed by,
        string code,
        uint256 amountInvestedEth,
        uint32 indexed round,
        uint256 indexed roundPrice,
        uint256 dopPurchased
    );

    /// @dev Emitted when dop is purchased with Token
    event InvestedWithToken(
        IERC20 indexed token,
        uint256 tokenPrice,
        address indexed by,
        string code,
        uint256 amountInvested,
        uint256 dopPurchased,
        uint32 indexed round
    );

    /// @dev Emitted when dop NFT is purchased with ETH
    event InvestedWithETHForNFT(
        address indexed by,
        string code,
        uint256 amountInEth,
        uint256 ethPrice,
        uint32 indexed round,
        uint256 roundPrice,
        uint256[] nftAmounts
    );

    /// @dev Emitted when dop NFT is purchased with token
    event InvestedWithTokenForNFT(
        IERC20 indexed token,
        uint256 tokenPrice,
        address indexed by,
        string code,
        uint256 amountInvested,
        uint32 indexed round,
        uint256 roundPrice,
        uint256[] nftAmounts
    );

    /// @dev Emitted when dop is purchased claim amount
    event InvestedWithClaimAmount(
        address indexed by,
        uint256 amount,
        IERC20 token,
        uint32 indexed round,
        uint256 indexed tokenPrice,
        uint256 dopPurchased
    );

    /// @dev Emitted when address of signer is updated
    event SignerUpdated(address oldSigner, address newSigner);

    /// @dev Emitted when address of funds wallet is updated
    event FundsWalletUpdated(address oldAddress, address newAddress);

    /// @dev Emitted when blacklist access of address is updated
    event BlacklistUpdated(address which, bool accessNow);

    /// @dev Emitted when buying access changes
    event BuyEnableUpdated(bool oldAccess, bool newAccess);

    /// @dev Emitted when dop NFT prices are updated
    event PricingUpdated(uint256 oldPrice, uint256 newPrice);

    /// @notice Restricts when updating wallet/contract address to zero address
    modifier checkAddressZero(address which) {
        if (which == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice Ensures that buy is enabled when buying
    modifier canBuy() {
        if (!buyEnable) {
            revert BuyNotEnable();
        }
        _;
    }

    /// @dev Constructor.
    /// @param fundsWalletAddress The address of funds wallet
    /// @param signerAddress The address of signer wallet
    /// @param claimsContractAddress The address of claim contract
    /// @param lastRound The last round created
    /// @param nftPrices The prices of the dop NFTs
    constructor(
        address fundsWalletAddress,
        address signerAddress,
        address claimsContractAddress,
        address owner,
        uint32 lastRound,
        uint256[] memory nftPrices
    ) Rounds(lastRound) Ownable(owner) {
        if (
            fundsWalletAddress == address(0) ||
            signerAddress == address(0) ||
            claimsContractAddress == address(0) ||
            owner == address(0)
        ) {
            revert ZeroAddress();
        }
        fundsWallet = fundsWalletAddress;
        signerWallet = signerAddress;
        claimsContract = claimsContractAddress;
        if (nftPrices.length == 0) {
            revert ZeroLengthArray();
        }
        for (uint256 i = 0; i < nftPrices.length; ++i) {
            _checkValue(nftPrices[i]);
        }
        nftPricing = nftPrices;
    }

    /// @notice Changes access of buying
    /// @param enabled The decision about buying
    function enableBuy(bool enabled) external onlyOwner {
        if (buyEnable == enabled) {
            revert IdenticalValue();
        }
        emit BuyEnableUpdated({oldAccess: buyEnable, newAccess: enabled});
        buyEnable = enabled;
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function changeSigner(
        address newSigner
    ) external checkAddressZero(newSigner) onlyOwner {
        address oldSigner = signerWallet;
        if (oldSigner == newSigner) {
            revert IdenticalValue();
        }
        emit SignerUpdated({oldSigner: oldSigner, newSigner: newSigner});
        signerWallet = newSigner;
    }

    /// @notice Changes funds wallet to a new address
    /// @param newFundsWallet The address of the new funds wallet
    function changeFundsWallet(
        address newFundsWallet
    ) external checkAddressZero(newFundsWallet) onlyOwner {
        address oldWallet = fundsWallet;
        if (oldWallet == newFundsWallet) {
            revert IdenticalValue();
        }
        emit FundsWalletUpdated({
            oldAddress: oldWallet,
            newAddress: newFundsWallet
        });
        fundsWallet = newFundsWallet;
    }

    /// @notice Changes the access of any address in contract interaction
    /// @param which The address for which access is updated
    /// @param access The access decision of `which` address
    function updateBlackListedUser(
        address which,
        bool access
    ) external checkAddressZero(which) onlyOwner {
        bool oldAccess = blacklistAddress[which];
        if (oldAccess == access) {
            revert IdenticalValue();
        }
        emit BlacklistUpdated({which: which, accessNow: access});
        blacklistAddress[which] = access;
    }

    /// @notice Purchases dopToken with Eth
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param deadline The deadline is validity of the signature
    /// @param minAmountDop The minAmountDop user agrees to purchase
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseTokenWithEth(
        string memory code,
        uint32 round,
        uint256 deadline,
        uint256 minAmountDop,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable canBuy {
        // The input must have been signed by the presale signer
        _validatePurchaseWithEth(msg.value, round, deadline, code, v, r, s);
        uint256 roundPrice = _getRoundPriceForToken(round, ETH);
        TokenInfo memory tokenInfo = getLatestPrice(ETH);
        if (tokenInfo.latestPrice == 0) {
            revert PriceNotFound();
        }
        uint256 toReturn = _calculateDop(
            msg.value,
            tokenInfo.latestPrice,
            tokenInfo.normalizationFactorForToken,
            roundPrice
        );
        if (toReturn < minAmountDop) {
            revert UnexpectedPriceDifference();
        }
        claims[msg.sender][round] += toReturn;
        payable(fundsWallet).sendValue(msg.value);
        emit InvestedWithETH({
            by: msg.sender,
            code: code,
            amountInvestedEth: msg.value,
            round: round,
            roundPrice: roundPrice,
            dopPurchased: toReturn
        });
    }

    /// @notice Purchases dopToken with any token
    /// @param token The address of investment token
    /// @param referenceNormalizationFactor The normalization factor
    /// @param referenceTokenPrice The current price of token in 10 decimals
    /// @param investment The Investment amount
    /// @param minAmountDop The minAmountDop user agrees to purchase
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseTokenWithToken(
        IERC20 token,
        uint8 referenceNormalizationFactor,
        uint256 referenceTokenPrice,
        uint256 investment,
        uint256 minAmountDop,
        string memory code,
        uint32 round,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external canBuy nonReentrant {
        // The input must have been signed by the presale signer
        _validatePurchaseWithToken(
            token,
            round,
            deadline,
            code,
            referenceTokenPrice,
            referenceNormalizationFactor,
            v,
            r,
            s
        );
        _checkValue(investment);

        uint256 roundPrice = _getRoundPriceForToken(round, token);

        (uint256 latestPrice, uint256 normalizationFactor) = _validatePrice(
            token,
            referenceTokenPrice,
            referenceNormalizationFactor
        );

        uint256 toReturn = _calculateDop(
            investment,
            latestPrice,
            normalizationFactor,
            roundPrice
        );
        if (toReturn < minAmountDop) {
            revert UnexpectedPriceDifference();
        }
        claims[msg.sender][round] += toReturn;

        token.safeTransferFrom(msg.sender, fundsWallet, investment);
        emit InvestedWithToken({
            token: token,
            tokenPrice: latestPrice,
            by: msg.sender,
            code: code,
            amountInvested: investment,
            dopPurchased: toReturn,
            round: round
        });
    }

    /// @notice Purchases NFT with Eth
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param nftAmounts The nftAmounts is array of nfts selected
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseNFTWithEth(
        string memory code,
        uint32 round,
        uint256[] calldata nftAmounts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable canBuy nonReentrant {
        uint256[] memory nftPrices = nftPricing;
        _validateArrays(nftAmounts.length, nftPrices.length);
        // The input must have been signed by the presale signer
        _validatePurchaseWithEth(msg.value, round, deadline, code, v, r, s);

        TokenInfo memory tokenInfo = getLatestPrice(ETH);
        if (tokenInfo.latestPrice == 0) {
            revert PriceNotFound();
        }
        (uint256 value, uint256 roundPrice) = _processPurchaseNFT(
            ETH,
            tokenInfo.latestPrice,
            tokenInfo.normalizationFactorForNFT,
            round,
            nftAmounts,
            nftPrices
        );
        if (msg.value < value) {
            revert InvalidInvestment();
        }
        _checkValue(value);
        uint256 amountUnused = msg.value - value;
        if (amountUnused > 0) {
            payable(msg.sender).sendValue(amountUnused);
        }
        payable(fundsWallet).sendValue(value);
        emit InvestedWithETHForNFT({
            by: msg.sender,
            code: code,
            amountInEth: value,
            ethPrice: tokenInfo.latestPrice,
            round: round,
            roundPrice: roundPrice,
            nftAmounts: nftAmounts
        });
    }

    /// @notice Purchases NFT with token
    /// @param token The address of investment token
    /// @param referenceTokenPrice The current price of token in 10 decimals
    /// @param referenceNormalizationFactor The normalization factor
    /// @param code The code is used to verify signature of the user
    /// @param round The round in which user wants to purchase
    /// @param nftAmounts The nftAmounts is array of nfts selected
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseNFTWithToken(
        IERC20 token,
        uint256 referenceTokenPrice,
        uint8 referenceNormalizationFactor,
        string memory code,
        uint32 round,
        uint256[] calldata nftAmounts,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external canBuy nonReentrant {
        uint256[] memory nftPrices = nftPricing;
        _validateArrays(nftAmounts.length, nftPrices.length);
        // The input must have been signed by the presale signer
        _validatePurchaseWithToken(
            token,
            round,
            deadline,
            code,
            referenceTokenPrice,
            referenceNormalizationFactor,
            v,
            r,
            s
        );
        TokenInfo memory tokenInfo = getLatestPrice(token);
        if (tokenInfo.latestPrice != 0) {
            if (referenceTokenPrice != 0 || referenceNormalizationFactor != 0) {
                revert CodeSyncIssue();
            }
        }
        //  If price feed isn't available,we fallback to the reference price
        if (tokenInfo.latestPrice == 0) {
            if (referenceTokenPrice == 0 || referenceNormalizationFactor == 0) {
                revert ZeroValue();
            }
            tokenInfo.latestPrice = referenceTokenPrice;
            tokenInfo.normalizationFactorForNFT = referenceNormalizationFactor;
        }

        (uint256 value, uint256 roundPrice) = _processPurchaseNFT(
            token,
            tokenInfo.latestPrice,
            tokenInfo.normalizationFactorForNFT,
            round,
            nftAmounts,
            nftPrices
        );
        _checkValue(value);

        token.safeTransferFrom(msg.sender, fundsWallet, value);
        emit InvestedWithTokenForNFT({
            token: token,
            tokenPrice: tokenInfo.latestPrice,
            by: msg.sender,
            code: code,
            amountInvested: value,
            round: round,
            roundPrice: roundPrice,
            nftAmounts: nftAmounts
        });
    }

    /// @inheritdoc IPreSaleDop
    function purchaseWithClaim(
        IERC20 token,
        uint256 referenceTokenPrice,
        uint8 referenceNormalizationFactor,
        uint256 amount,
        uint256 minAmountDop,
        address recipient,
        uint32 round
    ) external payable canBuy nonReentrant {
        if (msg.sender != claimsContract) {
            revert OnlyClaims();
        }
        _checkBlacklist(recipient);
        if (!allowedTokens[round][token].access) {
            revert TokenDisallowed();
        }
        uint256 roundPrice = _getRoundPriceForToken(round, token);
        (uint256 latestPrice, uint256 normalizationFactor) = _validatePrice(
            token,
            referenceTokenPrice,
            referenceNormalizationFactor
        );

        uint256 toReturn = _calculateDop(
            amount,
            latestPrice,
            normalizationFactor,
            roundPrice
        );
        if (toReturn < minAmountDop) {
            revert UnexpectedPriceDifference();
        }
        claims[recipient][round] += toReturn;
        if (token == ETH) {
            payable(fundsWallet).sendValue(msg.value);
        } else {
            token.safeTransferFrom(claimsContract, fundsWallet, amount);
        }
        emit InvestedWithClaimAmount({
            by: recipient,
            amount: amount,
            token: token,
            round: round,
            tokenPrice: latestPrice,
            dopPurchased: toReturn
        });
    }

    /// @notice Changes the access of any address in contract interaction
    /// @param newPrices The new prices of NFTs
    function updatePricing(uint256[] memory newPrices) external onlyOwner {
        uint256[] memory oldPrices = nftPricing;
        if (newPrices.length != oldPrices.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i = 0; i < newPrices.length; ++i) {
            uint256 newPrice = newPrices[i];
            _checkValue(newPrice);
            emit PricingUpdated({oldPrice: oldPrices[i], newPrice: newPrice});
        }
        nftPricing = newPrices;
    }

    /// @inheritdoc IPreSaleDop
    function verifyPurchaseWithClaim(
        address recipient,
        uint32 round,
        uint256 deadline,
        uint256[] calldata tokenPrices,
        uint8[] calldata normalizationFactors,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view {
        if (msg.sender != claimsContract) {
            revert OnlyClaims();
        }
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(
                recipient,
                round,
                tokenPrices,
                normalizationFactors,
                deadline,
                tokens,
                amounts
            )
        );
        _verifyMessage(encodedMessageHash, v, r, s);
    }

    /// @notice The Chainlink inherited function, give us tokens live price
    function getLatestPrice(
        IERC20 token
    ) public view returns (TokenInfo memory) {
        PriceFeedData memory data = tokenData[token];
        TokenInfo memory tokenInfo;
        if (address(data.priceFeed) == address(0)) {
            return tokenInfo;
        }
        (
            ,
            /*uint80 roundID*/ int price /*uint256 startedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = /*uint256 timeStamp*/ data.priceFeed.latestRoundData();
        tokenInfo = TokenInfo({
            latestPrice: uint256(price),
            normalizationFactorForToken: data.normalizationFactorForToken,
            normalizationFactorForNFT: data.normalizationFactorForNFT
        });
        return tokenInfo;
    }

    /// @notice Checks value, if zero then reverts
    function _checkValue(uint256 value) private pure {
        if (value == 0) {
            revert ZeroValue();
        }
    }

    /// @notice Validates blacklist address, round and deadline
    function _validatePurchase(
        uint32 round,
        uint256 deadline,
        IERC20 token
    ) private view {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        _checkBlacklist(msg.sender);
        if (!allowedTokens[round][token].access) {
            revert TokenDisallowed();
        }
        _verifyInRound(round);
    }

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if Invalid
    function _verifyCode(
        string memory code,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(msg.sender, code, deadline)
        );
        _verifyMessage(encodedMessageHash, v, r, s);
    }

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if Invalid
    function _verifyCodeWithPrice(
        string memory code,
        uint256 deadline,
        uint256 referenceTokenPrice,
        IERC20 token,
        uint256 normalizationFactor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(
                msg.sender,
                code,
                referenceTokenPrice,
                deadline,
                token,
                normalizationFactor
            )
        );
        _verifyMessage(encodedMessageHash, v, r, s);
    }

    /// @notice Verifies the address that signed a hashed message (`hash`) with
    /// `signature`
    function _verifyMessage(
        bytes32 encodedMessageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        if (
            signerWallet !=
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(encodedMessageHash),
                v,
                r,
                s
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @notice Process nft purchase by calculating nft prices and investment amount
    function _processPurchaseNFT(
        IERC20 token,
        uint256 price,
        uint256 normalizationFactor,
        uint32 round,
        uint256[] calldata nftAmounts,
        uint256[] memory nftPrices
    ) private returns (uint256, uint256) {
        uint256 value = 0;

        for (uint256 i = 0; i < nftPrices.length; ++i) {
            //  (10**0 * 10**6 +10**10) -10**10 = 6 decimals
            value +=
                (nftAmounts[i] * nftPrices[i] * (10 ** (normalizationFactor))) /
                price;
        }
        uint256 roundPrice = _getRoundPriceForToken(round, token);

        ClaimNFT memory amounts = ClaimNFT({
            nftAmounts: nftAmounts,
            roundPrice: roundPrice
        });
        claimNFT[msg.sender][round].push(amounts);
        return (value, roundPrice);
    }

    /// @notice Checks that address is blacklisted or not
    function _checkBlacklist(address which) private view {
        if (blacklistAddress[which]) {
            revert Blacklisted();
        }
    }

    /// @notice Validates round, deadline and signature
    function _validatePurchaseWithEth(
        uint256 amount,
        uint32 round,
        uint256 deadline,
        string memory code,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        _checkValue(amount);
        _validatePurchase(round, deadline, ETH);
        _verifyCode(code, deadline, v, r, s);
    }

    /// @notice Validates round, deadline and signature
    function _validatePurchaseWithToken(
        IERC20 token,
        uint32 round,
        uint256 deadline,
        string memory code,
        uint256 referenceTokenPrice,
        uint256 normalizationFactor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        _validatePurchase(round, deadline, token);
        _verifyCodeWithPrice(
            code,
            deadline,
            referenceTokenPrice,
            token,
            normalizationFactor,
            v,
            r,
            s
        );
    }

    /// @notice Validates round, deadline and signature
    function _getRoundPriceForToken(
        uint32 round,
        IERC20 token
    ) private view returns (uint256) {
        uint256 customPrice = allowedTokens[round][token].customPrice;
        uint256 roundPrice = customPrice > 0
            ? customPrice
            : rounds[round].price;
        return roundPrice;
    }

    /// @notice Calculates the dop amount
    function _calculateDop(
        uint256 investment,
        uint256 referenceTokenPrice,
        uint256 normalizationFactor,
        uint256 roundPrice
    ) private pure returns (uint256) {
        // toReturn= (10**11 * 10**10 +10**15) -10**18 = 18 decimals
        uint256 toReturn = (investment *
            referenceTokenPrice *
            (10 ** normalizationFactor)) / roundPrice;
        return toReturn;
    }

    function _validatePrice(
        IERC20 token,
        uint256 referenceTokenPrice,
        uint8 referenceNormalizationFactor
    ) private view returns (uint256, uint256) {
        TokenInfo memory tokenInfo = getLatestPrice(token);
        if (tokenInfo.latestPrice != 0) {
            if (referenceTokenPrice != 0 || referenceNormalizationFactor != 0) {
                revert CodeSyncIssue();
            }
        }
        //  If price feed isn't available,we fallback to the reference price
        if (tokenInfo.latestPrice == 0) {
            if (referenceTokenPrice == 0 || referenceNormalizationFactor == 0) {
                revert ZeroValue();
            }
            tokenInfo.latestPrice = referenceTokenPrice;
            tokenInfo
                .normalizationFactorForToken = referenceNormalizationFactor;
        }
        return (tokenInfo.latestPrice, tokenInfo.normalizationFactorForToken);
    }
}
