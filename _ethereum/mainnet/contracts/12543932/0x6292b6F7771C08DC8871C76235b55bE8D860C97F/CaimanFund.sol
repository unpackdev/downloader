// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";

/**
 * CAIMAN FUND
 *
 * https://caiman.fund
 *
 * ©2021 v1.0.0
 *
 * Requirements:
 *   - Deposits can be made in exchange for NFT an token which acts as the transaction invoice.
 *   - A token can be "released" after 9 months of profit/loss at the behest of Financial role.
 *     - Funds are awarded to the current holder of the token.
 *     - The "spent" token is then burned.
 *   - Tokens are standard ERC721 and thus can be exchanged/moved/traded as desired.
 */
contract CaimanFund is Context, AccessControlEnumerable, ERC721Enumerable, ERC721Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Strings for uint40;
    using Strings for uint8;

    bytes32 constant public PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 constant public FINANCIAL_ROLE = keccak256("FINANCIAL_ROLE");

    event FundsDeposited(uint8 fund, address from, uint256 _amount, uint256 tokenId);
    event FundsReleased(uint8 fund, address payable to, uint256 _amount, uint256 tokenId);

    Counters.Counter private tokenIdTracker;
    string constant private baseTokenURI = "https://token.caiman.fund/";

    /**
     * @dev require a minimum deposit of 1 ETH by default
     */
    uint256 constant public DEPOSIT_MINIMUM = 1000000000000000000;

    /**
     * @dev limit the maximum deposit to 25k ETH in one transaction by default
     */
    uint256 constant public DEPOSIT_MAXIMUM = 25000000000000000000000;

    /**
     * @dev limit the maximum for one fund to 100m ETH by default
     */
    uint256 constant public FUND_MAXIMUM_INVESTED = 100000000000000000000000000;

    /**
     * @dev will not allow fund release for 9 months
     */
    uint256 constant public RELEASE_TIME = 182 days;

    struct Deposit {
        uint8 fundId;
        uint256 amount;
        uint40 depositTime;
    }

    mapping(uint256 => Deposit) private deposits;

    struct Fund {
        string symbol;
        string name;
        bool paused;
        uint256 minDeposit;
        uint256 maxDeposit;
        uint256 invested;
        uint256 investedTotal;
        uint256 maxInvested;
    }

    mapping(uint8 => Fund) public funds;

    /**
     * @dev constructor for CaimanFund contract
     * 
     * Requirements:
     *      - Generate ERC721 token
     *      - Establish roles for minting, pausing, and financial actions.
     */
    constructor() ERC721(
        "Caiman Fund",
        "CFD"
    ){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(FINANCIAL_ROLE, _msgSender());
        setFund(1, "CFDI", "Caiman Fund I", false, DEPOSIT_MINIMUM, DEPOSIT_MAXIMUM, 0, 0, FUND_MAXIMUM_INVESTED);
        setFund(2, "CFDII", "Caiman Fund II", false, DEPOSIT_MINIMUM, DEPOSIT_MAXIMUM, 0, 0, FUND_MAXIMUM_INVESTED);
    }

    /**
     * @dev override or create a fund.
     */
    function setFund(
        uint8 _fundId,
        string memory _symbol,
        string memory _name,
        bool _paused,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _invested,
        uint256 _investedTotal,
        uint256 _maxInvested
    ) public onlyFinancialRole {
        if (0 == _minDeposit) {
            _minDeposit = funds[_fundId].minDeposit;
        }
        if (0 == _maxDeposit) {
            _maxDeposit = funds[_fundId].maxDeposit;
        }
        if (0 == _invested) {
            _invested = funds[_fundId].invested;
        }
        if (0 == _investedTotal) {
            _investedTotal = funds[_fundId].investedTotal;
        }
        if (0 == _maxInvested) {
            _maxInvested = funds[_fundId].maxInvested;
        }
        funds[_fundId] = Fund(_symbol, _name, _paused, _minDeposit, _maxDeposit, _invested, _investedTotal, _maxInvested);
    }

    /**
     * @dev prevent deposits into the fund.
     */
    function pauseFund(uint8 _fundId) public onlyPauserRole {
        require(funds[_fundId].paused == true, "CaimanFund: fund already paused");
        funds[_fundId].paused = true;
    }

    /**
     * @dev allow deposits into the fund.
     */
    function unpauseFund(uint8 _fundId) public onlyPauserRole {
        require(funds[_fundId].paused == true, "CaimanFund: fund already unpaused");
        funds[_fundId].paused = false;
    }

    /**
     * @dev deposits ETH to receive a minted token which represents the deposit
     */
    function deposit(uint8 _fundId) public whenNotPaused onlyHuman payable {
        require(false == funds[_fundId].paused, "CaimanFund: sorry this fund is not currently allowing new deposits, please come back later");
        require(msg.value >= funds[_fundId].minDeposit, "CaimanFund: deposit amount was below minimum, deposit cancelled");
        require(msg.value <= funds[_fundId].maxDeposit, "CaimanFund: maximum deposit amount exceeded, deposit cancelled");
        require(funds[_fundId].invested < funds[_fundId].maxInvested, "CaimanFund: sorry this fund is currently not accepting new deposits, please contact us for assistance");
        require((funds[_fundId].invested + msg.value) < funds[_fundId].maxInvested, "CaimanFund: sorry this fund will not allow a deposit of this size, please reduce the deposit size or contact us for assistance");

        funds[_fundId].invested += msg.value;
        funds[_fundId].investedTotal += msg.value;

        uint256 _tokenId = tokenIdTracker.current();
        _safeMint(_msgSender(), _tokenId);

        uint40 _depositTime = uint40(block.timestamp);

        deposits[_tokenId] = Deposit(_fundId, msg.value, _depositTime);
        tokenIdTracker.increment();

        emit FundsDeposited(_fundId, _msgSender(), msg.value, _tokenId);
    }

    /**
     * @dev get the invested totals for all funds.
     */
    function fund(uint8 _fundId) public view whenNotPaused returns (Fund memory) {
        return funds[_fundId];
    }

    /**
     * @dev withdraws ETH from the balance for the fund
     *
     * Requirements:
     *      - If unspecified the entire amount will be withdrawn.
     */
    function withdraw(uint256 _amount) public onlyFinancialRole whenNotPaused {
        if (_amount == 0) {
            _amount = address(this).balance;
        }
        Address.sendValue(payable(_msgSender()), _amount);
    }

    /**
     * @dev return the token information from a token ID, even if it has been released
     */
    function tokenInfo(uint256 _tokenId) public view returns (
        address owner,
        uint8 fundId,
        uint256 amount,
        uint40 depositTime,
        bool released
    ) {
        address _owner = address(0);
        bool _released = true;
        if (_exists(_tokenId)) {
            _owner = ERC721.ownerOf(_tokenId);
            _released = false;
        }
        return (
        _owner,
        deposits[_tokenId].fundId,
        deposits[_tokenId].amount,
        deposits[_tokenId].depositTime,
        _released
        );
    }

    /**
     * @dev burns a token and releases appropriate funds to the current owner from the contract balance
     */
    function releaseFromContract(
        uint256 _tokenId,
        uint256 _amount,
        bool _validate
    ) public onlyFinancialRole whenNotPaused {
        address payable _to = _releaseTo(_tokenId, _amount, _validate);

        Address.sendValue(_to, _amount);

        _burn(_tokenId);
        funds[deposits[_tokenId].fundId].invested -= deposits[_tokenId].amount;
        emit FundsReleased(deposits[_tokenId].fundId, _to, _amount, _tokenId);
    }

    /**
     * @dev burns a token and releases appropriate funds to the current owner directly
     */
    function releaseFromWallet(uint256 _tokenId, bool _validate)
    public onlyFinancialRole payable whenNotPaused
    {
        address payable _to = _releaseTo(_tokenId, msg.value, _validate);

        (bool success,) = _to.call{value : msg.value}("");
        require(success, "CaimanFund: unable to send value from wallet, recipient may have reverted");

        _burn(_tokenId);
        funds[deposits[_tokenId].fundId].invested -= deposits[_tokenId].amount;
        emit FundsReleased(deposits[_tokenId].fundId, _to, msg.value, _tokenId);
    }

    /**
     * @dev checks that the release attempt is valid with some optional safety checks that can be overridden.
     */
    function _releaseTo(uint256 _tokenId, uint256 _amount, bool _validate) private view returns (address payable) {
        require(_exists(_tokenId), "CaimanFund: token does not exist or has been released");
        if (_validate) {
            require(_amount > 0, "CaimanFund: release amount must be greater than 0.");
            require(_amount < (deposits[_tokenId].amount * 10), "CaimanFund: release amount in wei is more than 1000% of the original deposit.");
            require(_amount < (deposits[_tokenId].amount * 2), "CaimanFund: release amount in wei is more than 200% of the original deposit.");
            require(_amount > (deposits[_tokenId].amount / 2), "CaimanFund: release amount in wei is less than 50% of the original deposit.");
            require(deposits[_tokenId].depositTime < uint40(block.timestamp - RELEASE_TIME), "CaimanFund: release time has not yet been reached for this token.");
        }
        address _owner = ownerOf(_tokenId);
        require(_owner != _msgSender(), "CaimanFund: may not release funds to yourself");
        return payable(_owner);
    }

    /**
     * @dev requires the user has the financial role
     */
    modifier onlyFinancialRole() {
        require(hasRole(FINANCIAL_ROLE, _msgSender()), "CaimanFund: must have Financial role");
        _;
    }

    /**
     * @dev disallows contract or non-origin action.
     */
    modifier onlyHuman() {
        require(!Address.isContract(_msgSender()) && tx.origin == _msgSender(), "CaimanFund: action not permitted by automation");
        _;
    }

    /**
     * @dev requires the user has the pauser role
     */
    modifier onlyPauserRole() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "CaimanFund: must have pauser role to pause/unpause");
        _;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual onlyPauserRole {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual onlyPauserRole {
        _unpause();
    }

    /**
     * For the sake of simplicity, the tokenURI will contain the original deposit data.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(_tokenId), "CaimanFund: URI query for nonexistent token");
        string memory _s = "/";
        return string(abi.encodePacked(
                baseTokenURI,
                _tokenId.toString(), _s,
                deposits[_tokenId].fundId.toString(), _s,
                deposits[_tokenId].amount.toString(), _s,
                deposits[_tokenId].depositTime.toString()
            ));
    }

    /**
     * @dev - list the token URIs for the owner.
     */
    function tokenURIsByOwner(address _owner) public view returns (string[] memory) {
        uint256 _balance = ERC721.balanceOf(_owner);
        string[] memory _uris = new string[](_balance);
        if (_balance > 0) {
            for (uint256 t = 0; t < _balance; t++) {
                _uris[t] = tokenURI(ERC721Enumerable.tokenOfOwnerByIndex(_owner, t));
            }
        }
        return _uris;
    }

    /**
     * @dev permit standard token transfers.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721Pausable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}