//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./IRevenueSplitter.sol";
import "./REMXCollectionFactory.sol";
import "./IREMXCollection.sol";
import "./FreezeableUpgradeable.sol";

import "./AddressUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 *                                                                             _ _ _   _
 *                                                                           | (_) | | |
 *  _ __ ___ _ __ ___ __  __  _ __ _____   _____ _ __  _   _  ___   ___ _ __ | |_| |_| |_ ___ _ __
 * | '__/ _ \ '_ ` _ \\ \/ / | '__/ _ \ \ / / _ \ '_ \| | | |/ _ \ / __| '_ \| | | __| __/ _ \ '__|
 * | | |  __/ | | | | |>  <  | | |  __/\ V /  __/ | | | |_| |  __/ \__ \ |_) | | | |_| ||  __/ |
 * |_|  \___|_| |_| |_/_/\_\ |_|  \___| \_/ \___|_| |_|\__,_|\___| |___/ .__/|_|_|\__|\__\___|_|
 *                                                                     | |
 *                                                                     |_|
 *
 * The RevenueSplitter is the contract that manages revenue sharing between
 * parties involved in REMX NFT collections. The contract is Ether neutral
 * and maintains a balance of Ether destined for particular accounts, and
 * provides various mechanisms to deposit and withdraw funds.
 *
 * It also provides a method for initial purchase of REMX NFTs and supports
 * lazy minting used by REMX NFTs.
 *
 * For safety, a {sweep} method is provided for a priviledged account to send
 * funds out of the contract to an address other than the intended destination,
 * in case the intended recipient is unable to access their account and wishes to
 * receive their funds in a different way.
 *
 * Payee's are expected to withdraw funds from the contract (and pay the gas associated
 * with that transaction).
 *
 * A {payout} method is provided to allow authorized accounts to trigger a payout to
 * an artist and incurring the gas fees, allowing artists who have no Ether balance
 * to receive their funds at a cost to the Payout account.
 */

contract RevenueSplitter is
    IRevenueSplitter,
    Initializable,
    FreezeableUpgradeable,
    ContextUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    //
    REMXCollectionFactory private _collectionFactory;

    // the role of an account authorized to pay funds out of the contract
    bytes32 public constant PAYOUT_ROLE = keccak256("PAYOUT_ROLE");
    bytes32 public constant CREATE_COLLECTION_ROLE =
        keccak256("CREATE_COLLECTION_ROLE");

    // the balance of each payee in wei
    mapping(address => uint256) private _balances;

    // the minimum purchase price for an NFT
    uint256 private constant _minimumAmount = 0 ether;

    struct Collection {
        bool registered;
        uint256 totalShares;
        CollectionPayee[] payees;
    }

    // a single participation in a collection
    struct CollectionPayee {
        address payee;
        uint256 shares;
    }

    // map a collection address to the participants in the revenue sharing for that collection
    mapping(address => Collection) private _collections;

    /**
     * @dev initialize the revenue splitter and set up for access controllable resources
     */
    function initialize(address collectionFactory) external initializer {
        __Ownable_init();
        __Freezeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _collectionFactory = REMXCollectionFactory(collectionFactory);
    }

    /**
     * @dev indicate that the contract conforms to our convention
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IRevenueSplitter).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function createCollection(
        string memory name,
        string memory symbol,
        uint256 royaltyAmount,
        address[] memory _payees,
        uint256[] memory _shares,
        string memory baseURI,
        address minter
    ) external override returns (address) {
        require(
            hasRole(CREATE_COLLECTION_ROLE, _msgSender()) ||
                owner() == _msgSender(),
            "RMX: caller is not owner or collection creator"
        );

        require(bytes(name).length > 5, "RMX: Name too short");
        require(bytes(symbol).length >= 3, "RMX: Symbol too short");
        require(royaltyAmount <= 100, "RMX: Invalid royalty amount");

        address _collection = _collectionFactory.createCollection(
            owner(),
            minter,
            address(this),
            name,
            symbol,
            royaltyAmount,
            baseURI
        );

        _collections[_collection].registered = true;
        _collections[_collection].totalShares = 0;

        emit CreateCollectionEvent(address(_collection));

        _addCollectionPayees(address(_collection), _payees, _shares);

        return address(_collection);
    }

    /**
     * @dev returns a boolean indicating if a particular contract address is registered
     */
    function isRegistered(address _collection) external view returns (bool) {
        return _collections[_collection].registered;
    }

    /**
     * @dev register multiple payees in a single transaction, useful for reducing gas
     * when creating a collection and first initializing it
     */
    function addCollectionPayees(
        address _collection,
        address[] memory _payees,
        uint256[] memory _shares
    ) external override {
        _addCollectionPayees(_collection, _payees, _shares);
    }

    function _addCollectionPayees(
        address _collection,
        address[] memory _payees,
        uint256[] memory _shares
    ) internal {
        require(
            hasRole(CREATE_COLLECTION_ROLE, _msgSender()) ||
                owner() == _msgSender(),
            "RMX: caller is not owner or collection creator"
        );
        require(_payees.length == _shares.length, "RMX: invalid array length");

        for (uint i = 0; i < _payees.length; i++) {
            _addCollectionPayee(_collection, _payees[i], _shares[i]);
        }
    }

    /**
     * @dev register a payee to receive a certain percentage of a given NFT collection's revenue.
     *
     * Emits an {AddPayeeEvent}
     */
    function addCollectionPayee(
        address _collection,
        address _payee,
        uint256 shares
    ) external override {
        _addCollectionPayee(_collection, _payee, shares);
    }

    function _addCollectionPayee(
        address _collection,
        address _payee,
        uint256 shares
    ) internal isNotFrozen(_payee) {
        require(
            hasRole(CREATE_COLLECTION_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "RMX: caller is not owner or collection creator"
        );

        require(_payee != address(0), "RMX: payee is zero address");
        require(
            _collections[_collection].registered,
            "RMX: Unknown collection"
        );
        require(shares > 0, "RMX: shares are 0");
        for (uint i = 0; i < _collections[_collection].payees.length; i++) {
            require(
                _collections[_collection].payees[i].payee != _payee,
                "RMX: Payee already registered"
            );
        }
        _collections[_collection].payees.push(CollectionPayee(_payee, shares));
        _collections[_collection].totalShares += shares;

        emit AddPayeeEvent(_collection, _payee, shares);
    }

    function removeCollectionPayee(address _collection, address _payee)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_payee != address(0), "RMX: payee is zero address");
        require(
            _collections[_collection].registered,
            "RMX: Unknown collection"
        );

        CollectionPayee memory payee = CollectionPayee(address(0), 0);
        for (uint i = 0; i < _collections[_collection].payees.length; i++) {
            if (_collections[_collection].payees[i].payee == _payee) {
                payee = _collections[_collection].payees[i];
                // copy last element of array over matched element then pop last element
                // pop() shortens the array length
                // this approach only works if we don't care about ordering
                // if we care about order then we can copy every element from `payee` down one, then pop
                _collections[_collection].payees[i] = _collections[_collection]
                    .payees[_collections[_collection].payees.length - 1];
                _collections[_collection].payees.pop();
            }
        }
        require(payee.payee != address(0), "RMX: payee not found");
        _collections[_collection].totalShares -= payee.shares;

        emit RemovePayeeEvent(_collection, _payee);
    }

    /**
     * @dev facilitates the purchase of an NFT from a collection.  Receives the funds
     * and internally distributes the revenue.
     *
     * Emits a {BuyEvent}
     */
    function buyNFT(
        address payable _collection,
        uint256 tokenId,
        uint256 expiryBlock,
        bytes calldata signature
    ) external payable override isNotFrozen(_msgSender()) {
        require(
            _collections[_collection].registered,
            "RMX: Unknown collection"
        );
        require(msg.value >= _minimumAmount, "RMX: amount too small");

        _distributeFunds(_collection, msg.value);
        emit BuyEvent(_collection, tokenId, msg.value);

        IREMXCollection collection = IREMXCollection(_collection);
        collection.redeem(
            _msgSender(),
            tokenId,
            msg.value,
            expiryBlock,
            signature
        );
    }

    /**
     * @dev returns the balance of an account held in this contract.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev sweep funds from an account and send to another account.
     * Intended to be used to recover funds from the contract that cannot
     * be withdrawn by the original payee for some reason.
     *
     * Emits a {SweepEvent}
     */
    function sweep(address _payee, address payable _recipient)
        external
        override
        onlyRole(PAYOUT_ROLE)
        isNotFrozen(_payee)
        isNotFrozen(_recipient)
    {
        uint256 amount = _balances[_payee];
        require(amount > 0, "RMX: Insufficient balance");
        _balances[_payee] = 0;

        emit SweepEvent(_payee, _recipient, amount);

        AddressUpgradeable.sendValue(_recipient, amount);
    }

    /**
     * @dev pay funds out to a payee. Intended to save the payee the gas fee
     * for the transaction.
     *
     * Emits a {PayoutEvent}
     */
    function payout(address payable _payee)
        external
        override
        onlyRole(PAYOUT_ROLE)
        isNotFrozen(_payee)
    {
        uint256 amount = _balances[_payee];
        require(amount > 0, "RMX: Insufficient balance");
        _balances[_payee] = 0;

        emit PayoutEvent(_payee, amount);
        AddressUpgradeable.sendValue(_payee, amount);
    }

    /**
     * @dev allow a registered payee to withdraw funds held in the contract
     *
     * Emits a {WithdrawEvent}
     */
    function withdraw() external override isNotFrozen(_msgSender()) {
        uint256 amount = _balances[_msgSender()];
        require(amount > 0, "RMX: Insufficient balance");
        _balances[_msgSender()] = 0;

        emit WithdrawEvent(_msgSender(), amount);
        AddressUpgradeable.sendValue(payable(_msgSender()), amount);
    }

    /**
     * @dev deposit royalties into the contract and distribute the funds
     * according to the payees' percentages
     *
     * Emits {RoyaltyEvent} and {DepositEvent} via {_distributeFunds}
     */
    function depositRoyalty(address _collection) external payable override {
        require(
            _collections[_collection].registered,
            "RMX: Unknown collection"
        );

        emit RoyaltyEvent(_collection, msg.value);
        _distributeFunds(_collection, msg.value);
    }

    /**
     * @dev distribute the funds according to the payees' percentages
     *
     * Emits a {DepositEvent} for each payee
     */
    function _distributeFunds(address _collection, uint256 amount) internal {
        for (uint i = 0; i < _collections[_collection].payees.length; i++) {
            CollectionPayee memory _collectionPayee = _collections[_collection]
                .payees[i];
            uint256 deposit = (amount * _collectionPayee.shares) /
                _collections[_collection].totalShares;
            amount -= deposit;

            if (i == _collections[_collection].payees.length - 1) {
                deposit += amount;
                amount = 0;
            }

            _balances[_collectionPayee.payee] += deposit;

            emit DepositEvent(_collection, _collectionPayee.payee, deposit);
        }
    }

    function freezeAccount(address _account) external onlyOwner {
        this.freeze(_account);
        // loop over all collections and freeze the account there too
    }

    function thawAccount(address _account) external onlyOwner {
        this.thaw(_account);
        // loop over all collections and thaw the account there too
    }
}
