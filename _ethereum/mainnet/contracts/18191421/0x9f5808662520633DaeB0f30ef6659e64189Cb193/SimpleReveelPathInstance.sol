// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.15;

import "./Ownable.sol";
import "./Initializable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ERC2771Recipient.sol";

/*******************************
 * @title Simple Reveel Path
 * @notice The simple revenue path clone instance contract.
 */

interface IReveelPathFactory {
    function getPlatformWallet() external view returns (address);
}

contract SimpleReveelPathInstance is
    ERC2771Recipient,
    Ownable,
    Initializable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    uint32 public constant BASE = 1e7;

    bool private feeRequired;

    bool private isImmutable;

    uint32 private gasFee;

    address private mainFactory;

    bytes32 private pathHash;

    /**
     * @notice For a given token & wallet address, returns the amount of token released
     */
    mapping(address => mapping(address => uint256)) private released;

    /**
     * @notice Maps token address to the amount of token released from the path
     */
    mapping(address => uint256) private totalTokenReleased;

    /**
     * @notice Maps token address to the amount of token gone through accounting in the path
     */
    mapping(address => uint256) private totalTokenAccounted;

    /**  @notice For a given token & wallet address, the amount of the token that can been withdrawn by the wallet
    [token][wallet]*/
    mapping(address => mapping(address => uint256)) private tokenWithdrawable;

    /**
     * @notice For a given token & tiernumber, the total distributed in that tier is returned

     */
    mapping(address => uint256) private totalDistributed;

    /**
     * @notice For a given token the amount of fee that has been accumulated is returned.
     */
    mapping(address => uint256) private feeAccumulated;

    struct PathInfo {
        uint32 gasFee;
        bool isImmutable;
        address factory;
        address forwarder;
    }

    /********************************
     *           EVENTS              *
     ********************************/

    /** @notice Emits when token payment is withdrawn/claimed by a member
     * @param account The wallet for which token has been claimed for
     * * @param account The wallet for which token has been claimed for
     * @param payment The amount of token that has been paid out to the wallet
     */
    event PaymentReleased(
        address indexed account,
        address indexed token,
        uint256 indexed payment
    );

    /** @notice Emits when ERC20 payment is withdrawn/claimed by a member
     * @param token The token address for which withdrawal is made
     * @param account The wallet address to which withdrawal is made
     * @param payment The amount of the given token the wallet has claimed
     */
    event ERC20PaymentReleased(
        address indexed token,
        address indexed account,
        uint256 indexed payment
    );

    /** @notice Emits when tokens are distributed during withdraw or external distribution call
     *  @param token Address of token for distribution. Zero address for native token like ETH
     *  @param amount The amount of token distributed in wei
     */
    event TokenDistributed(address indexed token, uint256 indexed amount);

    /** @notice Emits on receive; mimics ERC20 Transfer
     *  @param from Address that deposited the eth
     *  @param value Amount of ETH deposited
     */
    event DepositETH(address indexed from, uint256 value);

    /**
     *  @notice Emits when fee is released
     *  @param token The token address. Address 0 for native gas token like ETH
     *  @param amount The amount of fee released
     */
    event FeeReleased(address indexed token, uint256 indexed amount);

    /**
     * emits when one or more revenue tiers are added
     *  @param wallets Array of arrays of wallet lists (each array is a tier)
     *  @param distributions Array of arrays of distr %s (each array is a tier)
     */
    event RevenueTierAdded(address[][] wallets, uint256[][] distributions);

    /**
     * emits when one or more revenue tiers wallets/distributions are updated
     *  @param wallets Array of arrays of wallet lists (each array is a tier)
     *  @param distributions Array of arrays of distr %s (each array is a tier)
     */
    event RevenueTierUpdated(address[] wallets, uint256[] distributions);

    /********************************
     *           MODIFIERS          *
     ********************************/
    /** @notice Entrant guard for mutable contract methods
     */
    modifier isMutable() {
        if (isImmutable) {
            revert RevenuePathNotMutable();
        }
        _;
    }

    /********************************
     *           ERRORS          *
     ********************************/

    /** @dev Reverts when passed wallet list and distribution list length is not equal
     * @param walletCount Length of wallet list
     * @param distributionCount Length of distribution list
     */
    error WalletAndDistrbutionCtMismatch(
        uint256 walletCount,
        uint256 distributionCount
    );

    /** @dev Reverts when the member has zero  withdrawal balance available
     */
    error NoDuePayment(address wallet);

    /** @dev Reverts when immutable path attempts to use mutable methods
     */
    error RevenuePathNotMutable();

    /** @dev Reverts when contract has insufficient token for withdrawal
     * @param contractBalance  The total balance of token available in the contract
     * @param requiredAmount The total amount of token requested for withdrawal
     */
    error InsufficentBalance(uint256 contractBalance, uint256 requiredAmount);

    /**
     * @dev Reverts when summation of distirbution is not equal to BASE
     */
    error TotalShareNot100();

    error InvalidPathHash();

    /********************************
     *           FUNCTIONS           *
     ********************************/

    /**
     * @notice Receive ETH
     */
    receive() external payable {
        emit DepositETH(_msgSender(), msg.value);
    }

    /** @notice Called for a given token to distribute, unallocated tokens to the respective tiers and wallet members
     *  @param token The address of the token
     *  @param _walletList the nested array of wallet list of all the tiers
     *  @param _distribution the nested array of distribution of the corresponding wallets of all the tiers.
     */
    function distributePendingTokens(
        address token,
        address[] memory _walletList,
        uint256[] memory _distribution
    ) external nonReentrant {
        _distributePendingTokens(token, _walletList, _distribution);
    }

    /** @notice Get the token amount that has not been allocated for in the revenue path
     *  @param token The token address
     */
    function getPendingDistributionAmount(
        address token
    ) public view returns (uint256) {
        uint256 pathTokenBalance;
        if (token == address(0)) {
            pathTokenBalance = address(this).balance;
        } else {
            pathTokenBalance = IERC20(token).balanceOf(address(this));
        }
        uint256 _pendingAmount = (pathTokenBalance +
            totalTokenReleased[token]) - totalTokenAccounted[token];
        return _pendingAmount;
    }

    /** @notice Initializes revenue path
     *  @param _walletList Nested array for wallet list across different tiers
     *  @param _distribution Nested array for distribution percentage across different tiers
     *  @param pathInfo A property object for the path details
     *  @param _owner Address of path owner
     */
    function initialize(
        address[] memory _walletList,
        uint256[] memory _distribution,
        PathInfo calldata pathInfo,
        address _owner
    ) external initializer {
        _validatePath(_walletList, _distribution);
        _generatePathHash(_walletList, _distribution);
        mainFactory = pathInfo.factory;
        gasFee = pathInfo.gasFee;
        isImmutable = pathInfo.isImmutable;

        _transferOwnership(_owner);
        _setTrustedForwarder(pathInfo.forwarder);
    }

    /** @notice Updating distribution for existing revenue tiers
     *  @param _walletList A  list of wallet address
     *  @param _distribution A  list of distribution percentage
     */
    function updateRevenueTiers(
        address[] memory _walletList,
        uint256[] memory _distribution
    ) external isMutable onlyOwner {
        _validatePath(_walletList, _distribution);

        _generatePathHash(_walletList, _distribution);
        emit RevenueTierUpdated(_walletList, _distribution);
    }

    /** @notice Releases distribute token
     * @param token The token address
     * @param accounts The address of the receivers
     */

    function release(
        address token,
        address payable[] calldata accounts,
        address[] memory _walletList,
        uint256[] memory _distribution,
        bool shouldDistribute
    ) external nonReentrant {
        if (shouldDistribute) {
            _distributePendingTokens(token, _walletList, _distribution);
        }

        uint256 _totalTokenReleased;
        uint256 payment;

        if (token == address(0)) {
            unchecked {
                for (uint256 i; i < accounts.length; ) {
                    payment = tokenWithdrawable[token][accounts[i]];
                    if (payment == 0) {
                        revert NoDuePayment({wallet: accounts[i]});
                    }
                    released[token][accounts[i]] += payment;
                    _totalTokenReleased += payment;
                    tokenWithdrawable[token][accounts[i]] = 0;
                    sendValue(accounts[i], payment);
                    emit PaymentReleased(accounts[i], token, payment);

                    i++;
                }
            }
            totalTokenReleased[token] += _totalTokenReleased;

            if (feeAccumulated[token] > 0) {
                uint256 value = feeAccumulated[token];
                feeAccumulated[token] = 0;
                totalTokenReleased[token] += value;
                address gasFeeWallet = IReveelPathFactory(mainFactory)
                    .getPlatformWallet();
                sendValue(payable(gasFeeWallet), value);
                emit FeeReleased(token, value);
            }
        } else {
            unchecked {
                for (uint256 i; i < accounts.length; ) {
                    payment = tokenWithdrawable[token][accounts[i]];
                    if (payment == 0) {
                        revert NoDuePayment({wallet: accounts[i]});
                    }
                    released[token][accounts[i]] += payment;
                    _totalTokenReleased += payment;
                    tokenWithdrawable[token][accounts[i]] = 0;
                    IERC20(token).safeTransfer(accounts[i], payment);
                    emit ERC20PaymentReleased(token, accounts[i], payment);

                    i++;
                }
            } //For loop ends

            totalTokenReleased[token] += _totalTokenReleased;
            if (feeAccumulated[token] > 0) {
                uint256 value = feeAccumulated[token];
                feeAccumulated[token] = 0;
                totalTokenReleased[token] += value;
                address gasFeeWallet = IReveelPathFactory(mainFactory)
                    .getPlatformWallet();
                IERC20(token).safeTransfer(gasFeeWallet, value);
                emit FeeReleased(token, value);
            }
        }
    }

    /** @notice Get the current ongoing tier of revenue path
     */
    function getFeeRequirementStatus() external view returns (bool required) {
        return feeRequired;
    }

    /** @notice Get the amount of ETH accumulated for fee collection
     */

    function getTotalFeeAccumulated(
        address token
    ) external view returns (uint256 amount) {
        return feeAccumulated[token];
    }

    /** @notice Get the amount of token released for a given account
     *  @param token the token address for which token released is fetched
     *  @param account the wallet address for whih the token released is fetched
     */

    function getTokenReleased(
        address token,
        address account
    ) external view returns (uint256 amount) {
        return released[token][account];
    }

    /** @notice Get the platform fee percentage
     */
    function getGasFee() external view returns (uint256) {
        return gasFee;
    }

    /** @notice Get the revenue path Immutability status
     */
    function getImmutabilityStatus() external view returns (bool) {
        return isImmutable;
    }

    /** @notice Get the amount of total eth withdrawn by the account
     */
    function getTokenWithdrawn(
        address token,
        address account
    ) external view returns (uint256) {
        return released[token][account];
    }

    /** @notice Update the trusted forwarder address
     *  @param forwarder The address of the new forwarder
     *
     */
    function setTrustedForwarder(address forwarder) external onlyOwner {
        _setTrustedForwarder(forwarder);
    }

    /**
     * @notice Returns total token released
     * @param token The token for which total released amount is fetched
     */
    function getTotalTokenReleased(
        address token
    ) external view returns (uint256) {
        return totalTokenReleased[token];
    }

    /**
     * @notice Returns total token accounted for a given token address
     * @param token The token for which total accountd amount is fetched
     */
    function getTotalTokenAccounted(
        address token
    ) external view returns (uint256) {
        return totalTokenAccounted[token];
    }

    /**
     * @notice Returns withdrawable or claimable token amount for a given wallet in the revenue path
     */
    function getWithdrawableToken(
        address token,
        address wallet
    ) external view returns (uint256) {
        return tokenWithdrawable[token][wallet];
    }

    /**
     * @notice Returns the SimpleReveelPathFactory contract address
     */
    function getMainFactory() external view returns (address) {
        return mainFactory;
    }

    function getRevenuePathHash() external view returns (bytes32) {
        return pathHash;
    }

    function getTotalDistributedAmount(
        address token
    ) external view returns (uint256) {
        return totalDistributed[token];
    }

    /** @notice Transfer handler for ETH
     * @param recipient The address of the receiver
     * @param amount The amount of ETH to be received
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAILED");
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /**
     * @notice Generates a path hash that is unique for the given walletList & distribution
     */
    function _generatePathHash(
        address[] memory _walletList,
        uint256[] memory _distribution
    ) private {
        pathHash = keccak256(abi.encode(_walletList, _distribution));
    }

    /**
     * @notice Validates the passed path details against the existing path hash
     */
    function _validatePathHash(
        address[] memory _walletList,
        uint256[] memory _distribution
    ) private view {
        bytes32 newPathHash = keccak256(abi.encode(_walletList, _distribution));

        if (newPathHash != pathHash) {
            revert InvalidPathHash();
        }
    }

    /**
     * @notice Validates all path details.
     */
    function _validatePath(
        address[] memory _walletList,
        uint256[] memory _distribution
    ) internal pure {
        uint256 totalWallets = _walletList.length;
        if (totalWallets != _distribution.length) {
            revert WalletAndDistrbutionCtMismatch({
                walletCount: totalWallets,
                distributionCount: _distribution.length
            });
        }

        uint256 totalDistribution;
        unchecked {
            for (uint256 i; i < totalWallets; ) {
                totalDistribution += _distribution[i];
                i++;
            }

            if (totalDistribution != BASE) {
                revert TotalShareNot100();
            }
        }
    }

    /** @notice Called for a given token to distribute, unallocated tokens to the respective tiers and wallet members
     *  @param token The address of the token
     *  @param _walletList the nested array of wallet list of all the tiers
     *  @param _distribution the nested array of distribution of the corresponding wallets of all the tiers.
     */
    function _distributePendingTokens(
        address token,
        address[] memory _walletList,
        uint256[] memory _distribution
    ) internal {
        _validatePathHash(_walletList, _distribution);

        uint256 pendingAmount = getPendingDistributionAmount(token);
        if (pendingAmount > 0) {
            uint256 distributionAmount;
            uint256 feeAmount;
            unchecked {
                if (gasFee > 0) {
                    feeAmount = ((pendingAmount * gasFee) / BASE);
                    feeAccumulated[token] += feeAmount;
                }

                distributionAmount = pendingAmount - feeAmount;

                uint256 totalWallets = _walletList.length;

                for (uint256 i; i < totalWallets; ) {
                    tokenWithdrawable[token][
                        _walletList[i]
                    ] += ((distributionAmount * _distribution[i]) / BASE);
                    i++;
                }

                totalTokenAccounted[token] += pendingAmount;
                totalDistributed[token] += pendingAmount;
            }

            emit TokenDistributed(token, pendingAmount);
        }
    }
}
