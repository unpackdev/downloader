// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";

/**
 * CAIMAN FUND
 *
 * https://caiman.fund
 *
 * ©2021 v1.0.1
 *
 * Requirements:
 *     - User may deposit in ETH or pre-approved ERC20 tokens.
 *     - Deposits are exchanged for an NFT which acts as the transaction invoice.
 *     - The NFT can be "released" after 9 months of profit/loss at the behest of Financial role.
 *         - Funds are awarded to the current holder of the NFT.
 *         - The "spent" NFT is burned after release.
 *     - NFTs are standard ERC721 and thus can be exchanged/moved/traded as desired.
 *     - ERC20 token contracts used as sources of funds must support the allowance and transferFrom functions.
 *     - External (non-ethereum) sources can be used as a source of funds.
 *          - NFT is minted as "unconfirmed"
 *          - The user must provide a destination external address (such as BTC wallet) to correlate off-chain deposit.
 *          - investment can be confirmed on-chain by Finance role
 *          - releases must be made off-chain
 *          - When the requestRelease is called, a destination can be provided.
 */
contract CaimanFundV1 is Initializable,
ContextUpgradeable,
AccessControlEnumerableUpgradeable,
ERC721EnumerableUpgradeable,
ERC721PausableUpgradeable,
ReentrancyGuardUpgradeable {
    function initialize(string memory name, string memory symbol) public virtual initializer {
        __CaimanFund_init(name, symbol);
    }

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20 for IERC20;
    using Strings for uint256;
    using Strings for uint40;
    using Strings for uint8;

    /// @dev triggered when funds are invested in exchange for an NFT.
    event Invested(uint8 fund, address indexed from, uint8 sourceId, uint256 amount, uint256 indexed tokenId, string externalSource);
    /// An external destination is provided if the original investment was made off-chain.
    event Request(uint256 indexed tokenId, string externalDestination);
    /// @dev triggered when the funds are released back to the NFT holder in exchange for the NFT.
    event Released(uint8 fund, address payable indexed to, uint8 sourceId, uint256 amount, uint256 indexed tokenId);
    /// @dev triggered when an off-chain investment has been confirmed
    event Confirm(uint256 indexed tokenId);
    /// @dev triggered when an off-chain investment has been cancelled/rejected
    event Reject(uint256 indexed tokenId);

    bytes32 constant public PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 constant public FINANCE_ROLE = keccak256("FINANCE_ROLE");

    CountersUpgradeable.Counter private _tokenIdTracker;

    /// @dev a fund to accept investments, including a destination wallet for transparency/prospectus.
    struct Fund {
        string symbol;
        string name;
        address payable destination;
        bool active;
    }

    mapping(uint8 => Fund) public funds;

    /// @dev an external contract to act as a source for ERC20 fund exchanges.
    struct Source {
        string symbol;
        string externalDestination;
        address source;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint8 decimals;
        bool active;
        bool isExternal;
    }

    mapping(uint8 => Source) public sources;

    /// @dev stores the details of an individual investment to augment the NFT.
    struct Investment {
        uint8 fundId;
        uint8 sourceId;
        uint256 amount;
        uint40 depositTime;
        bool confirmed;
    }

    mapping(uint256 => Investment) private investments;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
     *
     * See {ERC721-tokenURI}.
     */
    function __CaimanFund_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __CaimanFund_init_unchained();
    }

    function __CaimanFund_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // @dev excluding to reduce gas price till needed
        // _setupRole(PAUSE_ROLE, _msgSender());
        // _setupRole(FINANCE_ROLE, _msgSender());
    }

    /**
     * @dev override or create a fund.
     *
     * Requirements:
     *      - Use 0 for _sourceId to indicate ether (no external contract)
     *      - Leave _symbol blank to signal the end of public Sources array.
     *      - Include _externalDestination as a destination address for off-chain investments.
     *      - When this is external to ethereum's blockchain, indicate this with _isExternal.
     */
    function setSource(
        uint8 _sourceId,
        string memory _symbol,
        string memory _externalDestination,
        address payable _source,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint8 _decimals,
        bool _active,
        bool _isExternal
    ) public
    onlyRole(FINANCE_ROLE)
    {
        require(AddressUpgradeable.isContract(_source), "CF: not a contract");
        require(_minDeposit > 0, "CF: invalid amount");
        require(_minDeposit < _maxDeposit, "CF: min < max");
        sources[_sourceId] = Source(_symbol, _externalDestination, _source, _minDeposit, _maxDeposit, _decimals, _active, _isExternal);
    }

    function getSource(uint8 _sourceId)
    public
    view
    returns (Source memory) {
        return sources[_sourceId];
    }

    /**
     * @dev override or create a fund.
     *
     * Requirements:
     *      - Leave symbol blank to signal the end of public Sources array.
     */
    function setFund(
        uint8 _fundId,
        string memory _symbol,
        string memory _name,
        address payable _destination,
        bool _active
    ) public {
        _checkRole(FINANCE_ROLE, _msgSender());
        funds[_fundId] = Fund(_symbol, _name, _destination, _active);
    }

    function getFund(uint8 _fundId)
    public
    view
    returns (Fund memory) {
        return funds[_fundId];
    }

    /**
     * @dev logs an off-chain investment, minting a non-confirmed NFT to the owner,
     */
    function investExternal(uint8 _fundId, uint8 _sourceId, uint256 _amount, string memory _externalSource)
    public
    whenNotPaused
    nonReentrant
    {
        require(true == funds[_fundId].active, "CF: fund paused");
        require(true == sources[_sourceId].active, "CF: not accepting type");
        require(_amount >= sources[_sourceId].minDeposit, "CF: <min amount");
        require(_amount <= sources[_sourceId].maxDeposit, "CF: >max amount");
        require(bytes(_externalSource).length > 25, "CF: external source needed");

        uint256 _tokenId = _tokenIdTracker.current();
        _safeMint(_msgSender(), _tokenId);

        investments[_tokenId] = Investment(_fundId, _sourceId, _amount, uint40(block.timestamp), false);
        _tokenIdTracker.increment();

        emit Invested(_fundId, _msgSender(), _sourceId, _amount, _tokenId, _externalSource);
    }

    /**
     * @dev deposit Ether directly via consumer's wallet
     */
    function investEther(uint8 _fundId)
    public
    payable
    whenNotPaused
    nonReentrant
    {
        require(true == funds[_fundId].active, "CF: fund paused");
        require(true == sources[0].active, "CF: not accepting type");
        require(msg.value >= sources[0].minDeposit, "CF: <min amount");
        require(msg.value <= sources[0].maxDeposit, "CF: >max amount");

        address payable _to = _investTo(_fundId, 0, msg.value);

        (bool _success,) = _to.call{value : msg.value}("");
        require(_success, "CF: failed to send ETH");
    }

    /**
     * @dev deposit ERC20 tokens of an investable type.
     *      Assumes an allowance increase has already been given.
     */
    function investTokens(uint8 _fundId, uint8 _sourceId, uint256 _amount)
    public
    whenNotPaused
    nonReentrant
    {
        require(true == funds[_fundId].active, "CF: fund paused");
        require(true == sources[_sourceId].active, "CF: not accepting type");
        require(_amount >= sources[_sourceId].minDeposit, "CF: <min amount");
        require(_amount <= sources[_sourceId].maxDeposit, "CF: >max amount");

        address payable _to = _investTo(_fundId, _sourceId, _amount);

        IERC20(sources[_sourceId].source).safeTransferFrom(_msgSender(), _to, _amount);
    }

    // @dev excluding to reduce gas price till needed
    //
    // /**
    //  * @dev alternative to the user making the token deposit request themself.
    //  *      Assumes an allowance increase has already been given.
    //  *      In this case the gas is paid for the investor.
    //  */
    // function acceptTokens(address _from, uint8 _fundId, uint8 _sourceId, uint256 _amount)
    // public
    // {
    //     _checkRole(FINANCE_ROLE, _msgSender());
    //
    //     //require(true == funds[_fundId].active, "CF: fund paused");
    //     //require(true == sources[_sourceId].active, "CF: not accepting type");
    //     //require(_amount >= sources[_sourceId].minDeposit, "CF: <min amount");
    //     //require(_amount <= sources[_sourceId].maxDeposit, "CF: >max amount");
    //
    //     address payable _to = _investTo(_fundId, _sourceId, _amount);
    //
    //     IERC20(sources[_sourceId].source).safeTransferFrom(_from, _to, _amount);
    // }

    /**
     * @dev mints an NFT for an off-chain investment after the fact
     */
    function investFor(
        address _investor,
        uint8 _fundId,
        uint8 _sourceId,
        uint256 _amount,
        string memory _externalSource,
        uint40 _timeStamp
    ) public
    onlyRole(FINANCE_ROLE)
    {

        uint256 _tokenId = _tokenIdTracker.current();
        _safeMint(_investor, _tokenId);

        investments[_tokenId] = Investment(_fundId, _sourceId, _amount, _timeStamp, true);
        _tokenIdTracker.increment();

        emit Invested(_fundId, _investor, _sourceId, _amount, _tokenId, _externalSource);
    }

    /**
     * @dev confirms an off-chain deposit, updating the NFT.
     */
    function confirmExternal(uint256 _tokenId)
    public
    onlyRole(FINANCE_ROLE)
    {
        require(_exists(_tokenId), "CF: token invalid");
        require(investments[_tokenId].confirmed == false, "CF: already confirmed");
        require(sources[investments[_tokenId].sourceId].isExternal == true, "CF: is not external");

        investments[_tokenId].confirmed = true;

        emit Confirm(_tokenId);
    }

    /**
     * @dev rejects an off-chain deposit, burning the associated NFT.
     */
    function rejectExternal(uint256 _tokenId)
    public
    onlyRole(FINANCE_ROLE)
    {
        //        _checkRole(FINANCE_ROLE, _msgSender());
        require(_exists(_tokenId), "CF: token invalid");
        require(sources[investments[_tokenId].sourceId].isExternal == true, "CF: is not external");

        investments[_tokenId].confirmed = false;
        _burn(_tokenId);

        emit Reject(_tokenId);
    }

    /**
     * @dev Assume invested funds are received. Mint NFT, save deposit and emit event.
     */
    function _investTo(
        uint8 _fundId,
        uint8 _sourceId,
        uint256 _amount
    ) private
    returns (address payable) {
        uint256 _tokenId = _tokenIdTracker.current();
        _safeMint(_msgSender(), _tokenId);

        investments[_tokenId] = Investment(_fundId, _sourceId, _amount, uint40(block.timestamp), true);
        _tokenIdTracker.increment();

        emit Invested(_fundId, _msgSender(), _sourceId, _amount, _tokenId, "");
        return funds[_fundId].destination;
    }

    // @dev excluding to reduce gas price till needed
    //
    // /**
    //  * @dev withdraws ETH from the contract balance.
    //  *      Useful to avoid trapped funds if someone transfers  to this contract in error.
    //  */
    // function rescueETH(address payable _to, uint256 _amount)
    // public
    // {
    //     _checkRole(FINANCE_ROLE, _msgSender());
    //     (bool _success,) = payable(_to).call{value : _amount}("");
    //     require(_success, "CM: failed send");
    // }
    //
    // /**
    //  * @dev withdraws ETH from the contract balance.
    //  *      Useful to avoid trapped funds if someone transfers  to this contract in error.
    //  *      Provide the contract source to extract tokens so we can return to sender.
    //  */
    // function rescueERC20(address _contract, address payable _to, uint256 _amount)
    // public
    // {
    //     _checkRole(FINANCE_ROLE, _msgSender());
    //     IERC20(_contract).safeTransfer(_to, _amount);
    // }

    /**
     * @dev token holder requests release of their token, emitting an event to signal this request.
     *      _externalDestination provided as a destination wallet for external release.
     */
    function requestRelease(uint256 _tokenId, string memory _externalDestination)
    public
    whenNotPaused
    {
        /// @dev could indicate that the token has already been released
        require(_exists(_tokenId), "CF: token invalid");
        ///                                        "---------|---------|---------|--"
        require(ownerOf(_tokenId) == _msgSender(), "CF: only owner may request");
        require(investments[_tokenId].confirmed == true, "CF: not confirmed");

        if (sources[investments[_tokenId].sourceId].isExternal) {
            require(bytes(_externalDestination).length > 0, "CF: destination required");
        } else {
            require(bytes(_externalDestination).length == 0, "CF: not external");
        }

        emit Request(_tokenId, _externalDestination);
    }

    /**
     * @dev release funds to token holder
     *
     * Requirements:
     *     - transfers funds in the original deposit currency to the NFT holder
     *     - burns the NFT on confirmation
     *     - Emits Released event
     */
    function release(uint256 _tokenId, uint256 _amount, bool _validate)
    public
    payable onlyRole(FINANCE_ROLE)
    {
        //        _checkRole(FINANCE_ROLE, _msgSender());
        /// @dev Could indicate that the token has already been released
        require(_exists(_tokenId), "CF: token invalid");
        if (_validate) {
            /// @dev Amount should be greater than 0
            require(_amount > 0, "CF: amount invalid");
            /// @dev Checks that we are not (without knowledge) accidentally using the wrong decimal places.
            require(_amount < (investments[_tokenId].amount * 10), "CF: >1000%");
            require(_amount < (investments[_tokenId].amount * 2), "CF: >200%");
            require(_amount > (investments[_tokenId].amount / 2), "CF: <50%");
            /// @dev External investments must be confirmed before release
            require(investments[_tokenId].confirmed == true, "CF: not confirmed");
            /// @dev Checks that we are not releasing early without knowledge.
            require(investments[_tokenId].depositTime < uint40(block.timestamp - uint256(182 days)), "CF: early");
        }

        /// @dev Discern owner and mark them as the destination for release of Ether/Tokens
        address _owner = ownerOf(_tokenId);
        require(_owner != _msgSender(), "CF: release to self");
        address payable _to = payable(_owner);

        uint8 _sourceId = investments[_tokenId].sourceId;

        if (!sources[investments[_tokenId].sourceId].isExternal) {
            if (0 == _sourceId) {
                /// @dev Release in ETH from msg.value
                require(_amount <= msg.value, "CF: insufficient ETH");

                (bool _success,) = _to.call{value : _amount}("");
                require(_success, "CF: failed to send");
            } else {
                /// @dev Release in ERC20 token from balance
                IERC20(sources[_sourceId].source).safeTransferFrom(_msgSender(), _to, _amount);
            }
        }

        _burn(_tokenId);

        emit Released(investments[_tokenId].fundId, _to, _sourceId, _amount, _tokenId);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *     - the caller must have the `PAUSE_ROLE`.
     */
    function pause() public virtual onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *     - the caller must have the `PAUSE_ROLE`.
     */
    function unpause() public virtual onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    /**
     * For the sake of simplicity, the tokenURI will contain the original deposit data.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable)
    returns (string memory) {
        require(_exists(_tokenId), "CF: invalid token");
        return string(abi.encodePacked(
                "https://caiman.fund/token/",
                _tokenId.toString(), ".",
                investments[_tokenId].depositTime.toString(), ".",
                investments[_tokenId].fundId.toString(), ".",
                investments[_tokenId].sourceId.toString(), ".",
                investments[_tokenId].amount.toString(), ".",
                investments[_tokenId].confirmed ? "1" : "0"
            ));
    }

    /**
     * @dev list the token URIs for an owner.
     */
    function tokenURIsByOwner(address _owner)
    public
    view
    returns (string[] memory) {
        uint256 _balance = ERC721Upgradeable.balanceOf(_owner);
        string[] memory _uris = new string[](_balance);
        if (_balance > 0) {
            for (uint256 t = 0; t < _balance; t++) {
                _uris[t] = tokenURI(ERC721EnumerableUpgradeable.tokenOfOwnerByIndex(_owner, t));
            }
        }
        return _uris;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId)
    internal
    virtual
    override(ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
    returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    uint256[48] private __gap;
}