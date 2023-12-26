// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./Utils.sol";

interface IPreSaleDop {
    function rounds(
        uint8 round
    ) external view returns (uint256 startTime, uint256 endTime, uint256 price);

    function purchaseWithClaim(
        address recipient,
        uint8 round,
        uint256 amountUsd
    ) external payable;
}

contract Claims is AccessControl, Utils {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @notice Thrown when input arrays length does not match
    error ArgumentsLengthMismatch();

    /// @notice Thrown when no amounts are zero
    error ZeroClaimAmount();

    /// @notice Thrown when input array length is zero
    error InvalidData();

    /// @notice Thrown when zero address is passed while updating to new value
    error ZeroAddress();

    /// @notice Thrown when same value is passed while updating any variable
    error IdenticalValues();

    /// @notice Thrown when claiming before round ends
    error RoundNotEnded();

    /// @notice Thrown when round is not Enabled
    error RoundNotEnabled();

    /// @notice Thrown when CommissionsManager wants to setClaim while claim enable
    error WaitForRoundDisable();

    /// @notice Thrown when rebuying with zero Eth amount
    error AmountEthInvalid();

    /// @notice Thrown when rebuying with zero Usd amount
    error AmountUsdInvalid();

    /// @notice Thrown when all input amount inputs are zero
    error ZeroAmounts();

    /// @notice Returns the identifier of the CommissionsManager role
    bytes32 public constant COMMISSIONS_MANAGER =
        keccak256("COMMISSIONS_MANAGER");

    /// @notice Returns the identifier of the AdminRole role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @notice Returns the address of PreSaleDop contract
    IPreSaleDop public dopPreSale;

    /// @notice Returns usdt address
    IERC20 public immutable USDT;

    /// @member amountEth The Eth amount
    /// @member amountUsd The Usd amount
    struct Info {
        uint256 amountEth;
        uint256 amountUsd;
    }

    /// @notice mapping gives amount to claim in each round
    mapping(address => mapping(uint8 => Info)) public toClaim;

    /// @notice mapping stores the access of a round
    mapping(uint8 => bool) public isEnabled;

    /* ========== EVENTS ========== */

    event ClaimSet(
        address[] indexed to,
        uint8 indexed round,
        uint256[] amountsEth,
        uint256[] amountsUsd
    );
    event FundsClaimed(
        address indexed by,
        uint8 indexed round,
        uint256 amountEth,
        uint256 amountUsd
    );
    event RoundEnableUpdated(bool oldAccess, bool newAccess);
    event DopPreSaleUpdated(address oldDopPreSale, address newDopPreSale);

    /// @dev Constructor.
    /// @param usdt The address of usdt contract
    constructor(IERC20 usdt) {
        if (address(usdt) == address(0)) {
            revert ZeroAddress();
        }
        USDT = usdt;
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(COMMISSIONS_MANAGER, ADMIN_ROLE);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Updates Eth and Usd amounts to addresses in a given round
    /// @param to The array of addresses
    /// @param round The round value
    /// @param amountsEth The Eth amounts
    /// @param amountsUsd The Usdt amounts
    function setClaim(
        address[] calldata to,
        uint8 round,
        uint256[] calldata amountsEth,
        uint256[] calldata amountsUsd
    ) external onlyRole(COMMISSIONS_MANAGER) {
        if (isEnabled[round]) {
            revert WaitForRoundDisable();
        }
        uint256 toLength = to.length;
        if (toLength == 0) {
            revert InvalidData();
        }
        if (
            toLength != amountsEth.length &&
            amountsEth.length != amountsUsd.length
        ) {
            revert ArgumentsLengthMismatch();
        }
        for (uint256 i; i < toLength; i = uncheckedInc(i)) {
            Info storage infoClaim = toClaim[to[i]][round];
            if (amountsEth[i] > 0) {
                infoClaim.amountEth = amountsEth[i];
            }
            if (amountsUsd[i] > 0) {
                infoClaim.amountUsd = amountsUsd[i];
            }
        }
        emit ClaimSet({
            to: to,
            round: round,
            amountsEth: amountsEth,
            amountsUsd: amountsUsd
        });
    }

    /// @notice Claims the amount in a given round
    /// @param round The round in which you want to claim
    function claim(uint8 round) external {
        _checkRoundAndTime(round);
        Info memory info = toClaim[msg.sender][round];
        if (info.amountEth == 0 && info.amountUsd == 0) {
            revert ZeroClaimAmount();
        }
        delete toClaim[msg.sender][round];
        if (info.amountEth > 0) {
            payable(msg.sender).sendValue(info.amountEth);
        }
        if (info.amountUsd > 0) {
            USDT.safeTransfer(msg.sender, info.amountUsd);
        }
        emit FundsClaimed({
            by: msg.sender,
            round: round,
            amountEth: info.amountEth,
            amountUsd: info.amountUsd
        });
    }

    /// @notice Purchases Dop Token with claim amounts
    /// @param round The amounts of that round will be used
    /// @param amountEth The amountEth is Eth amount you wanna spend
    /// @param amountUsd The amountUsd is Usd amount you wanna spend
    function purchaseWithClaim(
        uint8 round,
        uint256 amountEth,
        uint256 amountUsd
    ) external {
        _checkRoundAndTime(round);
        if (amountEth == 0 && amountUsd == 0) {
            revert ZeroAmounts();
        }
        Info memory info = toClaim[msg.sender][round];
        if (amountEth > info.amountEth) {
            revert AmountEthInvalid();
        }
        if (amountUsd > info.amountUsd) {
            revert AmountUsdInvalid();
        }

        delete toClaim[msg.sender][round];
        USDT.forceApprove(address(dopPreSale), amountUsd);
        dopPreSale.purchaseWithClaim{value: amountEth}(
            msg.sender,
            round,
            amountUsd
        );
        uint256 amountEthExist = info.amountEth - amountEth;
        uint256 amountUsdExist = info.amountUsd - amountUsd;
        if (amountEthExist > 0) {
            payable(msg.sender).sendValue(amountEthExist);
        }
        if (amountUsdExist > 0) {
            USDT.safeTransfer(msg.sender, amountUsdExist);
        }
        emit FundsClaimed({
            by: msg.sender,
            round: round,
            amountEth: amountEthExist,
            amountUsd: amountUsdExist
        });
    }

    function _checkRoundAndTime(uint8 round) internal view {
        if (!isEnabled[round]) {
            revert RoundNotEnabled();
        }
        (, uint256 endTime, ) = dopPreSale.rounds(round);
        if (block.timestamp < endTime) {
            revert RoundNotEnded();
        }
    }

    /// @notice Changes DopPresale contract address
    /// @param dopPreSaleAddress The address of the new PreSaleDop contract
    function updatePreSaleAddress(
        IPreSaleDop dopPreSaleAddress
    ) external onlyRole(ADMIN_ROLE) {
        if (address(dopPreSaleAddress) == address(0)) {
            revert ZeroAddress();
        }
        if (dopPreSale == dopPreSaleAddress) {
            revert IdenticalValues();
        }
        emit DopPreSaleUpdated({
            oldDopPreSale: address(dopPreSale),
            newDopPreSale: address(dopPreSaleAddress)
        });
        dopPreSale = dopPreSaleAddress;
    }

    /// @notice Changes the Claim access of the contract
    /// @param round The round number of which access is changed
    /// @param decision The access decision of the round
    function updateEnable(
        uint8 round,
        bool decision
    ) public onlyRole(COMMISSIONS_MANAGER) {
        bool oldAccess = isEnabled[round];
        if (oldAccess == decision) {
            revert IdenticalValues();
        }
        emit RoundEnableUpdated({oldAccess: oldAccess, newAccess: decision});
        isEnabled[round] = decision;
    }

    receive() external payable {}
}
