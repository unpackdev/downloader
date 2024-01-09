// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./PaymentSplitterUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/*
      ▄▄▄▄▄        ▄▄▄▄▄▄ -▄▄▄▄▄▄▄▄▄▄▄⌐ ▄▄▄▄▄▄▄▄▄▄▄▄▄     ▄▄▄▄           ,▄▄▄▄▄,     .▄▄▄▄▄▄▄▄,         ,▄▄∞∞▄,          ▄▄▄▄▄,    .▄▄▄▄▄▄⌐    w▄▄▄  ▄▄▄▄▄▄▄▄▄             ▄▄▄▄▄
       █████      ▐████     ████     ▐▌ █   ▐███▌   █     █████        ▄▀  ▀▀████▄     ████   ███▄    ╓██      ██     ▄▀      ▀█▄▄   ████        ▌    ▐███▌  ▀███▄         ▐████
       █████▌     █████     ████      ▌ `   ▐███▌   ▐     ▌████▄     ,█       ▀████▄   ████   ████▌   ███       █    ██         ██   ████        ▌    ▐███▌   ████▌        █████▌
       █ ████    █ ████     ████      `     ▐███▌        █ ▐████     ██        ▐████µ  ████   ████    ████▄         ██▌          █   ████        ▌    ▐███▌   ████▌       ▐` ████
       █ ▐████  ▐▀ ████     ████   ▐        ▐███▌       ,▌  ████▌   ▐██     ,   ▐████  ████⌐▄██▀       ▀█████▄▄     ██▌          █   ████        ▌    ▐███▌  ▄██▀         █  ▐████
       █  ████▌ ▌  ████     ████""▀█        ▐███▌       █    ████   ████   ^█═   ▐███  ████   ▀███▄      ▀██████▄  ▐███              ████        ▌    ▐███▌▀██▄          █    ████▄
       █   █████   ████     ████            ▐███▌      ▐     ▐████  ▐███▌         ███  ████     ████  ▌     ▀█████▄ ████             ████        ▌    ▐███▌ ████        ╒▌    ▐████
       █   ▐███-   ████     ████      ,     ▐███▌      █`````"████▄  ████▄        ██   ████     ████▌ █        ████ █████            ████        ▌    ▐███▌ ▐███▌       █"`````████▌
       █    ██▌    ████     ████      █     ▐███▌     █       ▐████   █████       █▀   ████     ████  █▄       ▐███  █████▄       ▀  ▐███       ▐-    ▐███▌  ████      ▐-       ████
       █     ▀     ████     ████     ,█     ▐███▌    ▐▌        ████▌   ▀█████▄,,▄▀     ████   ▄███▀   ▌▀▄     ,██▀    ▀█████▄,,▄∞     ▀███     ▄▀     ▐███▌   ███▄     █        ▐████
      ▀▀▀`        ▀▀▀▀▀▀' "▀▀▀▀▀````▀▀▀    "▀▀▀▀▀'  '▀▀       `▀▀▀▀▀▀     ▀▀▀▀▀      `▀▀▀▀▀`"             ▀""▀           ▀▀▀▀▀-          `▀"""`      "▀▀▀▀▀"    ▀▀▀▀ `▀▀`       ▀▀▀▀▀▀`

    “I never am really satisfied that I understand anything; because, 
    understand it well as I may, my comprehension can only be an infinitesimal 
    fraction of all I want to understand about the many connections and 
    relations which occur to me.” Ada Lovelace
*/

/// @title MetaObscuraReceiver
/// @author koloz
/// @notice This contract act as the receiver and claiming interface for MetaObscura.
/// @dev For erc20s sent here we don't keep track explicitly and they're all sent out on withdraw.
contract MetaObscuraReceiver is
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20Upgradeable indexed token,
        address to,
        uint256 amount
    );

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256))
        private _erc20Released;

    address public metaObscuraCreator;

    address public metaObscuraContract;
    uint256 public cameraTokenId;

    modifier onlyStakeHolder() {
        IERC721Upgradeable erc721 = IERC721Upgradeable(metaObscuraContract);
        require(
            _msgSender() == erc721.ownerOf(cameraTokenId) ||
                _msgSender() == metaObscuraCreator,
            "must be stakeholder"
        );
        _;
    }

    function init(
        address _metaObscuraCreator,
        uint256 _creatorCut,
        address _metaObscuraContract,
        uint256 _cameraTokenId,
        uint256 _cameraOwnerCut
    ) public initializer {
        require(_metaObscuraCreator != address(0));
        require(_metaObscuraContract != address(0));

        metaObscuraCreator = _metaObscuraCreator;
        metaObscuraContract = _metaObscuraContract;

        cameraTokenId = _cameraTokenId;

        address[] memory payees = new address[](2);
        payees[0] = _metaObscuraCreator;
        payees[1] = _metaObscuraContract;

        uint256[] memory shares_ = new uint256[](2);
        shares_[0] = _creatorCut;
        shares_[1] = _cameraOwnerCut;

        __Context_init();
        __Ownable_init();

        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    receive() external payable virtual {}

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token)
        public
        view
        returns (uint256)
    {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release() public virtual onlyStakeHolder nonReentrant {
        address account = _msgSender() == metaObscuraCreator
            ? metaObscuraCreator
            : metaObscuraContract;

        address payable receiver = account == metaObscuraCreator
            ? payable(metaObscuraCreator)
            : payable(
                IERC721Upgradeable(metaObscuraContract).ownerOf(cameraTokenId)
            );

        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(receiver, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token)
        public
        virtual
        onlyStakeHolder
        nonReentrant
    {
        address account = _msgSender() == metaObscuraCreator
            ? metaObscuraCreator
            : metaObscuraContract;

        address receiver = account == metaObscuraCreator
            ? metaObscuraCreator
            : IERC721Upgradeable(metaObscuraContract).ownerOf(cameraTokenId);

        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            account,
            totalReceived,
            released(token, account)
        );

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, receiver, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev View computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function pendingPayment(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 alreadyReleased = released(account);

        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev View computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function pendingPayment(address account, IERC20Upgradeable token)
        public
        view
        returns (uint256)
    {
        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 alreadyReleased = released(token, account);

        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    uint256[43] private __gap;
}
