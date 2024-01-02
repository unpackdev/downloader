// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20CappedUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IService.sol";
import "./IToken.sol";
import "./ITGE.sol";
import "./IIDRegistry.sol";
import "./IPool.sol";
import "./IRegistry.sol";
import "./ExceptionsLibrary.sol";
import "./IPausable.sol";

/**
 * @title Company (Pool) Token
 * @notice Tokens are the primary quantitative characteristic of all entities within the protocol. In addition to their inherent function as a unit of calculation, tokens can also be used as votes and as a unit indicating the degree of participation of an address in an off-chain or on-chain pool project. Tokens of any type can only be issued within the framework of a TGE (Token Generation Event), and by using vesting settings, such a TGE can divide the issuance of purchased or airdropped tokens into stages, as well as temporarily block the ability to transfer them from one address to another.
 * @dev An expanded ERC20 contract, based on which tokens of various types are issued. At the moment, the protocol provides for 2 types of tokens: Governance, which must be created simultaneously with the pool, existing for the pool only in the singular and participating in voting, and Preference, which may be several for one pool and which do not participate in voting in any way.
 */
contract Token is
    ERC20CappedUpgradeable,
    ERC20VotesUpgradeable,
    IToken,
    ReentrancyGuardUpgradeable
{
    /// @dev Service contract address
    IService public service;

    /// @dev Pool contract address
    address public pool;

    /**
    * @notice Token type code
    * @dev Code "1" - Governance Token is the main token of the pool, compatible with the ERC20 standard. One such token is equal to one vote. One pool can only have one contract of this type of token. When the primary TGE is launched, dedicated to the distribution of this type of token, the token is only a candidate for the Governance role.
    In case of a successful TGE, it remains the Governance token of the pool forever.
    In case of a failed TGE, it carries no weight and voting power for Governance procedures; another token can be appointed in its place through a repeated primary TGE. The cap is set once during the launch of the primary TGE.
    During each TGE, an additional issuance of Service:ProtocolTokenFee percent of the total volume of tokens distributed during the event takes place and is transferred to the balance of the Service:ProtocolTreasury address.
    * @dev Code "2" - Preference Token is an additional pool token, compatible with the ERC20 standard. It does not have voting power. One pool can have multiple independent and non-interacting tokens of this type.
    In case of a successful TGE, it is recognized by the pool as a Preference token forever.
    In case of a failed TGE, the pool forgets about such a token, not recognizing it as a Preference token.
    The cap is set once during the launch of the primary TGE.
    */
    TokenType public tokenType;

    /// @dev Preference token description, allows up to 5000 characters, for others - ""
    string public description;

    /// @notice All TGEs associated with this token
    /// @dev A list of TGE contract addresses that have been launched to distribute this token. If any of the elements in the list have a "Successful" state, it means that the token is valid and used by the pool. If there are no such TGEs, the token can be considered unsuccessful, meaning it is detached from the pool.
    address[] public tgeList;

    /// @notice Token decimals
    /// @dev This parameter is mandatory for all ERC20 tokens and is set to 18 by default. It indicates the precision applied when calculating a particular token. It can also be said that 10 raised to the power of minus decimal is the minimum indivisible amount of the token.
    uint8 private _decimals;

    /// @dev Total Vested tokens for all TGEs
    uint256 private totalVested;

    /// @dev List of all TGEs with locked tokens
    address[] private tgeWithLockedTokensList;

    /// @dev Total amount of tokens reserved for the minting protocol fee
    uint256 private totalProtocolFeeReserved;

    mapping(address => address[]) public tseList;

    bytes32 public compliance;

    event Transferred(address account);

    /// Examples: 1% = 10000, 100% = 1000000, 0.1% = 1000
    uint256 public partnerFee;

    address public partnerAddress;

    struct Dividend {
        uint256 amount;
        uint256 blockNumber;
        address tokenAddress; // Address of the ERC20 token or address(0) for Ether
    }

    Dividend[] public dividends;

    mapping(address => uint256) public lastDividendsClaimedIndex;

    // Mapping to record failed dividend transfers
    mapping(address => mapping(address => uint256)) public failedTransfers;

    mapping(address => uint256) private totalClaimedDividends;

    mapping(address => uint256) private lastRecordedBalance;

    event DividendsDeposited(
        address indexed depositor,
        uint256 amount,
        address tokenAddress
    );
    event DividendsClaimed(
        address indexed claimant,
        uint256 amount,
        address tokenAddress
    );

    // INITIALIZER AND CONSTRUCTOR

    /**
     * @notice Contract constructor.
     * @dev This contract uses OpenZeppelin upgrades and has no need for a constructor function.
     * The constructor is replaced with an initializer function.
     * This method disables the initializer feature of the OpenZeppelin upgrades plugin, preventing the initializer methods from being misused.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Token creation, can only be started once. At the same time, the TGE contract, which sells the created token, is necessarily simultaneously deployed and receives an entry in the Registry. For the Governance token, the Name field for the ERC20 standard is taken from the trademark of the Pool contract to which the deployed token belongs. For Preference tokens, you can set an arbitrary value of the Name field.
     * @param service_ The address of the Service contract
     * @param pool_ The address of the pool contract
     * @param info The token parameters, including its type, in the form of a structure described in the TokenInfo method
     * @param primaryTGE_ The address of the primary TGE for this token
     */
    function initialize(
        IService service_,
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external initializer {
        __ReentrancyGuard_init();
        __ERC20Capped_init(info.cap);

        description = info.description;

        if (info.tokenType == TokenType.Preference) {
            __ERC20_init(info.name, info.symbol);
            _decimals = info.decimals;
        } else {
            __ERC20_init(info.name, info.symbol);
        }
        tgeList.push(primaryTGE_);
        tgeWithLockedTokensList.push(primaryTGE_);
        tokenType = info.tokenType;
        service = service_;
        pool = pool_;
    }

    receive() external payable {}

    // RESTRICTED FUNCTIONS

    /**
     * @dev Minting of new tokens. Only the TGE or Vesting contract can mint tokens, there is no other way to get an additional issue. If the user who is being minted does not have tokens, they are sent to delegation on his behalf.
     * @param to The address of the account for which new token units are being minted
     * @param amount The number of tokens being minted
     */
    function mint(address to, uint256 amount) external onlyTGEOrVesting {
        // Delegate to self if first mint and no delegatee set
        if (tokenType == IToken.TokenType.Governance) {
            if (balanceOf(to) == 0 && delegates(to) == address(0))
                _delegate(to, to);
        }

        // Mint tokens
        _mint(to, amount);
    }

    /**
     * @dev Method for burning tokens. It can be called by both the token owner and the TGE contract to burn returned tokens during redeeming.
     * @param from The address of the account
     * @param amount The amount of tokens
     */
    function burn(address from, uint256 amount) external whenPoolNotPaused {
        // Check that sender is valid
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE ||
                msg.sender == from,
            ExceptionsLibrary.INVALID_USER
        );

        // Burn tokens
        _burn(from, amount);
    }

    /**
     * @dev This method adds the TGE contract address to the TGEList of this token.
     * @param tge The TGE address
     */
    function addTGE(address tge) external onlyTGEFactory {
        tgeList.push(tge);
        tgeWithLockedTokensList.push(tge);
    }

    function addTSE(address account, address tse) external onlyTGEFactory {
        tseList[account].push(tse);
    }

    function setCompliance(bytes32 compliance_) external {
        require(
            msg.sender == address(service.tgeFactory()) ||
                service.hasRole(service.ADMIN_ROLE(), msg.sender) ||
                service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_SERVICE
        );
        compliance = compliance_;

        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IToken.setCompliance.selector, compliance_)
        );
    }

    function setPartnerFee(
        address _partnerAddress,
        uint256 _partnerFee
    ) external {
        require(
            msg.sender == address(service.tgeFactory()) ||
                service.hasRole(service.ADMIN_ROLE(), msg.sender) ||
                service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_SERVICE
        );
        partnerFee = _partnerFee;
        partnerAddress = _partnerAddress;
    }

    /**
     * @dev This method modifies the number of token units that are vested and reserved for claiming by users.
     * @param amount The amount of tokens
     */
    function setTGEVestedTokens(uint256 amount) external onlyTGEOrVesting {
        totalVested = amount;
    }

    /**
     * @dev This method modifies the number of token units that are reserved as protocol fee.
     * @param amount The amount of tokens
     */
    function setProtocolFeeReserved(uint256 amount) external onlyTGE {
        totalProtocolFeeReserved = amount;
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev This method returns the precision level for the fractional parts of this token.
     * @return Decimals
     */
    function decimals()
        public
        view
        override(ERC20Upgradeable, IToken)
        returns (uint8)
    {
        if (tokenType == TokenType.Governance) {
            return 18;
        } else {
            return _decimals;
        }
    }

    /**
     * @dev This method returns the maximum allowable token emission.
     * @return The number of tokens taking into account the Decimals parameter
     */
    function cap()
        public
        view
        override(IToken, ERC20CappedUpgradeable)
        returns (uint256)
    {
        return super.cap();
    }

    /**
     * @dev This method returns the short name of the token, its ticker for listing.
     * @return A string with the name
     */
    function symbol()
        public
        view
        override(IToken, ERC20Upgradeable)
        returns (string memory)
    {
        return super.symbol();
    }

    /**
     * @dev The given getter returns the total balance of the address that is not locked for transfer, taking into account all the TGEs with which this token was distributed.
     * @dev It is the difference between the actual balance of the account and its locked portion.
     * @param account The address of the account
     * @return Unlocked balance of the account
     */
    function unlockedBalanceOf(address account) public view returns (uint256) {
        // Get total account balance
        uint256 balance = balanceOf(account);

        // Iterate through TGE With Locked Tokens List to get locked balance
        address[] memory _tgeWithLockedTokensList = tgeWithLockedTokensList;
        uint256 totalLocked = 0;
        for (uint256 i; i < _tgeWithLockedTokensList.length; i++) {
            totalLocked += ITGE(_tgeWithLockedTokensList[i]).lockedBalanceOf(
                account
            );
        }

        // Return difference
        return balance - totalLocked;
    }

    /**
     * @dev This method indicates whether a successful TGE has been conducted for this token. To determine this, it is sufficient to check the first event from the list of all TGEs. If it ended in failure, then this token cannot be considered active for its pool.
     * @return bool Is any TGE successful
     */
    function isPrimaryTGESuccessful() external view returns (bool) {
        return (ITGE(tgeList[0]).state() == ITGE.State.Successful);
    }

    /**
     * @dev This method returns the list of addresses of all TGE contracts ever deployed for this token.
     * @return array An array of contract addresses
     */
    function getTGEList() external view returns (address[] memory) {
        return tgeList;
    }

    /**
     * @dev This method returns the list of addresses of all TGE contracts ever deployed for this token and having active token transfer restrictions.
     * @return array An array of contract addresses
     */

    function getTgeWithLockedTokensList()
        external
        view
        returns (address[] memory)
    {
        return tgeWithLockedTokensList;
    }

    /**
     * @dev This method returns the address of the last conducted TGE for this token. Sorting is based on the starting block of the TGE, not the ending block (i.e., even if an earlier TGE contract is still active and the most recent one by creation time has already ended, the method will still return the address of the most recent contract).
     * @return address The contract address
     */
    function lastTGE() external view returns (address) {
        return tgeList[tgeList.length - 1];
    }

    /**
     * @dev This method returns the accumulated value stored in the contract's memory, which represents the number of token units that are in vesting at the time of the request.
     * @return uint256 The sum of tokens in vesting
     */
    function getTotalTGEVestedTokens() public view returns (uint256) {
        return totalVested;
    }

    /**
     * @dev This method returns the accumulated value stored in the contract's memory, which represents the number of token units that are reserved and should be issued and sent as the contract's fee.
     * @return uint256 The sum of tokens for the fee
     */
    function getTotalProtocolFeeReserved() public view returns (uint256) {
        return totalProtocolFeeReserved;
    }

    /**
     * @dev This method calculates the total supply for the token taking into account the reserved but not yet issued units (for vesting and protocol fee).
     * @return uint256 The sum of reserved tokens
     */
    function totalSupplyWithReserves() public view returns (uint256) {
        uint256 _totalSupplyWithReserves = totalSupply() +
            getTotalTGEVestedTokens() +
            getTotalProtocolFeeReserved();

        return _totalSupplyWithReserves;
    }

    function isERC1155() public pure returns (bool) {
        return false;
    }

    // INTERNAL FUNCTIONS

    /**
     * @notice Overriding the transfer method of the ERC20 token contract.
     * @dev When tokens are being transferred, a check is performed to ensure that the sender's balance has a sufficient amount of tokens that are not locked up. This is a stricter condition compared to the normal balance check.
     * @dev Each such transaction also triggers the check of all TGE contracts for the end of lockup and removes such contracts from the tgeWithLockedTokensList.
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param amount Amount of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenPoolNotPaused {
        // Update list of TGEs with locked tokens
        updateTgeWithLockedTokensList();

        // Check that locked tokens are not transferred
        require(
            amount <= unlockedBalanceOf(from),
            ExceptionsLibrary.LOW_UNLOCKED_BALANCE
        );

        if (tokenType == IToken.TokenType.Governance) {
            if (balanceOf(to) == 0 && delegates(to) == address(0))
                _delegate(to, to);
        }

        // Execute transfer
        super._transfer(from, to, amount);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        emit Transferred(to);
        require(
            IIDRegistry(service.idRegistry()).isWhitelisted(from, compliance),
            ExceptionsLibrary.NOT_WHITELISTED
        );

        require(
            IIDRegistry(service.idRegistry()).isWhitelisted(to, compliance),
            ExceptionsLibrary.NOT_WHITELISTED
        );

        super._afterTokenTransfer(from, to, amount);
    }

    function delegate(
        address delegatee
    ) public override(ERC20VotesUpgradeable, IToken) {
        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IToken.delegate.selector, delegatee)
        );

        super.delegate(delegatee);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override(ERC20Upgradeable, IToken) returns (bool) {
        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(IToken.transfer.selector, to, amount)
        );

        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override(ERC20Upgradeable, IToken) returns (bool) {
        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(
                IToken.transferFrom.selector,
                from,
                to,
                amount
            )
        );

        return super.transferFrom(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function _mint(
        address account,
        uint256 amount
    ) internal override(ERC20VotesUpgradeable, ERC20CappedUpgradeable) {
        super._mint(account, amount);
    }

    /**
     * @notice Burning a specified amount of tokens that are held in the account's balance
     * @dev Burning a specified amount of units of the token from the specified account.
     * @param account The address from which tokens are deducted for destruction
     * @param amount The amount of tokens to be destroyed
     */
    function _burn(
        address account,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._burn(account, amount);
    }

    // PRIVATE FUNCTIONS

    /**
     * @notice Update the list of TGEs with locked tokens
     * @dev It is crucial to keep this list up to date to have accurate information at any given time on how much of their token balance each user can dispose of, taking into account the locks imposed by the TGEs in which the user participated.
     */
    function updateTgeWithLockedTokensList() private {
        address[] memory _tgeWithLockedTokensList = tgeWithLockedTokensList;
        for (uint256 i; i < _tgeWithLockedTokensList.length; i++) {
            // Check if transfer is unlocked
            if (ITGE(_tgeWithLockedTokensList[i]).transferUnlocked()) {
                // Remove tge from tgeWithLockedTokensList when transfer is unlocked
                tgeWithLockedTokensList[i] = tgeWithLockedTokensList[
                    tgeWithLockedTokensList.length - 1
                ];
                tgeWithLockedTokensList.pop();
            }
        }
    }

    // DIVIDENDS BLOCK

    /**
     * @notice Deposits dividends in either Ether or ERC20 tokens.
     * @dev Records the deposited amount and token address. For ERC20, the amount is transferred from the sender.
     * @param tokenAddress The address of the ERC20 token, or address(0) for Ether.
     * @param amount The amount of ERC20 tokens to deposit. For Ether deposits, this is ignored.
     */
    function depositDividends(
        address tokenAddress,
        uint256 amount
    ) public payable nonReentrant {
        uint256 depositAmount;
        if (tokenAddress == address(0)) {
            // Ether deposit
            require(msg.value > 0, "No Ether to deposit");
            depositAmount = msg.value;
        } else {
            // ERC20 token deposit
            require(amount > 0, "Amount must be greater than 0");
            uint256 balanceBefore = IERC20Upgradeable(tokenAddress).balanceOf(
                address(this)
            );
            IERC20Upgradeable(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            uint256 balanceAfter = IERC20Upgradeable(tokenAddress).balanceOf(
                address(this)
            );
            depositAmount = balanceAfter - balanceBefore;
            require(depositAmount == amount, "Deposit amount mismatch");
        }

        _addDividendsRecord(tokenAddress, depositAmount);
    }

    /**
     * @dev Updates the dividend records by adding new deposits that have occurred since the last record update.
     * This function is designed to be called by an admin to ensure that all recent deposits are accounted for in the dividend system.
     * It calculates the new dividends based on the difference between the current balance and the last recorded balance.
     * This function handles both Ether and ERC20 token dividends.
     *
     * @notice This function should be called by an admin to update the dividend records with recent deposits.
     *
     * @param tokenAddress The address of the ERC20 token, or address(0) for Ether. This is the token for which the dividend deposits are being updated.
     *
     * Requirements:
     * - There must be new dividends to deposit, i.e., the current balance minus the last recorded balance must be greater than zero.
     * - This function can only be called when no other function is being executed in the contract (nonReentrant).
     */
    function updateDividendDeposits(address tokenAddress) public nonReentrant {
        uint256 currentBalance;
        if (tokenAddress == address(0)) {
            currentBalance = address(this).balance;
        } else {
            currentBalance = IERC20Upgradeable(tokenAddress).balanceOf(
                address(this)
            );
        }

        uint256 totalBalanceIncludingClaimed = currentBalance +
            totalClaimedDividends[tokenAddress];
        uint256 newDividends = totalBalanceIncludingClaimed -
            lastRecordedBalance[tokenAddress];
        require(newDividends > 0, "No new dividends to deposit");

        // Update the last recorded balance
        lastRecordedBalance[tokenAddress] = totalBalanceIncludingClaimed;

        // Call _addDividendsRecord to handle the new dividends
        _addDividendsRecord(tokenAddress, newDividends);
    }

    /**
     * @dev Adds a record of deposited dividends to the contract's storage. This function is an internal utility used
     * by other functions in the contract to record dividend deposits. It creates a new Dividend struct and adds it to
     * the dividends array. This function is not meant to be called externally but is used internally to handle
     * dividend deposits.
     *
     * @notice Internal function to record a new dividend deposit.
     *
     * @param tokenAddress The address of the ERC20 token for which dividends are being deposited, or address(0) for Ether.
     * @param amount The amount of dividends being deposited. For Ether, this is the value sent with the transaction;
     * for ERC20 tokens, this is the amount transferred to the contract.
     *
     * Emits a `DividendsDeposited` event indicating the depositor, the amount, and the token address.
     */
    function _addDividendsRecord(address tokenAddress, uint256 amount) private {
        dividends.push(
            Dividend({
                amount: amount,
                blockNumber: block.number,
                tokenAddress: tokenAddress
            })
        );

        // Log the dividend deposit
        service.registry().log(
            msg.sender,
            address(this),
            0,
            abi.encodeWithSelector(
                IToken.depositDividends.selector,
                tokenAddress,
                amount
            )
        );

        emit DividendsDeposited(msg.sender, amount, tokenAddress);
    }

    /**
     * @notice Claims any dividends owed to the caller.
     * @dev Calculates and transfers the owed dividends to the caller.
     *      Records any failed transfer for a later retry.
     */
    function claimDividends() public nonReentrant {
        uint256 totalClaimable = 0;
        for (
            uint256 i = lastDividendsClaimedIndex[msg.sender];
            i < dividends.length;
            i++
        ) {
            Dividend storage dividend = dividends[i];
            uint256 balanceAtDividend = getPastVotes(
                msg.sender,
                dividend.blockNumber
            );
            uint256 claimable = (balanceAtDividend * dividend.amount) /
                totalSupplyAt(dividend.blockNumber);
            if (dividend.tokenAddress == address(0)) {
                payable(msg.sender).transfer(claimable);
                totalClaimable += claimable;
            } else {
                try
                    IERC20Upgradeable(dividend.tokenAddress).transfer(
                        msg.sender,
                        claimable
                    )
                {
                    totalClaimable += claimable;

                    // Update total claimed dividends
                    totalClaimedDividends[dividend.tokenAddress] += claimable;
                } catch {
                    // Record the failed transfer for a retry
                    failedTransfers[msg.sender][
                        dividend.tokenAddress
                    ] += claimable;
                }
            }
            lastDividendsClaimedIndex[msg.sender] = i + 1;
        }
        emit DividendsClaimed(msg.sender, totalClaimable, address(0));
    }

    /**
     * @notice Allows a user to retry claiming dividends that previously failed to transfer.
     * @param tokenAddress The address of the token for which to claim failed transfers.
     */
    function retryFailedTransfers(address tokenAddress) public nonReentrant {
        uint256 amount = failedTransfers[msg.sender][tokenAddress];
        require(amount > 0, "No failed transfers for this token");

        // Attempt the transfer again
        IERC20Upgradeable(tokenAddress).transfer(msg.sender, amount);

        // Reset the failed transfer amount
        failedTransfers[msg.sender][tokenAddress] = 0;
    }

    /**
     * @notice Retrieves the total dividends owed to a shareholder.
     * @param shareholder The address of the shareholder.
     * @return totalOwed The total amount of dividends owed to the shareholder.
     */
    function getOwedDividends(
        address shareholder
    ) public view returns (uint256) {
        uint256 totalOwed = 0;
        for (
            uint256 i = lastDividendsClaimedIndex[shareholder];
            i < dividends.length;
            i++
        ) {
            Dividend memory dividend = dividends[i];
            uint256 balanceAtDividend = getPastVotes(
                shareholder,
                dividend.blockNumber
            );
            uint256 owed = (balanceAtDividend * dividend.amount) /
                totalSupplyAt(dividend.blockNumber);
            totalOwed += owed;
        }
        return totalOwed;
    }

    /**
     * @notice Retrieves the total token supply at a given block number.
     * @param blockNumber The block number to check the total supply at.
     * @return The total token supply at the given block number.
     */
    function totalSupplyAt(uint256 blockNumber) public view returns (uint256) {
        return getPastTotalSupply(blockNumber);
    }

    // MODIFIERS

    /// @notice Modifier that allows the method to be called only by the Pool contract.
    modifier onlyPool() {
        require(msg.sender == pool, ExceptionsLibrary.NOT_POOL);
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGEFactory contract.
    modifier onlyTGEFactory() {
        require(
            msg.sender == address(service.tgeFactory()),
            ExceptionsLibrary.NOT_TGE_FACTORY
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGE contract.
    modifier onlyTGE() {
        require(
            service.registry().typeOf(msg.sender) ==
                IRecordsRegistry.ContractType.TGE,
            ExceptionsLibrary.NOT_TGE
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by the TGE or Vesting contract.
    modifier onlyTGEOrVesting() {
        bool isTGE = service.registry().typeOf(msg.sender) ==
            IRecordsRegistry.ContractType.TGE;
        bool isVesting = address(service.vesting()) == msg.sender;
        require(isTGE || isVesting, ExceptionsLibrary.NOT_TGE);
        _;
    }

    /// @notice Modifier that allows the method to be called only if the Pool contract is not paused.
    modifier whenPoolNotPaused() {
        require(!IPausable(pool).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }
}
