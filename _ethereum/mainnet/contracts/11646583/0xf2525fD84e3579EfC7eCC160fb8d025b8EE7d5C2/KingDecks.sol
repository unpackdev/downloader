pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./TokenList.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

/**
 * It accepts deposits of a pre-defined ERC-20 token(s), the "deposit" token.
 * The deposit token will be repaid with another ERC-20 token, the "repay"
 * token (e.g. a stable-coin), at a pre-defined rate.
 *
 * On top of the deposit token, a particular NFT (ERC-721) instance may be
 * required to be deposited as well. If so, this exact NFT will be returned.
 *
 * Note the `treasury` account that borrows and repays tokens.
 */
contract KingDecks is Ownable, ReentrancyGuard, TokenList {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // On a deposit withdrawal, a user receives the "repay" token
    // (but not the originally deposited ERC-20 token).
    // The amount (in the  "repay" token units) to be repaid is:
    // `amountDue = Deposit.amount * TermSheet.rate/1e+9`                (1)

    // If interim withdrawals allowed, the amount which can not be withdrawn
    // before the deposit period ends is:
    // `minBalance = Deposit.amountDue * Deposit.lockedShare / 65535`    (2)
    //
    // (note: `TermSheet.earlyRepayableShare` defines `Deposit.lockedShare`)

    // Limit on the deposited ERC-20 token amount
    struct Limit {
        // Min token amount to deposit
        uint224 minAmount;
        // Max deposit amount multiplier, scaled by 1e+4
        // (no limit, if set to 0):
        // `maxAmount = minAmount * maxAmountFactor/1e4`
        uint32 maxAmountFactor;
    }

    // Terms of deposit(s)
    struct TermSheet {
        // Remaining number of deposits allowed under this term sheet
        // (if set to zero, deposits disabled; 255 - no limitations applied)
        uint8 availableQty;
        // ID of the ERC-20 token to deposit
        uint8 inTokenId;
        // ID of the ERC-721 token (contract) to deposit
        // (if set to 0, no ERC-721 token is required to be deposited)
        uint8 nfTokenId;
        // ID of the ERC-20 token to return instead of the deposited token
        uint8 outTokenId;
        // Maximum amount that may be withdrawn before the deposit period ends,
        // in 1/255 shares of the deposit amount.
        // The amount linearly increases from zero to this value with time.
        // (if set to zero, early withdrawals are disabled)
        uint8 earlyRepayableShare;
        // Fees on early withdrawal, in 1/255 shares of the amount withdrawn
        // (fees linearly decline to zero towards the repayment time)
        // (if set to zero, no fees charged)
        uint8 earlyWithdrawFees;
        // ID of the deposit amount limit (equals to: index in `_limits` + 1)
        // (if set to 0, no limitations on the amount applied)
        uint16 limitId;
        // Deposit period in hours
        uint16 depositHours;
        // Min time between interim (early) withdrawals
        // (if set to 0, no limits on interim withdrawal time)
        uint16 minInterimHours;
        // Rate to compute the "repay" amount, scaled by 1e+9 (see (1))
        uint64 rate;
        // Bit-mask for NFT IDs (in the range 1..64) allowed to deposit
        // (if set to 0, no limitations on NFT IDs applied)
        uint64 allowedNftNumBitMask;
    }

    // Parameters of a deposit
    struct Deposit {
        uint176 amountDue;      // Amount due, in "repay" token units
        uint32 maturityTime;    // Time the final withdrawal is allowed since
        uint32 lastWithdrawTime;// Time of the most recent interim withdrawal
        uint16 lockedShare;     // in 1/65535 shares of `amountDue` (see (2))
        // Note:
        // - the depositor account and the deposit ID linked via mappings
        // - other props (eg.: `termsId`) encoded within the ID of a deposit
    }

    // Deposits of a user
    struct UserDeposits {
        // Set of (unique) deposit IDs
        uint256[] ids;
        // Mapping from deposit ID to deposit data
        mapping(uint256 => Deposit) data;
    }

    // Number of deposits made so far
    uint32 public depositQty;

    // Account that controls the tokens deposited
    address public treasury;

    // Limits on "deposit" token amount
    Limit[] private _limits;

    // Info on each TermSheet
    TermSheet[] internal _termSheets;

    // Mappings from a "repay" token ID to the total amount due
    mapping(uint256 => uint256) public totalDue; // in "repay" token units

    // Mapping from user account to user deposits
    mapping(address => UserDeposits) internal _deposits;

    event NewDeposit(
        uint256 indexed inTokenId,
        uint256 indexed outTokenId,
        address indexed user,
        uint256 depositId,
        uint256 termsId,
        uint256 amount, // amount deposited (in deposit token units)
        uint256 amountDue, // amount to be returned (in "repay" token units)
        uint256 maturityTime // UNIX-time when the deposit is unlocked
    );

    // User withdraws the deposit
    event Withdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount // amount sent to user (in deposit token units)
    );

    event InterimWithdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount, // amount sent to user (in "repay" token units)
        uint256 fees // withheld fees (in "repay" token units)
    );

    // termsId is the index in the `_termSheets` array + 1
    event NewTermSheet(uint256 indexed termsId);
    event TermsEnabled(uint256 indexed termsId);
    event TermsDisabled(uint256 indexed termsId);

    constructor(address _treasury) public {
        _setTreasury(_treasury);
    }

    function depositIds(
        address user
    ) external view returns (uint256[] memory) {
        _revertZeroAddress(user);
        UserDeposits storage userDeposits = _deposits[user];
        return userDeposits.ids;
    }

    function depositData(
        address user,
        uint256 depositId
    ) external view returns(uint256 termsId, Deposit memory params) {
        params = _deposits[_nonZeroAddr(user)].data[depositId];
        termsId = 0;
        if (params.maturityTime !=0) {
            (termsId, , , ) = _decodeDepositId(depositId);
        }
    }

    function termSheet(
        uint256 termsId
    ) external view returns (TermSheet memory) {
        return _termSheets[_validTermsID(termsId) - 1];
    }

    function termSheetsNum() external view returns (uint256) {
        return _termSheets.length;
    }

    function allTermSheets() external view returns(TermSheet[] memory) {
        return _termSheets;
    }

    function depositLimit(
        uint256 limitId
    ) external view returns (Limit memory) {
        return _limits[_validLimitID(limitId) - 1];
    }

    function depositLimitsNum() external view returns (uint256) {
        return _limits.length;
    }

    function getTokenData(
        uint256 tokenId
    ) external view returns(address, TokenType, uint8 decimals) {
        return _token(uint8(tokenId));
    }

    function isAcceptableNft(
        uint256 termsId,
        address nftContract,
        uint256 nftId
    ) external view returns(bool) {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        if (tS.nfTokenId != 0 && _tokenAddr(tS.nfTokenId) == nftContract) {
            return _isAllowedNftId(nftId, tS.allowedNftNumBitMask);
        }
        return false;
    }

    function idsToBitmask(
        uint256[] memory ids
    ) pure external returns(uint256 bitmask) {
        bitmask = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(id != 0 && id <= 64, "KDecks:unsupported NFT ID");
            bitmask = bitmask | (id == 1 ? 1 : 2 << (id - 2));
        }
    }

    function computeEarlyWithdrawal(
        address user,
        uint256 depositId
    ) external view returns (uint256 amountToUser, uint256 fees) {
        Deposit memory _deposit = _deposits[user].data[depositId];
        require(_deposit.amountDue != 0, "KDecks:unknown or repaid deposit");

        (uint256 termsId, , , ) = _decodeDepositId(depositId);
        TermSheet memory tS = _termSheets[termsId - 1];

        (amountToUser, fees, ) = _computeEarlyWithdrawal(_deposit, tS, now);
    }

    function deposit(
        uint256 termsId,    // term sheet ID
        uint256 amount,     // amount in deposit token units
        uint256 nftId       // ID of the NFT instance (0 if no NFT required)
    ) public nonReentrant {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        require(tS.availableQty != 0, "KDecks:terms disabled or unknown");

        if (tS.availableQty != 255) {
            _termSheets[termsId - 1].availableQty = --tS.availableQty;
            if ( tS.availableQty == 0) emit TermsDisabled(termsId);
        }

        if (tS.limitId != 0) {
            Limit memory l = _limits[tS.limitId - 1];
            require(amount >= l.minAmount, "KDecks:too small deposit amount");
            if (l.maxAmountFactor != 0) {
                require(
                    amount <=
                        uint256(l.minAmount).mul(l.maxAmountFactor) / 1e4,
                    "KDecks:too big deposit amount"
                );
            }
        }

        uint256 serialNum = depositQty + 1;
        depositQty = uint32(serialNum); // overflow risk ignored

        uint256 depositId = _encodeDepositId(
            serialNum,
            termsId,
            tS.outTokenId,
            tS.nfTokenId,
            nftId
        );

        address tokenIn;
        uint256 amountDue;
        {
            uint8 decimalsIn;
            (tokenIn,, decimalsIn) = _token(tS.inTokenId);
            (,, uint8 decimalsOut) = _token(tS.outTokenId);
            amountDue = _amountOut(amount, tS.rate, decimalsIn, decimalsOut);
        }

        require(amountDue < 2**178, "KDecks:O2");
        uint32 maturityTime = safe32(now.add(uint256(tS.depositHours) *3600));

        if (tS.nfTokenId == 0) {
            require(nftId == 0, "KDecks:unexpected non-zero nftId");
        } else {
            require(
                nftId < 2**16 &&
                _isAllowedNftId(nftId, tS.allowedNftNumBitMask),
                "KDecks:disallowed NFT instance"
            );
            IERC721(_tokenAddr(tS.nfTokenId))
                .safeTransferFrom(msg.sender, address(this), nftId, _NFT_PASS);
        }

        IERC20(tokenIn).safeTransferFrom(msg.sender, treasury, amount);

        // inverted and re-scaled from 255 to 65535
        uint256 lockedShare = uint(255 - tS.earlyRepayableShare) * 65535/255;
        _registerDeposit(
            _deposits[msg.sender],
            depositId,
            Deposit(
                uint176(amountDue),
                maturityTime,
                safe32(now),
                uint16(lockedShare)
            )
        );
        totalDue[tS.outTokenId] = totalDue[tS.outTokenId].add(amountDue);

        emit NewDeposit(
            tS.inTokenId,
            tS.outTokenId,
            msg.sender,
            depositId,
            termsId,
            amount,
            amountDue,
            maturityTime
        );
    }

    // Entirely withdraw the deposit (when the deposit period ends)
    function withdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, false);
    }

    // Early withdrawal of the unlocked "repay" token amount (beware of fees!!)
    function interimWithdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, true);
    }

    function addTerms(TermSheet[] memory termSheets) public onlyOwner {
        for (uint256 i = 0; i < termSheets.length; i++) {
            _addTermSheet(termSheets[i]);
        }
    }

    function updateAvailableQty(
        uint256 termsId,
        uint256 newQty
    ) external onlyOwner {
        require(newQty <= 255, "KDecks:INVALID_availableQty");
        _termSheets[_validTermsID(termsId) - 1].availableQty = uint8(newQty);
        if (newQty == 0) {
            emit TermsDisabled(termsId);
        } else {
            emit TermsEnabled(termsId);
        }
    }

    function addLimits(Limit[] memory limits) public onlyOwner {
        // Risk of `limitId` (16 bits) overflow ignored
        for (uint256 i = 0; i < limits.length; i++) {
            _addLimit(limits[i]);
        }
    }

    function addTokens(
        address[] memory addresses,
        TokenType[] memory types,
        uint8[] memory decimals
    ) external onlyOwner {
        _addTokens(addresses, types, decimals);
    }

    function setTreasury(address _treasury) public onlyOwner {
        _setTreasury(_treasury);
    }

    // Save occasional airdrop or mistakenly transferred tokens
    function transferFromContract(IERC20 token, uint256 amount, address to)
        external
        onlyOwner
    {
        _revertZeroAddress(to);
        token.safeTransfer(to, amount);
    }

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    // Equals to `bytes4(keccak256("KingDecks"))`
    bytes private constant _NFT_PASS = abi.encodePacked(bytes4(0xb0e68bdd));

    // Implementation of the ERC721 Receiver
    function onERC721Received(address, address, uint256, bytes calldata data)
        external
        pure
        returns (bytes4)
    {
        // Only accept transfers with _NFT_PASS passed as `data`
        return (data.length == 4 && data[0] == 0xb0 && data[3] == 0xdd)
        ? _ERC721_RECEIVED
        : bytes4(0);
    }

    // Other parameters, except `serialNum`, encoded for gas saving & UI sake
    function _encodeDepositId(
        uint256 serialNum,  // Incremental num, unique for every deposit
        uint256 termsId,    // ID of the applicable term sheet
        uint256 outTokenId, // ID of the ERC-20 token to repay deposit in
        uint256 nfTokenId,  // ID of the deposited ERC-721 token (contract)
        uint256 nftId       // ID of the deposited ERC-721 token instance
    ) internal pure returns (uint256 depositId) {
        depositId = nftId
        | (nfTokenId << 16)
        | (outTokenId << 24)
        | (termsId << 32)
        | (serialNum << 48);
    }

    function _decodeDepositId(uint256 depositId) internal pure
    returns (
        uint16 termsId,
        uint8 outTokenId,
        uint8 nfTokenId,
        uint16 nftId
    ) {
        termsId = uint16(depositId >> 32);
        outTokenId = uint8(depositId >> 24);
        nfTokenId = uint8(depositId >> 16);
        nftId = uint16(depositId);
    }

    function _withdraw(uint256 depositId, bool isInterim) internal {
        UserDeposits storage userDeposits = _deposits[msg.sender];
        Deposit memory _deposit = userDeposits.data[depositId];

        require(_deposit.amountDue != 0, "KDecks:unknown or repaid deposit");

        uint256 amountToUser;
        uint256 amountDue = 0;
        uint256 fees = 0;

        (
            uint16 termsId,
            uint8 outTokenId,
            uint8 nfTokenId,
            uint16 nftId
        ) = _decodeDepositId(depositId);

        if (isInterim) {
            TermSheet memory tS = _termSheets[termsId - 1];
            require(
                now >= uint256(_deposit.lastWithdrawTime) + tS.minInterimHours * 3600,
                "KDecks:withdrawal not yet allowed"
            );

            uint256 lockedShare;
            (amountToUser, fees, lockedShare) = _computeEarlyWithdrawal(
                _deposit,
                tS,
                now
            );
            amountDue = uint256(_deposit.amountDue).sub(amountToUser).sub(fees);
            _deposit.lockedShare = uint16(lockedShare);

            emit InterimWithdraw(msg.sender, depositId, amountToUser, fees);
        } else {
            require(now >= _deposit.maturityTime, "KDecks:deposit is locked");
            amountToUser = uint256(_deposit.amountDue);

            if (nftId != 0) {
                IERC721(_tokenAddr(nfTokenId)).safeTransferFrom(
                    address(this),
                    msg.sender,
                    nftId,
                    _NFT_PASS
                );
            }
            _deregisterDeposit(userDeposits, depositId);

            emit Withdraw(msg.sender, depositId, amountToUser);
        }

        _deposit.lastWithdrawTime = safe32(now);
        _deposit.amountDue = uint176(amountDue);
        userDeposits.data[depositId] = _deposit;

        totalDue[outTokenId] = totalDue[outTokenId]
            .sub(amountToUser)
            .sub(fees);

        IERC20(_tokenAddr(outTokenId))
            .safeTransferFrom(treasury, msg.sender, amountToUser);
    }

    function _computeEarlyWithdrawal(
        Deposit memory d,
        TermSheet memory tS,
        uint256 timeNow
    ) internal pure returns (
        uint256 amountToUser,
        uint256 fees,
        uint256 newlockedShare
    ) {
        require(d.lockedShare != 65535, "KDecks:early withdrawals banned");

        amountToUser = 0;
        fees = 0;
        newlockedShare = 0;

        if (timeNow > d.lastWithdrawTime && timeNow < d.maturityTime) {
            // values are too small for overflow; if not, safemath used
            {
                uint256 timeSincePrev = timeNow - d.lastWithdrawTime;
                uint256 timeLeftPrev = d.maturityTime - d.lastWithdrawTime;
                uint256 repayable = uint256(d.amountDue)
                    .mul(65535 - d.lockedShare)
                    / 65535;

                amountToUser = repayable.mul(timeSincePrev).div(timeLeftPrev);
                newlockedShare = uint256(65535).sub(
                    repayable.sub(amountToUser)
                    .mul(65535)
                    .div(uint256(d.amountDue).sub(amountToUser))
                );
            }
            {
                uint256 term = uint256(tS.depositHours) * 3600; // can't be 0
                uint256 timeLeft = d.maturityTime - timeNow;
                fees = amountToUser
                    .mul(uint256(tS.earlyWithdrawFees))
                    .mul(timeLeft)
                    / term // fee rate linearly drops to 0
                    / 255; // `earlyWithdrawFees` scaled down

            }
            amountToUser = amountToUser.sub(fees); // fees withheld
        }
    }

    function _amountOut(
        uint256 amount,
        uint64 rate,
        uint8 decIn,
        uint8 decOut
    ) internal pure returns(uint256 out) {
        if (decOut > decIn + 9) { // rate is scaled (multiplied) by 1e9
            out = amount.mul(rate).mul(10 ** uint256(decOut - decIn - 9));
        } else {
            out = amount.mul(rate).div(10 ** uint256(decIn + 9 - decOut));
        }
        return out;
    }

    function _addTermSheet(TermSheet memory tS) internal {
        (, TokenType _type,) = _token(tS.inTokenId);
        require(_type == TokenType.Erc20, "KDecks:INVALID_DEPOSIT_TOKEN");
        (, _type,) = _token(tS.outTokenId);
        require(_type == TokenType.Erc20, "KDecks:INVALID_REPAY_TOKEN");
        if (tS.nfTokenId != 0) {
            (, _type,) = _token(tS.nfTokenId);
            require(_type == TokenType.Erc721, "KDecks:INVALID_NFT_TOKEN");
        }
        if (tS.earlyRepayableShare == 0) {
            require(
                tS.earlyWithdrawFees == 0 && tS.minInterimHours == 0,
                "KDecks:INCONSISTENT_PARAMS"
            );
        }

        if (tS.limitId != 0) _validLimitID(tS.limitId);
        require(
             tS.depositHours != 0 && tS.rate != 0,
            "KDecks:INVALID_ZERO_PARAM"
        );

        // Risk of termsId (16 bits) overflow ignored
        _termSheets.push(tS);

        emit NewTermSheet(_termSheets.length);
        if (tS.availableQty != 0 ) emit TermsEnabled(_termSheets.length);
    }

    function _addLimit(Limit memory l) internal {
        require(l.minAmount != 0, "KDecks:INVALID_minAmount");
        _limits.push(l);
    }

    function _isAllowedNftId(
        uint256 nftId,
        uint256 allowedBitMask
    ) internal pure returns(bool) {
        if (allowedBitMask == 0) return true;
        uint256 idBitMask = nftId == 1 ? 1 : (2 << (nftId - 2));
        return (allowedBitMask & idBitMask) != 0;
    }

    function _registerDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId,
        Deposit memory _deposit
    ) internal {
        userDeposits.data[depositId] = _deposit;
        userDeposits.ids.push(depositId);
    }

    function _deregisterDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId
    ) internal {
        _removeArrayElement(userDeposits.ids, depositId);
    }

    // Assuming the given array does contain the given element
    function _removeArrayElement(uint256[] storage arr, uint256 el) internal {
        uint256 lastIndex = arr.length - 1;
        if (lastIndex != 0) {
            uint256 replaced = arr[lastIndex];
            if (replaced != el) {
                // Shift elements until the one being removed is replaced
                do {
                    uint256 replacing = replaced;
                    replaced = arr[lastIndex - 1];
                    lastIndex--;
                    arr[lastIndex] = replacing;
                } while (replaced != el && lastIndex != 0);
            }
        }
        // Remove the last (and quite probably the only) element
        arr.pop();
    }

    function _setTreasury(address _treasury) internal {
        _revertZeroAddress(_treasury);
        treasury = _treasury;
    }

    function _revertZeroAddress(address _address) private pure {
        require(_address != address(0), "KDecks:ZERO_ADDRESS");
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function _validTermsID(uint256 termsId) private view returns (uint256) {
        require(
            termsId != 0 && termsId <= _termSheets.length,
            "KDecks:INVALID_TERMS_ID"
        );
        return termsId;
    }

    function _validLimitID(uint256 limitId) private view returns (uint256) {
        require(
            limitId != 0 && limitId <= _limits.length,
            "KDecks:INVALID_LIMITS_ID"
        );
        return limitId;
    }

    function safe32(uint256 n) private pure returns (uint32) {
        require(n < 2**32, "KDecks:UNSAFE_UINT32");
        return uint32(n);
    }
}
