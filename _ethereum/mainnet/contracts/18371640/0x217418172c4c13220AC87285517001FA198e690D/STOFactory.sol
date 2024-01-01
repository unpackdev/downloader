/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./UpgradeableBeacon.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IBeacon.sol";
import "./Proxy.sol";
import "./ERC1967Upgrade.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20Burnable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./MathUpgradeable.sol";
/// Import all OZ interfaces from which it extends
/// Add custom functions
import "./IERC20MetadataUpgradeable.sol";

/// @title ISTOToken
/// @custom:security-contact tech@brickken.com
interface ISTOToken is IERC20MetadataUpgradeable {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 balance;
    }

    /// @dev Struct to store the Dividend of STO Token
    struct DividendDistribution {
        /// @dev Total Amount of Dividend
        uint256 totalAmount;
        /// @dev Block number
        uint256 blockNumber;
    }

    /// Events

    event NewDividendDistribution(address indexed token, uint256 totalAmount);

    event DividendClaimed(
        address indexed claimer,
        address indexed token,
        uint256 amountClaimed
    );

    event NewPaymentToken(
        address indexed OldPaymentToken,
        address indexed NewPaymentToken
    );

    /// @dev Event to signal that the issuer changed
    /// @param issuer New issuer address
    event ChangeIssuer(address indexed issuer);

    /// @dev Event to signal that the minter changed
    /// @param newMinter New minter address
    event ChangeMinter(address indexed newMinter);

    /// @dev Event to signal that the url changed
    /// @param newURL New url
    event ChangeURL(string newURL);

    /// @dev Event to signal that the max supply changed
    /// @param newMaxSupply New max supply
    event ChangeMaxSupply(uint256 newMaxSupply);

    /// @dev Event emitted when any group of wallet is added or remove to the whitelist
    /// @param addresses Array of addresses of the wallets changed in the whitelist
    /// @param statuses Array of boolean status to define if add or remove the wallet to the whitelist
    /// @param owner Address of the owner of the contract
    event ChangeWhitelist(address[] addresses, bool[] statuses, address owner);

    event TrackingChanged(
        address indexed from,
        address indexed oldValue,
        address indexed newValue
    );
    event CheckpointBalanceChanged(
        address indexed from,
        uint256 oldValue,
        uint256 newValue
    );

    /// @dev Method to query past holder balance
    /// @param account address to query
    /// @param blockNumber which block in the past to query
    function getPastBalance(address account, uint256 blockNumber)
        external
        returns (uint256);

    /// @dev Method to query past total supply
    /// @param blockNumber which block in the past to query
    function getPastTotalSupply(uint256 blockNumber) external returns (uint256);

    /// @dev Method to query a specific checkpoint
    /// @param account address to query
    /// @param pos index in the array
    function checkpoints(address account, uint32 pos)
        external
        returns (Checkpoint memory);

    /// @dev Method to query the number of checkpoints
    /// @param account address to query
    function numCheckpoints(address account) external returns (uint32);

    /// @dev Method to check if account is tracked. If it returns address(0), user is not tracked
    /// @param account address to query
    function trackings(address account) external returns (address);

    /// @dev Method to get account balance, it should give same as balanceOf()
    /// @param account address to query
    function getBalance(address account) external returns (uint256);

    /// @dev Method to add a new dividend distribution
    /// @param totalAmount Total Amount of Dividend
    function addDistDividend(uint256 totalAmount) external;

    /// @dev Method to claim dividends of STO Token
    function claimDividend() external;

    /// @dev Method to check how much amount of dividends the user can claim
    /// @param claimer Address of claimer of STO Token
    /// @return amount of dividends to claim
    function getMaxAmountToClaim(address claimer)
        external
        view
        returns (uint256 amount);

    /// @dev Method to check the index of where to start claiming dividends
    /// @param claimer Address of claimer of STO Token
    /// @return index after the lastClaimedBlock
    function getIndexToClaim(address claimer) external view returns (uint256);

    /// @dev Verify last claimed block for user
    /// @param _address Address to verify
    function lastClaimedBlock(address _address) external view returns (bool);

    /// @dev Method to confiscate STO tokens
    /// @dev This method is only available to the owner of the contract
    /// @param from Array of Addresses of where STO tokens are lost
    /// @param amount Array of Amounts of STO tokens to be confiscated
    /// @param to Address of where STO tokens to be sent
    function confiscate(
        address[] memory from,
        uint[] memory amount,
        address to
    ) external;

    /// @dev Method to enable/disable confiscation feature
    /// @dev This method is only available to the owner of the contract
    function changeConfiscation(bool status) external;

    /// @dev Method to disable confiscation feature forever
    /// @dev This method is only available to the owner of the contract
    function disableConfiscationFeature() external;

    /// @dev Returns the address of the current owner.
    function owner() external returns (address);

    /// @dev Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner.
    function renounceOwnership() external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @notice Can only be called by the current owner.
    function transferOwnership(address newOwner) external;

    /// @dev Maximal amount of STO Tokens that can be minted
    function maxSupply() external view returns (uint256);

    /// @dev address of the minter
    function minter() external view returns (address);

    /// @dev address of the issuer
    function issuer() external view returns (address);

    /// @dev url for offchain records
    function url() external view returns (string memory);

    /// @dev Verify if the address is in the Whitelist
    /// @param adr Address to verify
    function whitelist(address adr) external view returns (bool);

    /// @dev Method to change the issuer address
    /// @dev This method is only available to the owner of the contract
    function changeIssuer(address newIssuer) external;

    /// @dev Method to change the minter address
    /// @dev This method is only available to the owner of the contract
    function changeMinter(address newMinter) external;

    /// @dev Set addresses in whitelist.
    /// @dev This method is only available to the owner of the contract
    /// @param users addresses to be whitelisted
    /// @param statuses statuses to be whitelisted
    function changeWhitelist(address[] calldata users, bool[] calldata statuses)
        external;

    /// @dev Method to setup or update the max supply of the token
    /// @dev This method is only available to the owner of the contract
    function changeMaxSupply(uint supplyCap) external;

    /// @dev Method to mint STO tokens
    /// @dev This method is only available to the owner of the contract
    function mint(address to, uint256 amount) external;

    /// @dev Method to setup or update the URI where the documents of the tokenization are stored
    /// @dev This method is only available to the owner of the contract
    function changeUrl(string memory newURL) external;

    /// @dev Expose the burn method, only the msg.sender can burn his own token
    function burn(uint256 amount) external;
}

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
/// @title STOBeaconProxy
/// @custom:security-contact tech@brickken.com
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        assert(_BEACON_SLOT == bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1));
        _upgradeBeaconToAndCall(beacon, data, false);
    }

	/**
	 * @dev Returns the current beacon address.
	 */
	function getBeacon() external view returns (address) {
		return _beacon();
	}

	/**
	 * @dev Returns the current beacon address.
	 */
	function getImplementation() external view returns (address) {
		return _implementation();
	}

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal  {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

interface IUniPoolV2 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/// @title STOErrors
/// @custom:security-contact tech@brickken.com
abstract contract STOErrors {
    /// User `caller` is not the owner of the contract
    error CallerIsNotOwner(address caller);
    /// User `caller` is not the issuer of the contract
    error CallerIsNotIssuer(address caller);
	/// User `caller` is not the same address of the Claimer Address
    error CallerIsNotClaimer(address caller);
    /// Issuer `issuer` can't start a new Issuance Process if the Previous one has not been Finalized and Withdrawn
    error IssuanceNotFinalized(address issuer);
    /// Issuance start date has not been reached 
    error IssuanceNotStarted(address issuer);
    /// The Initialization of the Issuance Process sent by the Issuer `issuer` is not valid
    error InitialValueWrong(address issuer);
    /// This transaction exceed the Max Supply of STO Token
    error MaxSupplyExceeded();
    /// The issuance collected funds are not withdrawn yet
    error IssuanceNotWithdrawn(address issuer);
    /// The issuance process is not in rollback state
    error IssuanceNotInRollback(uint256 index);
    /// Fired when fees are over 100%
    error FeeOverLimits(uint256 newFee);
    /// The Issuer `issuer` tried to Whitelisted not valid ERC20 Smart Contract (`token`)
    error AddressIsNotContract(address token, address issuer);
    /// The Issuer `issuer` tried to Finalize the Issuance Process before to End Date `endDate`
    error IssuanceNotEnded(address issuer, uint256 endDate);
    /// The Issuer `issuer` tried to Finalize the Issuance Process was Finalized
    error IssuanceWasFinalized(address issuer);
    /// The Issuer `issuer` tried to Withdraw the Issuance Process was Withdrawn
    error IssuanceWasWithdrawn(address issuer);
    /// The Issuer `issuer` tried to Rollback the Issuance Process was Rollbacked
    error IssuanceWasRollbacked(address issuer);
    /// The User `user` tried to refund the ERC20 Token in the Issuance Process was Successful
    error IssuanceWasSuccessful(address user);
    /// The User `user` tried to redeem the STO Token in the Issuance Process was not Successful
    error IssuanceWasNotSuccessful(address user);
    /// The User `user` tried to buy STO Token in the Issuance Process was ended in `endDate`
    error IssuanceEnded(address user, uint256 endDate);
    /// The User `user` tried to buy with ERC20 `token` is not WhiteListed in the Issuance Process
    error TokenIsNotWhitelisted(address token, address user);
    /// The User `user` tried to buy STO Token, and the Amount `amount` exceed the Maximal Ticket `maxTicket`
    error AmountExceeded(address user, uint256 amount, uint256 maxTicket);
	/// the User `user` tried to buy STO Token, and the Amount `amount` is under the Minimal Ticket `minTicket`
	error InsufficientAmount(address user, uint256 amount, uint256 minTicket);
    /// The user `user` tried to buy STO Token, and the Amount `amount` exceed the Amount Available `amountAvailable`
	/// @param user The user address
	/// @param amount The amount of token to buy
	/// @param amountAvailable The amount of token available
    error HardCapExceeded(
        address user,
        uint256 amount,
        uint256 amountAvailable
    );
    /// The User `user` has not enough balance `amount` in the ERC20 Token `token`
    error InsufficientBalance(address user, address token, uint256 amount);
    /// The User `user` tried to buy USDC Token, and the Swap with ERC20 Token `tokenERC20` was not Successful
    error SwapFailure(address user, address tokenERC20, uint256 priceInUSD, uint256 balanceAfter);
    /// The User `user` tried to redeem the ERC20 Token Again! in the Issuance Process with Index `index`
    error RedeemedAlready(address user, uint256 index);
    /// The User `user` tried to be refunded with payment tokend Again! in the Issuance Process with Index `index`
    error RefundedAlready(address user, uint256 index);
    /// The User `user` is not Investor in the Issuance Process with Index `index`
    error NotInvestor(address user, uint256 index);
    /// The Max Amount of STO Token in the Issuance Process will be Raised
    error HardCapRaised();
    /// User `user`,don't have permission to reinitialize the contract
    error UserIsNotOwner(address user);
    /// User is not Whitelisted, User `user`,don't have permission to transfer or call some functions
    error UserIsNotWhitelisted(address user);
	/// At least pair of arrays have a different length
    error LengthsMismatch();
	/// The premint Amount of STO Tokens in the Issuance Process exceeds the Max Amount of STO Tokens
    error PremintGreaterThanMaxSupply();
	/// The Address can't be zero address
	error NotZeroAddress();
	/// The Variable can't be zero
	error NotZeroValue();
	/// The Address is not a Contract
	error NotContractAddress();
	/// The Dividend Amount can't be zero
	error DividendAmountIsZero();
	/// The Wallet `claimer` is not Available to Claim Dividend
	error NotAvailableToClaim(address claimer);
	/// The User `claimer` can't claim
	error NotAmountToClaim(address claimer);
	///The User `user` try to claim an amount `amountToClaim` more than the amount available `amountAvailable`
	error ExceedAmountAvailable(address claimer, uint256 amountAvailable, uint256 amountToClaim);
	/// The User `user` is not the Minter of the STO Token
	error NotMinter(address user);
	/// The Transaction sender by User `user`, with Token ERC20 `tokenERC20` is not valid
	error ApproveFailed(address user, address tokenERC20);
    /// Confiscation Feature is Disabled
    error ConfiscationDisabled();
    // The token is not the payment token
	error InvalidPaymentToken(address token);
}

/// @title STOFactory
/// @custom:security-contact tech@brickken.com
contract STOFactory is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    STOErrors
{
    using AddressUpgradeable for address;
    using MathUpgradeable for uint256;


    address public bkn; // Brickken Token Address
    address public brickkenVault; // Brickken Vault Address
    address public stoBeaconToken; // Beacon Token Address
    address public stoBeaconEscrow; // Beacon Escrow Address

    uint256 public priceInBKN; // Price of STO in BKN
    uint256 public priceInUSD; // Price of STO in USD
    uint256 public idSTOs; // STO ID

    // Mapping of STOTokens and STOEscrows addresses to their respective STO IDs
    mapping(uint256 => address) public stoTokens;
    mapping(uint256 => address) public stoEscrows;
    mapping(address => bool) public whitelist;

    /// @dev Struct with tokenization config
    /// @param url URI for offchain records stored in IPFS referring to one specific tokenization
    /// @param name Name of the STOToken
    /// @param symbol Symbol of the STOToken
    /// @param maxSupply Max Supply of the STOToken, 0 if unlimited supply
    /// @param paymentToken Token used to denominate issuer's withdraw on succesfull tokenization
    /// @param router Uniswap v2 Router address
    /// @param preMints Amounts of the STOToken to be minted to each initial holder
    /// @param initialHolders Wallets of the initial holders of the STOToken
    struct TokenizationConfig {
        string url;
        string name;
        string symbol;
        uint256 maxSupply;
        address paymentToken;
        address router;
        uint256[] preMints;
        address[] initialHolders;
    }

    /// @dev Event emitted when a new STO is created
    /// @param id ID of the STO
    /// @param token smart contract address of the STOToken
    /// @param escrow smart contract address of the STOEscrow
    event NewTokenization(
        uint256 indexed id,
        address indexed token,
        address indexed escrow
    );

    /// @dev Event emitted when wallets are changed in the whitelist
    /// @param addresses Addresses of the wallet to modify in the whitelist
    /// @param owner Owner of the contract that changed the whitelist
    /// @param statuses statuses that indicate if the corresponding address has been either removed or added to the whitelist
    event ChangeWhitelist(
        address[] addresses,
        bool[] statuses,
        address indexed owner
    );

    /// @dev Event emitted when the owner changes the stored beacons addresses for STOToken and STOEscrow
    /// @param newBeaconSTOTokenAddress new beacon address for STOToken
    /// @param newBeaconSTOEscrowAddress new beacon address for STOEscrow
    event ChangeBeaconAddress(
        address indexed newBeaconSTOTokenAddress,
        address indexed newBeaconSTOEscrowAddress
    );

    /// @dev Event emitted when price in BKN and/or USDC changed
    /// @param newPriceInBKN New price in BKN
    /// @param newPriceInUSD New price in USDC
    event ChangeFee(
        uint256 indexed newPriceInBKN,
        uint256 indexed newPriceInUSD
    );

    /// @dev Event emitted when fees are charged for each new tokenization
    /// @param issuer wallet address of the issuer
    /// @param currency token used to pay the fee, usually BKN
    /// @param amount Amount of fees charged
    event ChargeFee(address indexed issuer, string currency, uint256 amount);

    /// @dev Modifier to check if the caller is whitelisted
    modifier onlyWhitelisted() {
        address issuer = _msgSender();
        if (!whitelist[issuer]) revert UserIsNotWhitelisted(issuer);
        _;
    }

    function initialize(
        address beaconToken,
        address beaconEscrow,
        address bknContract,
        address vault,
        address[] calldata _whitelist
    ) public reinitializer(2) {
        ///Prevent anyone from reinitializing the contract
        if (super.owner() != address(0) && _msgSender() != super.owner())
            revert UserIsNotOwner(_msgSender());
        
        if (owner() == address(0)) __Ownable_init();
        
        if (vault == address(0)) revert NotZeroAddress();
        if (!Address.isContract(bknContract)) revert NotContractAddress();
        if (!Address.isContract(IBeacon(beaconToken).implementation())) revert NotContractAddress();
        if (!Address.isContract(IBeacon(beaconEscrow).implementation())) revert NotContractAddress();

        bkn = bknContract;
        brickkenVault = vault;
        stoBeaconToken = beaconToken;
        stoBeaconEscrow = beaconEscrow;

        for(uint256 i; i<_whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    /// @dev Function to paused The Factory Contract
    function pauseFactory() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @dev Function to unpaused The Factory Contract
    function unpauseFactory() external whenPaused onlyOwner {
        _unpause();
    }

    /// @dev Function to add or remove a wallet to the whitelist
    /// @param users Address of the wallet to add or remove to the whitelist
    /// @param statuses Status that indicate if add or remove to the whitelist
    function changeWhitelist(
        address[] calldata users,
        bool[] calldata statuses
    ) external whenNotPaused onlyOwner {
        if (users.length != statuses.length || users.length == 0)
            revert LengthsMismatch();
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = statuses[i];
        }
        emit ChangeWhitelist(users, statuses, _msgSender());
    }

    /// @dev Change the Beacon Smart Contract Address deployed
    /// @dev This Address must be a Smart Contract deployer based on Upgradable Proxy Plugins of OpenZeppelin (both Truffle and Hardhat)
    /// @dev And the Beacon will be upgradeable through JS/TS script (e.g. via Hardhat: `await upgrades.upgradeBeacon(beaconAddress, newImplementation);`)
    /// @param newToken Address of the Beacon Smart Contract for STOToken
    /// @param newEscrow Address of the Beacon Smart Contract for STOEscrow
    function changeBeacon(
        address newToken,
        address newEscrow
    ) external whenNotPaused onlyOwner {
        if (newToken == address(0) || newEscrow == address(0))
            revert NotZeroAddress();
        if (!newToken.isContract() || !newEscrow.isContract())
            revert NotContractAddress();
        stoBeaconToken = newToken;
        stoBeaconEscrow = newEscrow;
        emit ChangeBeaconAddress(newToken, newEscrow);
    }

    /// @dev Method to change the fee price in BKN and USDC
    /// @param newPriceInBKN New price in BKN
    /// @param newPriceInUSD New price in USDC
    function changeFee(
        uint256 newPriceInBKN,
        uint256 newPriceInUSD
    ) external whenNotPaused onlyOwner {
        priceInBKN = newPriceInBKN;
        priceInUSD = newPriceInUSD;
        emit ChangeFee(newPriceInBKN, newPriceInUSD);
    }

    /// @dev Method to deploy a new STO Token
    /// @param config Configuration of the STO Token to be deployed
    function newTokenization(
        TokenizationConfig memory config
    ) external whenNotPaused onlyWhitelisted {
        address issuer = msg.sender;
        _chargeFee(issuer);

        /// By default each new token and escrow is owned by Brickken. Ownership can be hand over at any moment.
        address _owner = owner();

        if (config.initialHolders.length != config.preMints.length)
            revert LengthsMismatch();

        uint256 length = config.preMints.length;

        uint256 totalPremint = 0;

        for (uint256 i = 0; i < length; i++) {
            totalPremint += config.preMints[i];
        }

        if (config.maxSupply != 0 && totalPremint > config.maxSupply)
            revert PremintGreaterThanMaxSupply();

        address stoToken = address(
            new BeaconProxy(
                stoBeaconToken,
                abi.encodeWithSignature(
                    "initialize(string,string,address,uint256,string,uint256[],address[],address)",
                    config.name,
                    config.symbol,
                    issuer,
                    config.maxSupply,
                    config.url,
                    config.preMints,
                    config.initialHolders,
                    config.paymentToken
                )
            )
        );

        address stoEscrow = address(
            new BeaconProxy(
                stoBeaconEscrow,
                abi.encodeWithSignature(
                    "initialize(address,address,address,address,address,address)",
                    stoToken,
                    issuer,
                    _owner,
                    config.paymentToken,
                    config.router,
                    brickkenVault
                )
            )
        );

        ++idSTOs;
        stoTokens[idSTOs] = stoToken;
        stoEscrows[idSTOs] = stoEscrow;

        //Setup the escrow as a valid minter and finally transferOwnership to _owner
        ISTOToken(stoToken).changeMinter(stoEscrow);
        ISTOToken(stoToken).transferOwnership(_owner);

        emit NewTokenization(idSTOs, stoToken, stoEscrow);
    }

    /// @dev Public method to calculate how many BKN are needed in fees
    /// @return amountToPay number of BKNs to be transferred
    function getFeesInBkn() public view returns(uint256 amountToPay) {
        /// by default it takes BKN fixed units of fee
        amountToPay = priceInBKN > 0 ? priceInBKN : 0;

        /// If a fixed fee in dollar is set, it then overwrites it with it
        if (priceInUSD > 0) {

            uint256 priceOfBKNInUSDT = getBKNPrice(); // this returns the price in USD with 18 decimals


            if( priceOfBKNInUSDT != 0 ) amountToPay = priceInUSD.mulDiv(1e18, priceOfBKNInUSDT) + 1; // round up
        }

        return amountToPay;
    }

    function getBKNPrice() public view returns(uint256) {
        /// Uni v2 Pool of BKN / USDT (This is only for ETH Mainnet) 
        (uint112 reserveBKN, uint112 reserveUSDT, uint32 blockTimestampLast) = IUniPoolV2(0x02EcB5f7cb416bC8dd70b84Db295F5b2D98F4125).getReserves();

        uint256 intermediatePrice = uint256(reserveUSDT).mulDiv(1e18, uint256(reserveBKN)) + 1; // round up
        
        // Default to amountToPay = priceInBKN if the price is old more than 15 days
        if(blockTimestampLast < block.timestamp - 60*60*24*15) return 0;
        
        return intermediatePrice * 1e12; 
    }

    /// @dev Internal method to charge the fee in BKN using a fixed USDC or BKN price.
    /// @param user address of the issuer
    function _chargeFee(address user) internal {
        /// by default it takes BKN fixed units of fee
        uint256 amountToPay = getFeesInBkn();

        /// Finally is there any positive amount of BKN to be transferred, transfer them
        if (amountToPay > 0) {
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(bkn),
                user,
                brickkenVault,
                amountToPay
            );
            emit ChargeFee(user, "BKN", amountToPay);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}