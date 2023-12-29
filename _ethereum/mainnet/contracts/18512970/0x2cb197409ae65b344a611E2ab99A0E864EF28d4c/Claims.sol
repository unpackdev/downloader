// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

import "./IPreSaleDop.sol";

import "./Common.sol";

/// @title Claims contract
/// @notice Implements the claiming of the leader's commissons

contract Claims is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Thrown when input array length is zero
    error InvalidData();

    /// @notice Thrown when claiming before round ends
    error RoundNotEnded();

    /// @notice Thrown when round is not Enabled
    error RoundNotEnabled();

    /// @notice Thrown when CommissionsManager wants to setClaim while claim enable
    error WaitForRoundDisable();

    /// @notice Returns the identifier of the CommissionsManager role
    bytes32 public constant COMMISSIONS_MANAGER =
        keccak256("COMMISSIONS_MANAGER");

    /// @notice Returns the identifier of the AdminRole role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @notice Returns the address of PreSaleDop contract
    IPreSaleDop public presaleDop;

    /// @member token The token address
    /// @member amount The token amount
    struct ClaimInfo {
        IERC20 token;
        uint256 amount;
    }

    /// @notice Stores the amount of token in a round of the user
    mapping(address => mapping(uint32 => mapping(IERC20 => uint256)))
        public pendingClaims;

    /// @notice Stores the enabled/disabled status of a round
    mapping(uint32 => bool) public isEnabled;

    /// @dev Emitted when claim amount is set for the addresses
    event ClaimSet(
        address[] indexed to,
        uint32 indexed round,
        IERC20 token,
        uint256 amount
    );

    /// @dev Emitted when claim amount is claimed
    event FundsClaimed(
        address indexed by,
        uint32 indexed round,
        IERC20 token,
        uint256 amount
    );

    /// @dev Emitted when claim access changes for the round
    event RoundEnableUpdated(bool oldAccess, bool newAccess);

    /// @dev Emitted when dop preSale contract is updated
    event PresaleDopUpdated(address oldpresaleDop, address newpresaleDop);

    /// @dev Constructor.
    constructor() {
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(COMMISSIONS_MANAGER, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Updates token amounts to addresses in a given round
    /// @param to The array of claimants
    /// @param round The round number
    /// @param claims The tokens and amount to claim
    function setClaim(
        address[] calldata to,
        uint32 round,
        ClaimInfo[][] memory claims
    ) external onlyRole(COMMISSIONS_MANAGER) {
        if (isEnabled[round]) {
            revert WaitForRoundDisable();
        }
        uint256 toLength = to.length;
        if (toLength == 0) {
            revert InvalidData();
        }
        if (toLength != claims.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i; i < toLength; ++i) {
            mapping(IERC20 => uint256) storage claimInfo = pendingClaims[to[i]][
                round
            ];
            for (uint256 j = 0; j < claims[i].length; j++) {
                ClaimInfo memory amount = claims[i][j];
                claimInfo[amount.token] = amount.amount;
                emit ClaimSet({
                    to: to,
                    round: round,
                    token: amount.token,
                    amount: amount.amount
                });
            }
        }
    }

    /// @notice Claims the amount in a given round
    /// @param round The round in which you want to claim
    /// @param tokens The addresses of the token to be claimed
    function claim(
        uint32 round,
        IERC20[] calldata tokens
    ) external nonReentrant {
        _checkRoundAndTime(round);
        mapping(IERC20 => uint256) storage claimInfo = pendingClaims[
            msg.sender
        ][round];
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amount = claimInfo[token];
            if (amount == 0) {
                continue;
            }
            delete claimInfo[token];

            if (token == ETH) {
                payable(msg.sender).sendValue(amount);
            } else {
                token.safeTransfer(msg.sender, amount);
            }
            emit FundsClaimed({
                by: msg.sender,
                round: round,
                token: token,
                amount: amount
            });
        }
    }

    /// @notice Purchases Dop Token with claim amounts
    /// @param round The round in which user will purchase
    /// @param deadline The deadline of the signature
    /// @param tokenPrices The current prices of the tokens in 10 decimals
    /// @param tokens The address of the tokens
    /// @param amounts The Investment amounts
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function purchaseWithClaim(
        uint32 round,
        uint256 deadline,
        uint8[] calldata normalizationFactors,
        uint256[] calldata tokenPrices,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata minAmountsDop,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        _checkRoundAndTime(round);
        if (normalizationFactors.length == 0) {
            revert ZeroLengthArray();
        }
        if (
            normalizationFactors.length != tokenPrices.length ||
            tokenPrices.length != tokens.length ||
            tokens.length != amounts.length ||
            amounts.length != minAmountsDop.length
        ) {
            revert ArrayLengthMismatch();
        }
        _verifyPurchaseWithClaim(
            msg.sender,
            round,
            deadline,
            tokenPrices,
            normalizationFactors,
            tokens,
            amounts,
            v,
            r,
            s
        );

        mapping(IERC20 => uint256) storage info = pendingClaims[msg.sender][
            round
        ];
        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amountToInvest = amounts[i];
            uint8 normalizationFactor = normalizationFactors[i];
            uint256 minAmountDop = minAmountsDop[i];
            uint256 amount = info[token];
            if (amount == 0) {
                continue;
            }
            if (amountToInvest > amount) {
                continue;
            }
            delete info[token];
            uint256 remainingAmount = amount - amountToInvest;

            if (token == ETH) {
                presaleDop.purchaseWithClaim{value: amountToInvest}(
                    ETH,
                    0,
                    normalizationFactor,
                    amountToInvest,
                    minAmountDop,
                    msg.sender,
                    round
                );
            } else {
                // address presaleContract = address(presaleDop);
                uint256 allowance = token.allowance(
                    address(this),
                    address(presaleDop)
                );
                if (allowance < amountToInvest) {
                    token.forceApprove(address(presaleDop), type(uint256).max);
                }

                presaleDop.purchaseWithClaim(
                    token,
                    tokenPrices[i],
                    normalizationFactor,
                    amountToInvest,
                    minAmountDop,
                    msg.sender,
                    round
                );
            }
            if (remainingAmount > 0) {
                if (token == ETH) {
                    payable(msg.sender).sendValue(remainingAmount);
                } else {
                    token.safeTransfer(msg.sender, remainingAmount);
                }
                emit FundsClaimed({
                    by: msg.sender,
                    round: round,
                    token: token,
                    amount: remainingAmount
                });
            }
        }
    }

    // The tokenPrices,tokens are provided externally and therefore have to be verified by the trusted presale contract
    function _verifyPurchaseWithClaim(
        address by,
        uint32 round,
        uint256 deadline,
        uint256[] calldata tokenPrices,
        uint8[] calldata normalizationFactors,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        presaleDop.verifyPurchaseWithClaim(
            by,
            round,
            deadline,
            tokenPrices,
            normalizationFactors,
            tokens,
            amounts,
            v,
            r,
            s
        );
    }

    /// @notice Verifies round and time
    function _checkRoundAndTime(uint32 round) internal view {
        if (!isEnabled[round]) {
            revert RoundNotEnabled();
        }
        (, uint256 endTime, ) = presaleDop.rounds(round);
        if (block.timestamp < endTime) {
            revert RoundNotEnded();
        }
    }

    /// @notice Changes PresaleDop contract address
    /// @param presaleDopAddress The address of the new PreSaleDop contract
    function updatePreSaleAddress(
        IPreSaleDop presaleDopAddress
    ) external onlyRole(ADMIN_ROLE) {
        if (address(presaleDopAddress) == address(0)) {
            revert ZeroAddress();
        }
        if (presaleDop == presaleDopAddress) {
            revert IdenticalValue();
        }
        emit PresaleDopUpdated({
            oldpresaleDop: address(presaleDop),
            newpresaleDop: address(presaleDopAddress)
        });
        presaleDop = presaleDopAddress;
    }

    /// @notice Changes the Claim access of the contract
    /// @param round The round number of which access is changed
    /// @param status The access status of the round
    function enableClaims(
        uint32 round,
        bool status
    ) public onlyRole(COMMISSIONS_MANAGER) {
        bool oldAccess = isEnabled[round];
        if (oldAccess == status) {
            revert IdenticalValue();
        }
        emit RoundEnableUpdated({oldAccess: oldAccess, newAccess: status});
        isEnabled[round] = status;
    }

    receive() external payable {}
}
