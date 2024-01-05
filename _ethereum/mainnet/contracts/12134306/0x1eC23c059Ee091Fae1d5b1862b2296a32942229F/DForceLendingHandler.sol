pragma solidity 0.5.12;

contract DSAuthority {
    function canCall(
        address src,
        address dst,
        bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority(address indexed authority);
    event LogSetOwner(address indexed owner);
    event OwnerUpdate(address indexed owner, address indexed newOwner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority public authority;
    address public owner;
    address public newOwner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    // Warning: you should absolutely sure you want to give up authority!!!
    function disableOwnership() public onlyOwner {
        owner = address(0);
        emit OwnerUpdate(msg.sender, owner);
    }

    function transferOwnership(address newOwner_) public onlyOwner {
        require(newOwner_ != owner, "TransferOwnership: the same owner.");
        newOwner = newOwner_;
    }

    function acceptOwnership() public {
        require(
            msg.sender == newOwner,
            "AcceptOwnership: only new owner do this."
        );
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    ///[snow] guard is Authority who inherit DSAuth.
    function setAuthority(DSAuthority authority_) public onlyOwner {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier onlyOwner {
        require(isOwner(msg.sender), "ds-auth-non-owner");
        _;
    }

    function isOwner(address src) internal view returns (bool) {
        return bool(src == owner);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig)
        internal
        view
        returns (bool)
    {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by owner account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is DSAuth {
    bool public paused;

    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused, "whenPaused: not paused");
        _;
    }

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor() internal {
        paused = false;
    }

    /**
     * @dev Called by the contract owner to pause, triggers stopped state.
     */
    function pause() public whenNotPaused auth {
        paused = true;
        emit Paused(owner);
    }

    /**
     * @dev Called by the contract owner to unpause, returns to normal state.
     */
    function unpause() public whenPaused auth {
        paused = false;
        emit Unpaused(owner);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // This function is not a standard ERC20 interface, just for compitable with market.
    function decimals() external view returns (uint8);
}

contract ERC20SafeTransfer {
    function doTransferOut(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transfer(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.transferFrom(_from, _to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }

    function doApprove(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        IERC20 token = IERC20(_token);
        bool result;

        token.approve(_to, _amount);

        assembly {
            switch returndatasize()
                case 0 {
                    result := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    result := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        return result;
    }
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "ds-math-div-overflow");
        z = x / y;
    }
}

interface IDTokenController {
    function getDToken(address _token) external view returns (address);
}

contract Handler is ERC20SafeTransfer, Pausable {
    using SafeMath for uint256;
    bool private initialized; // Flags for initializing data
    address public dTokenController; // dToken mapping contract

    mapping(address => bool) private tokensEnable; // Supports token or not

    event NewdTokenAddresses(
        address indexed originalDToken,
        address indexed newDToken
    );
    event DisableToken(address indexed underlyingToken);
    event EnableToken(address indexed underlyingToken);

    // --- Init ---
    // This function is used with contract proxy, do not modify this function.
    function initialize(address _dTokenController) public {
        require(!initialized, "initialize: Already initialized!");
        owner = msg.sender;
        dTokenController = _dTokenController;
        initialized = true;
    }

    /**
     * @dev Update dToken mapping contract.
     * @param _newDTokenController The new dToken mapping contact.
     */
    function setDTokenController(address _newDTokenController) external auth {
        require(
            _newDTokenController != dTokenController,
            "setDTokenController: The same dToken mapping contract address!"
        );
        address _originalDTokenController = dTokenController;
        dTokenController = _newDTokenController;
        emit NewdTokenAddresses(
            _originalDTokenController,
            _newDTokenController
        );
    }

    /**
     * @dev Authorized function to disable some underlying tokens.
     * @param _underlyingTokens Tokens to disable.
     */
    function disableTokens(address[] calldata _underlyingTokens) external auth {
        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            _disableToken(_underlyingTokens[i]);
        }
    }

    /**
     * @dev Authorized function to enable some underlying tokens.
     * @param _underlyingTokens Tokens to enable.
     */
    function enableTokens(address[] calldata _underlyingTokens) external auth {
        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            _enableToken(_underlyingTokens[i]);
        }
    }

    function _disableToken(address _underlyingToken) internal {
        require(
            tokensEnable[_underlyingToken],
            "disableToken: Has been disabled!"
        );
        tokensEnable[_underlyingToken] = false;
        emit DisableToken(_underlyingToken);
    }

    function _enableToken(address _underlyingToken) internal {
        require(
            !tokensEnable[_underlyingToken],
            "enableToken: Has been enabled!"
        );
        tokensEnable[_underlyingToken] = true;
        emit EnableToken(_underlyingToken);
    }

    /**
     * @dev The _underlyingToken approves to dToken contract.
     * @param _underlyingToken Token address to approve.
     */
    function approve(address _underlyingToken, uint256 amount) public auth {
        address _dToken = IDTokenController(dTokenController).getDToken(
            _underlyingToken
        );

        require(
            doApprove(_underlyingToken, _dToken, amount),
            "approve: Approve dToken failed!"
        );
    }

    /**
     * @dev Support token or not.
     * @param _underlyingToken Token to check.
     */
    function tokenIsEnabled(address _underlyingToken)
        public
        view
        returns (bool)
    {
        return tokensEnable[_underlyingToken];
    }
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    function initReentrancyStatus() internal {
        _status = _NOT_ENTERED;
    }
}

interface IController {
    function hasiToken(address _iToken) external view returns (bool);
    function rewardDistributor() external view returns (IRewardDistributor);
}

interface IRewardDistributor {
    function claimAllReward(address[] calldata _holders) external;
    function claimReward(address[] calldata _holders, address[] calldata _iTokens) external;

    function rewardToken() external view returns (address);
}

interface IiToken {
    function mint(address _recipient, uint256 _mintAmount) external;

    function redeem(address _from, uint256 _redeemiToken) external;

    function redeemUnderlying(address _from, uint256 _redeemUnderlying) external;

    function balanceOfUnderlying(address _account) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function controller() external view returns (IController);

    function underlying() external view returns (address);

    function isiToken() external view returns (bool);
}

contract DForceLendingHandler is Handler, ReentrancyGuard {
    uint256 constant BASE = 10**18;

    struct InterestDetails {
        uint256 totalUnderlyingBalance; // Total underlying balance including interest
        uint256 interest; // Total interest
    }
    // Based on underlying token, get current interest details
    mapping(address => InterestDetails) public interestDetails;

    mapping(address => address) public iTokens; //iTokens;

    address public rewardToken;

    event NewMappingiToken(
        address indexed token,
        address indexed mappingiToken
    );

    event RewardClaimed(
        address indexed underlying,
        uint256 indexed rewardBalance
    );

    constructor(address _dTokenController, address _rewardToken) public {
        initialize(_dTokenController, _rewardToken);
    }

    // --- Init ---
    // This function is used with contract proxy, do not modify this function.
    function initialize(address _dTokenController, address _rewardToken)
        public
    {
        super.initialize(_dTokenController);
        rewardToken = _rewardToken;
        initReentrancyStatus();
    }

    /**
     * @dev Authorized function to set iToken address base on underlying token.
     * @param _underlyingTokens Supports underlying tokens in DForce lending.
     * @param _mappingTokens  Corresponding iToken addresses.
     */
    function setiTokensRelation(
        address[] calldata _underlyingTokens,
        address[] calldata _mappingTokens
    ) external auth {
        require(
            _underlyingTokens.length == _mappingTokens.length,
            "setTokensRelation: Array length do not match!"
        );
        for (uint256 i = 0; i < _underlyingTokens.length; i++) {
            _setiTokenRelation(_underlyingTokens[i], _mappingTokens[i]);
        }
    }

    function _setiTokenRelation(
        address _underlyingToken,
        address _mappingiToken
    ) internal {
        iTokens[_underlyingToken] = _mappingiToken;
        emit NewMappingiToken(_underlyingToken, _mappingiToken);
    }

    /**
     * @dev Authorized function to approves market and dToken to transfer handler's underlying token.
     * @param _underlyingToken Token address to approve.
     */
    function approve(address _underlyingToken, uint256 amount) public auth {
        address _iToken = iTokens[_underlyingToken];

        require(
            doApprove(_underlyingToken, _iToken, amount),
            "approve: Approve cToken failed!"
        );

        super.approve(_underlyingToken, amount);
    }

    /**
     * @dev Internal function to transfer rewardToken airdrops to corresponding dToken to distribute.
     */
    function claimReward(address _underlyingToken) external {
        require(
            tokenIsEnabled(_underlyingToken),
            "claimReward: Token is disabled!"
        );
        address _iToken = iTokens[_underlyingToken];
        require(_iToken != address(0x0), "claimReward: Do not support token!");

        address[] memory _holders = new address[](1);
        address[] memory _iTokens = new address[](1);
        _holders[0] = address(this);
        _iTokens[0] = _iToken;
        IiToken(_iToken).controller().rewardDistributor().claimReward(_holders, _iTokens);

        address _rewardToken = rewardToken;
        uint256 _rewardBalance = IERC20(_rewardToken).balanceOf(_holders[0]);
        if (_rewardBalance > 0) {
            address _dToken = IDTokenController(dTokenController).getDToken(_underlyingToken);
            require(
                doTransferOut(_rewardToken, _dToken, _rewardBalance),
                "deposit: Comp transfer out of contract failed."
            );
            emit RewardClaimed(_dToken, _rewardBalance);
        }
    }

    /**
     * @dev Deposit token to market, only called by dToken contract.
     * @param _underlyingToken Token to deposit.
     * @return The actual deposited token amount.
     */
    function deposit(address _underlyingToken, uint256 _amount)
        external
        whenNotPaused
        auth
        nonReentrant
        returns (uint256)
    {
        require(
            tokenIsEnabled(_underlyingToken),
            "deposit: Token is disabled!"
        );
        require(
            _amount > 0,
            "deposit: Deposit amount should be greater than 0!"
        );

        address _iToken = iTokens[_underlyingToken];
        require(_iToken != address(0x0), "deposit: Do not support token!");

        uint256 _MarketBalanceBefore = IiToken(_iToken).balanceOfUnderlying(
            address(this)
        );

        // Update the stored interest with the market balance before the mint
        InterestDetails storage _details = interestDetails[_underlyingToken];
        uint256 _interest = _MarketBalanceBefore.sub(
            _details.totalUnderlyingBalance
        );
        _details.interest = _details.interest.add(_interest);

        // Mint all the token balance of the handler,
        // which should be the exact deposit amount normally,
        // but there could be some unexpected transfers before.
        uint256 _handlerBalance = IERC20(_underlyingToken).balanceOf(
            address(this)
        );
        IiToken(_iToken).mint(address(this), _handlerBalance);

        // claimComp(_underlyingToken);

        // including unexpected transfers.
        uint256 _MarketBalanceAfter = IiToken(_iToken).balanceOfUnderlying(
            address(this)
        );

        // Store the latest real balance.
        _details.totalUnderlyingBalance = _MarketBalanceAfter;

        uint256 _changedAmount = _MarketBalanceAfter.sub(_MarketBalanceBefore);

        // Return the smaller value as unexpected transfers were also included.
        return _changedAmount > _amount ? _amount : _changedAmount;
    }

    /**
     * @dev Withdraw token from market, but only for dToken contract.
     * @param _underlyingToken Token to withdraw.
     * @param _amount Token amount to withdraw.
     * @return The actual withdrown token amount.
     */
    function withdraw(address _underlyingToken, uint256 _amount)
        external
        whenNotPaused
        auth
        nonReentrant
        returns (uint256)
    {
        require(
            _amount > 0,
            "withdraw: Withdraw amount should be greater than 0!"
        );

        address _iToken = iTokens[_underlyingToken];
        require(_iToken != address(0x0), "withdraw: Do not support token!");

        uint256 _MarketBalanceBefore = IiToken(_iToken).balanceOfUnderlying(
            address(this)
        );

        // Update the stored interest with the market balance before the redeem
        InterestDetails storage _details = interestDetails[_underlyingToken];
        uint256 _interest = _MarketBalanceBefore.sub(
            _details.totalUnderlyingBalance
        );
        _details.interest = _details.interest.add(_interest);

        uint256 _handlerBalanceBefore = IERC20(_underlyingToken).balanceOf(
            address(this)
        );

        // Redeem all or just the amount of underlying token
        if (_amount == uint256(-1)) {
            IiToken(_iToken).redeem(address(this), IERC20(_iToken).balanceOf(address(this)));
        } else {
            IiToken(_iToken).redeemUnderlying(address(this), _amount);
        }

        // claimComp(_underlyingToken);

        uint256 _handlerBalanceAfter = IERC20(_underlyingToken).balanceOf(
            address(this)
        );

        // Store the latest real balance.
        _details.totalUnderlyingBalance = IiToken(_iToken)
            .balanceOfUnderlying(address(this));

        uint256 _changedAmount = _handlerBalanceAfter.sub(
            _handlerBalanceBefore
        );

        // return a smaller value.
        return _changedAmount > _amount ? _amount : _changedAmount;
    }

    /**
     * @dev Update exchange rate in cToken and get the latest total balance for
     *      handler's _underlyingToken, with all accumulated interest included.
     * @param _underlyingToken Token to get actual balance.
     */
    function getRealBalance(address _underlyingToken)
        external
        returns (uint256)
    {
        return
            IiToken(iTokens[_underlyingToken]).balanceOfUnderlying(
                address(this)
            );
    }

    /**
     * @dev The latest maximum withdrawable _underlyingToken in the market.
     * @param _underlyingToken Token to get liquidity.
     */
    function getRealLiquidity(address _underlyingToken)
        external
        returns (uint256)
    {
        address _iToken = iTokens[_underlyingToken];
        uint256 _underlyingBalance = IiToken(_iToken).balanceOfUnderlying(
            address(this)
        );
        uint256 _cash = IiToken(_iToken).getCash();

        return _underlyingBalance > _cash ? _cash : _underlyingBalance;
    }

    /***************************************************/
    /*** View Interfaces For Backwards compatibility ***/
    /***************************************************/

    /**
     * @dev Total balance of handler's _underlyingToken, accumulated interest included
     * @param _underlyingToken Token to get balance.
     */
    function getBalance(address _underlyingToken)
        public
        view
        returns (uint256)
    {
        address _iToken = iTokens[_underlyingToken];
        uint256 _iTokenBalance = IERC20(_iToken).balanceOf(address(this));
        uint256 _exchangeRate = IiToken(_iToken).exchangeRateStored();

        return _iTokenBalance.mul(_exchangeRate) / BASE;
    }

    /**
     * @dev The maximum withdrawable amount of _underlyingToken in the market.
     * @param _underlyingToken Token to get liquidity.
     */
    function getLiquidity(address _underlyingToken)
        external
        view
        returns (uint256)
    {
        address _iToken = iTokens[_underlyingToken];
        uint256 _underlyingBalance = getBalance(_underlyingToken);
        uint256 _cash = IiToken(_iToken).getCash();

        return _underlyingBalance > _cash ? _cash : _underlyingBalance;
    }
}