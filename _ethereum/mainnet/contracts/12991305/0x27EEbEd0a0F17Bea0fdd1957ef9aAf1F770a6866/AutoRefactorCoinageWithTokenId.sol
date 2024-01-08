// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IAutoRefactorCoinageWithTokenId.sol";
import "./DSMath.sol";
import "./AccessibleCommon.sol";

/**
 * @dev Implementation of coin age token based on ERC20 of openzeppelin-solidity
 *
 * AutoRefactorCoinageWithTokenId stores `_totalSupply` and `_balances` as RAY BASED value,
 * `_allowances` as RAY FACTORED value.
 *
 * This takes public function (including _approve) parameters as RAY FACTORED value
 * and internal function (including approve) parameters as RAY BASED value, and emits event in RAY FACTORED value.
 *
 * `RAY BASED` = `RAY FACTORED`  / factor
 *
 *  factor increases exponentially for each block mined.
 */
contract AutoRefactorCoinageWithTokenId is
    DSMath,
    AccessibleCommon,
    IAutoRefactorCoinageWithTokenId
{
    struct Balance {
        uint256 balance;
        uint256 refactoredCount;
        uint256 remain;
    }

    // string public _name;
    // string public _symbol;
    uint8 public decimal = 27;
    uint256 public REFACTOR_BOUNDARY = 10**28;
    uint256 public REFACTOR_DIVIDER = 2;

    uint256 public override refactorCount;

    mapping(uint256 => Balance) public balances;

    Balance public _totalSupply;

    uint256 public override _factor;

    bool internal _transfersEnabled;

    event FactorSet(uint256 previous, uint256 current, uint256 shiftCount);

    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "AutoRefactorCoinageWithTokenId:zero address");
        _;
    }
    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "AutoRefactorCoinageWithTokenId:zero address"
        );
        _;
    }

    /// @dev event on mining
    /// @param tokenOwner owner of tokenId
    /// @param tokenId mining tokenId
    /// @param amount  mined amount
    event Mined(
        address indexed tokenOwner,
        uint256 indexed tokenId,
        uint256 amount
    );

    /// @dev event on burn
    /// @param tokenOwner owner of tokenId
    /// @param tokenId mining tokenId
    /// @param amount  mined amount
    event Burned(
        address indexed tokenOwner,
        uint256 indexed tokenId,
        uint256 amount
    );

    constructor(uint256 initfactor) {
        _factor = initfactor;

        //_factorIncrement = factorIncrement;
        //_lastBlock = block.number;
        //_transfersEnabled = transfersEnabled;

        //_setupDecimals(decimal);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function factor() public view override returns (uint256) {
        uint256 result = _factor;
        for (uint256 i = 0; i < refactorCount; i++) {
            result = result * (REFACTOR_DIVIDER);
        }
        return result;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return
            _applyFactor(_totalSupply.balance, _totalSupply.refactoredCount) +
            (_totalSupply.remain);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(uint256 tokenId) public view override returns (uint256) {
        Balance storage b = balances[tokenId];

        return _applyFactor(b.balance, b.refactoredCount) + (b.remain);
    }

    /** @dev Creates `amount` tokens and assigns them to `tokenId`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(
            tokenId != 0,
            "AutoRefactorCoinageWithTokenId: mint to the zero tokenId"
        );
        Balance storage b = balances[tokenId];

        uint256 currentBalance = balanceOf(tokenId);
        uint256 newBalance = currentBalance + amount;

        uint256 rbAmount = _toRAYBased(newBalance);
        b.balance = rbAmount;
        b.refactoredCount = refactorCount;

        addTotalSupply(amount);
        emit Mined(tokenOwner, tokenId, _toRAYFactored(rbAmount));
    }

    /**
     * @dev Destroys `amount` tokens from `tokenId`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `tokenId` cannot be the zero .
     * - `tokenId` must have at least `amount` tokens.
     */
    function _burn(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount
    ) internal {
        require(
            tokenId != 0,
            "AutoRefactorCoinageWithTokenId: burn from the zero tokenId"
        );
        Balance storage b = balances[tokenId];

        uint256 currentBalance = balanceOf(tokenId);
        uint256 newBalance = currentBalance - amount;

        uint256 rbAmount = _toRAYBased(newBalance);
        b.balance = rbAmount;
        b.refactoredCount = refactorCount;

        subTotalSupply(amount);
        emit Burned(tokenOwner, tokenId, _toRAYFactored(rbAmount));
    }

    // helpers

    /**
     * @param v the value to be factored
     */
    function _applyFactor(uint256 v, uint256 refactoredCount)
        internal
        view
        returns (uint256)
    {
        if (v == 0) {
            return 0;
        }

        v = rmul2(v, _factor);

        for (uint256 i = refactoredCount; i < refactorCount; i++) {
            v = v * (REFACTOR_DIVIDER);
        }

        return v;
    }

    /**
     * @dev Calculate RAY BASED from RAY FACTORED
     */
    function _toRAYBased(uint256 rf) internal view returns (uint256 rb) {
        return rdiv2(rf, _factor);
    }

    /**
     * @dev Calculate RAY FACTORED from RAY BASED
     */
    function _toRAYFactored(uint256 rb) internal view returns (uint256 rf) {
        return rmul2(rb, _factor);
    }

    // new

    function setFactor(uint256 infactor)
        external
        override
        onlyOwner
        returns (uint256)
    {
        uint256 previous = _factor;

        uint256 count = 0;
        uint256 f = infactor;
        for (; f >= REFACTOR_BOUNDARY; f = (f / REFACTOR_DIVIDER)) {
            count = count + 1;
        }

        refactorCount = count;
        _factor = f;
        emit FactorSet(previous, f, count);

        return _factor;
    }

    function addTotalSupply(uint256 amount) internal {
        uint256 currentSupply =
            _applyFactor(_totalSupply.balance, _totalSupply.refactoredCount);
        uint256 newSupply = currentSupply + amount;

        uint256 rbAmount = _toRAYBased(newSupply);
        _totalSupply.balance = rbAmount;
        _totalSupply.refactoredCount = refactorCount;
    }

    function subTotalSupply(uint256 amount) internal {
        uint256 currentSupply =
            _applyFactor(_totalSupply.balance, _totalSupply.refactoredCount);
        uint256 newSupply = currentSupply - amount;

        uint256 rbAmount = _toRAYBased(newSupply);
        _totalSupply.balance = rbAmount;
        _totalSupply.refactoredCount = refactorCount;
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount
    )
        public
        override
        onlyOwner
        nonZeroAddress(tokenOwner)
        nonZero(tokenId)
        returns (bool)
    {
        _mint(tokenOwner, tokenId, amount);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(
        address tokenOwner,
        uint256 tokenId,
        uint256 amount
    ) public override onlyOwner {
        require(
            amount <= balanceOf(tokenId),
            "AutoRefactorCoinageWithTokenId: Insufficient balance of token ID"
        );
        if (amount > totalSupply()) _burn(tokenOwner, tokenId, totalSupply());
        else _burn(tokenOwner, tokenId, amount);
    }

    function burnTokenId(address tokenOwner, uint256 tokenId)
        public
        override
        onlyOwner
    {
        uint256 amount = totalSupply();
        if (amount < balanceOf(tokenId)) _burn(tokenOwner, tokenId, amount);
        else _burn(tokenOwner, tokenId, balanceOf(tokenId));
    }

    function balancesTokenId(uint256 tokenId)
        public
        view
        override
        returns (
            uint256 balance,
            uint256 refactoredCount,
            uint256 remain
        )
    {
        return (
            balances[tokenId].balance,
            balances[tokenId].refactoredCount,
            balances[tokenId].remain
        );
    }
}
