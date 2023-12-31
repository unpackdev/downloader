// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./ECDSA.sol";
import "./Address.sol";

/// @title PreSaleDopInstitution contract
/// @author Dop
/// @notice Implements the preSale of Dop Token
/// @dev The PreSaleDopInstitution contract allows you to purchase dop token with ETH and USD

contract PreSaleDopInstitution is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Thrown when address is blacklisted
    error Blacklisted();

    /// @notice Thrown when updating an address with zero address
    error ZeroAddress();

    /// @notice Thrown when buy is disabled
    error BuyNotEnable();

    /// @notice Thrown when claim is disabled
    error ClaimNotEnable();

    /// @notice Thrown when signature is invalid
    error InvalidSignature();

    /// @notice Thrown when Eth price suddenly drops while purchasing with ETH
    error UnexpectedPriceDifference();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    /// @notice Thrown when value to trasfer is zero
    error ValueZero();

    /// @notice Thrown when sign deadline is expired
    error DeadlineExpired();

    /// @notice Returns the chainlink price feed contract address
    AggregatorV3Interface internal immutable PRICE_FEED;

    /// @notice Returns the multiplier to handle zeros
    uint256 private constant MULTIPLIER10 = 1e10;

    /// @notice Returns the multiplier to handle zeros
    uint256 private constant MULTIPLIER30 = 1e30;

    /// @notice Returns that BuyEnable or not
    bool public buyEnable;

    /// @notice Returns that claimEnable or not
    bool public claimEnable;

    /// @notice Returns the address of signerWallet
    address public signerWallet;

    /// @notice Returns the address of dopWallet
    address public dopWallet;

    /// @notice Returns the address of fundsWallet
    address public fundsWallet;

    /// @notice Returns the USDT address
    IERC20 public immutable USDT;

    /// @notice Returns the dopToken address
    IERC20 public dopToken;

    /// @notice mapping gives claim info of user
    mapping(address => uint256) public claims;

    /// @notice mapping gives info about address's permission
    mapping(address => bool) public blacklistAddress;

    /* ========== EVENTS ========== */

    event InvestedWithEth(
        address indexed by,
        string code,
        uint256 amountInvestedEth,
        address indexed recipient,
        uint256 indexed price,
        uint256 dopPurchased
    );
    event InvestedWithUSDT(
        address indexed by,
        string code,
        uint256 amountInUsd,
        address indexed recipient,
        uint256 indexed price,
        uint256 dopPurchased
    );
    event Claimed(address indexed by, uint256 amount);
    event SignerUpdated(address oldSigner, address newSigner);
    event DopWalletUpdated(address oldAddress, address newAddress);
    event DopTokenUpdated(address oldDopAddress, address newDopAddress);
    event FundsWalletUpdated(address oldAddress, address newAddress);
    event BlacklistUpdated(address which, bool accessNow);
    event BuyEnableUpdated(bool oldAccess, bool newAccess);
    event ClaimEnableUpdated(bool oldAccess, bool newAccess);

    /* ========== MODIFIERS ========== */

    /// @notice restricts blacklisted addresses
    modifier notBlacklisted(address which) {
        if (blacklistAddress[which]) {
            revert Blacklisted();
        }
        _;
    }

    /// @notice restricts when updating wallet/contract address to zero address
    modifier checkZeroAddress(address which) {
        if (which == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice ensures that buy is enabled when buying
    modifier canBuy() {
        if (!buyEnable) {
            revert BuyNotEnable();
        }
        _;
    }

    /// @notice ensures that claim is enabled when claiming
    modifier canClaim() {
        if (!claimEnable) {
            revert ClaimNotEnable();
        }
        _;
    }

    /// @dev Constructor.
    /// @param priceFeed The address of chainlink price feed contract
    /// @param signerAddress The address of signer wallet
    /// @param fundsWalletAddress The address of funds wallet
    /// @param dopAddress The address of Dop token
    /// @param usdt The address of usdt contract
    constructor(
        AggregatorV3Interface priceFeed,
        address fundsWalletAddress,
        address signerAddress,
        address dopAddress,
        IERC20 usdt
    ) {
        if (
            address(priceFeed) == address(0) ||
            fundsWalletAddress == address(0) ||
            signerAddress == address(0) ||
            dopAddress == address(0) ||
            address(usdt) == address(0)
        ) {
            revert ZeroAddress();
        }
        PRICE_FEED = AggregatorV3Interface(priceFeed);
        buyEnable = true;
        fundsWallet = fundsWalletAddress;
        signerWallet = signerAddress;
        dopWallet = dopAddress;
        USDT = usdt;
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

    /// @notice Changes access of claiming
    /// @param enabled The decision about claiming
    function enableClaim(bool enabled) external onlyOwner {
        if (claimEnable == enabled) {
            revert IdenticalValue();
        }
        emit ClaimEnableUpdated({oldAccess: claimEnable, newAccess: enabled});
        claimEnable = enabled;
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function changeSigner(
        address newSigner
    ) external checkZeroAddress(newSigner) onlyOwner {
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
    ) external checkZeroAddress(newFundsWallet) onlyOwner {
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

    /// @notice Changes dop wallet to a new address
    /// @param newDopWallet The address of the new dop wallet
    function changeDopWallet(
        address newDopWallet
    ) external checkZeroAddress(newDopWallet) onlyOwner {
        address dopWalletOld = dopWallet;
        if (dopWalletOld == newDopWallet) {
            revert IdenticalValue();
        }
        emit DopWalletUpdated({
            oldAddress: dopWalletOld,
            newAddress: newDopWallet
        });
        dopWallet = newDopWallet;
    }

    /// @notice Changes dop token contract to a new address
    /// @param newDopAddress The address of the new dop token
    function updateDopToken(
        IERC20 newDopAddress
    ) external checkZeroAddress(address(newDopAddress)) onlyOwner {
        IERC20 oldDop = dopToken;
        if (oldDop == newDopAddress) {
            revert IdenticalValue();
        }
        emit DopTokenUpdated({
            oldDopAddress: address(oldDop),
            newDopAddress: address(newDopAddress)
        });
        dopToken = newDopAddress;
    }

    /// @notice Changes the access of any address in contract interaction
    /// @param which The address for which access is updated
    /// @param access The access decision of `which` address
    function updateBlackListedUser(
        address which,
        bool access
    ) external checkZeroAddress(which) onlyOwner {
        bool oldAccess = blacklistAddress[which];
        if (oldAccess == access) {
            revert IdenticalValue();
        }
        emit BlacklistUpdated({which: which, accessNow: access});
        blacklistAddress[which] = access;
    }

    /// @notice Purchases dopToken with Eth
    /// @param code The code is used to verify signature of the user
    /// @param recipient The recipient is the address which will claim Dop tokens
    /// @param price The price is usdt price of Dop token
    /// @param deadline The deadline is validity of the signature
    /// @param minAmountDop The minAmountDop user agrees to purchase
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseWithEth(
        string memory code,
        address recipient,
        uint256 price,
        uint256 deadline,
        uint256 minAmountDop,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable notBlacklisted(msg.sender) canBuy {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        if (recipient == address(0)) {
            recipient = msg.sender;
        }
        _checkValue(msg.value);
        _verifyCode(msg.sender, code, price, deadline, v, r, s);
        // we don't expect such large msg.value `or `getLatestPriceEth() value such that this multiplication overflows and reverts.

        uint256 toReturn = ((msg.value * getLatestPriceEth()) * MULTIPLIER10) /
            (price);
        if (toReturn < minAmountDop) {
            revert UnexpectedPriceDifference();
        }
        claims[recipient] += toReturn;
        payable(fundsWallet).sendValue(msg.value);
        emit InvestedWithEth({
            by: msg.sender,
            code: code,
            amountInvestedEth: msg.value,
            recipient: recipient,
            price: price,
            dopPurchased: toReturn
        });
    }

    /// @notice Purchases dopToken with Usdt token
    /// @param investment The Investment amount
    /// @param code The code is used to verify signature of the user
    /// @param recipient The recipient is the address which will claim Dop tokens
    /// @param price The price is usdt price of Dop token
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseWithUsdt(
        uint256 investment,
        string memory code,
        address recipient,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external notBlacklisted(msg.sender) canBuy {
        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }
        if (recipient == address(0)) {
            recipient = msg.sender;
        }
        _checkValue(investment);
        _verifyCode(msg.sender, code, price, deadline, v, r, s);
        // we don't expect such value such that this multiplication overflows and reverts.
        uint256 toReturn = (investment * MULTIPLIER30) / (price);
        claims[recipient] += toReturn;

        USDT.safeTransferFrom(msg.sender, fundsWallet, investment);
        emit InvestedWithUSDT({
            by: msg.sender,
            code: code,
            amountInUsd: investment,
            recipient: recipient,
            price: price,
            dopPurchased: toReturn
        });
    }

    /// @notice Claim dopToken purchased
    function claimTokens() external notBlacklisted(msg.sender) canClaim {
        uint amountClaim = claims[msg.sender];
        _checkValue(amountClaim);
        delete claims[msg.sender];
        dopToken.safeTransferFrom(dopWallet, msg.sender, amountClaim);

        emit Claimed({by: msg.sender, amount: amountClaim});
    }

    /// @notice The chainlink inherited function, gives ETH/USD live price
    function getLatestPriceEth() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/ int price /*uint256 startedAt*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = /*uint256 timeStamp*/ PRICE_FEED.latestRoundData();

        return uint256(price); // returns value 8 decimals
    }

    /// @notice The helper function which verifies signature, signed by signerWallet, reverts if invalidSignature
    function _verifyCode(
        address by,
        string memory code,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(by, code, price, deadline)
        );

        if (
            signerWallet !=
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(encodedMessageHash),
                v,
                r,
                s
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @notice Checks value, if zero then reverts
    function _checkValue(uint256 value) internal pure {
        if (value == 0) {
            revert ValueZero();
        }
    }
}
