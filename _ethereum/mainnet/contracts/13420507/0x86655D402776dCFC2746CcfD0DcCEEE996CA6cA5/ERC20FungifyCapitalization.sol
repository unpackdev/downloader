// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC20Lockup.sol";

abstract contract ERC20FungifyCapitalization is
    Context,
    AccessControlEnumerable,
    ERC20,
    ERC20Lockup
{

    using SafeERC20 for IERC20;

    //
    // Events
    //

    event AllocationSet(
        address indexed fromAddress,
        address indexed toAddress,
        uint256 indexed usdcQuota
    );

    event TokenDistribution(
        address indexed account,
        uint256 indexed tokenAmount
    );

    //
    // Constants
    //

    /* Roles */

    // A role used for managing the capitalization whitelist.
    bytes32 private constant ALLOCATOR_ROLE = keccak256("ALLOCATOR_ROLE");

    /* Addresses */

    IERC20 private constant USDC = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));

    /* Token supply */

    // A fixed supply for the lifetime of the token.
    // solhint-disable-next-line var-name-mixedcase
    uint256 public immutable TOTAL_TOKEN_SUPPLY = 1_000_000_000 * (10 ** decimals());

    //
    // State
    //

    /* Addresses */

    // Address that holds the initial mint, and from which capitalization is done.
    address public treasuryAddress;

    // Tracking whether the capitalization component has been initialized, and the minting has been done.
    bool public capitalizationInitialized = false;

    /* Capitalization payout ratio */

    // A valuation, denominated in USDC, used to determine token distribution during capitalization.
    uint256 public capitalizationValue;

    /* Capitalization allocation list */

    struct Allocation
    {
        // The address sending in USDC for capitalization.
        address toAddress;

        // The amount of USDC that may be redeemed for tokens.
        uint256 usdcQuota;
    }

    mapping ( address => Allocation ) public allocList;

    //
    // Constructor
    //

    /**
     * @dev Constructor for the capitalization component.
     *
     * @param _treasuryAddress The address to which the initial supply of tokens should be minted, and which will be
     * the admin for the capitalization component after the initial deployer renounces its role.
     *
     * Requirements:
     *
     * - Must provide a valid treasury address.
     */
    constructor(
        address _treasuryAddress
    )
    {
        require(
            _treasuryAddress != address(0),
            "Zero treasury address"
        );

        treasuryAddress = _treasuryAddress;

        // Deployer will have both admin and allocator roles initially, but will renounce them.
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            _msgSender()
        );

        _setupRole(
            ALLOCATOR_ROLE,
            _msgSender()
        );

        // The treasury address is the same as the timelock contract operated by the DAO, so it gets these roles too.
        _setupRole(
            DEFAULT_ADMIN_ROLE,
            _treasuryAddress
        );

        _setupRole(
            ALLOCATOR_ROLE,
            _treasuryAddress
        );
    }

    //
    // State changing functions
    //

    /* Capitalization init */

    /**
     * @dev This function does the initial setup for capitalization, including minting the fixed supply, distributing
     * the team, and granting the team the allocator role for managing the allocation list.
     *
     * @param _capitalizationValue The initial valuation, in USDC, to be used for capitalization.
     * @param _teamMembers An array of team wallet addresses.
     * @param _teamPortions An array of percentages for each team member, dividing the 25% team portion of the total
     * token supply.  These are expressed as tenths of a percent, e.g. a portion of uint256(250) corresponds to that
     * team member getting 25% of 25% of the tokens.
     *
     * Requirements:
     *
     * - Must be called by an allocator.
     * - Can only be called once.
     * - Capitalization value must be non-zero.
     * - Team data array lengths must match.
     */
    function initializeCapitalization(
        uint256 _capitalizationValue,
        address[] memory _teamMembers,
        uint256[] memory _teamPortions
    )
    external
    onlyRole(ALLOCATOR_ROLE)
    {
        require(
            capitalizationInitialized == false,
            "Already initialized"
        );

        require(
            _capitalizationValue > 0,
            "Zero capitalization value"
        );

        require(
            _teamMembers.length == _teamPortions.length,
            "Team data array length mismatch"
        );

        capitalizationValue = _capitalizationValue;

        // Mint the total supply of tokens.
        _mint(
            treasuryAddress,
            TOTAL_TOKEN_SUPPLY
        );

        for ( uint256 i = 0; i < _teamMembers.length; i++ )
        {
            // Distribute the tokens to the team members, with vesting.
            _teamDistribution(
                _teamMembers[i],
                _teamPortions[i]
            );

            // All team members are granted the allocator role for the initial raise.
            grantRole(
                ALLOCATOR_ROLE,
                _teamMembers[i]
            );
        }

        capitalizationInitialized = true;
    }

    /**
     * @dev This function does the distribution of tokens to team members, and sets the vesting schedule.
     *
     * @param _toAddress The team member wallet address.
     * @param _portion The percentage of the team portion given to this team member, expressed as tenths of a percent.
     */
    function _teamDistribution(
        address _toAddress,
        uint256 _portion
    )
    internal
    {
        // This is 25% * portion% * token supply, adjusted for uint math.
        uint256 tokenAmount = ( _portion * TOTAL_TOKEN_SUPPLY ) / ( 4 * 1000 );

        // Send tokens from treasury to team member.
        _transfer(
            treasuryAddress,
            _toAddress,
            tokenAmount
        );

        // Add team vesting lockup entries.  Half the tokens vest over a two year period, vesting monthly.
        for ( uint256 i = 0; i < 24; i++ )
        {
            _addTokenLock(
                _toAddress,
                // Half of the tokens, divided into 24 parts (months).
                ( ( tokenAmount / 2 ) / 24 ),
                // The two years are split into 24 even periods, approximating months.
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + ( ( i * ( 2 * 365 days ) ) / 24 )
            );
        }
    }

    /**
     * @dev This function allows allocators to reset the capitalization value.
     *
     * @param _capitalizationValue The valuation, in USDC, to be used for capitalization.
     *
     * Requirements:
     *
     * - Must be called by an allocator.
     */
    function setCapitalizationValue(
        uint256 _capitalizationValue
    )
    external
    onlyRole(ALLOCATOR_ROLE)
    {
        capitalizationValue = _capitalizationValue;
    }

    /* Allocation management */

    /**
     * @dev This function sets the data in an allocation list entry, either creating or updating the entry.
     *
     * @param _fromAddress The address which will be sending the USDC.
     * @param _toAddress The address to which the tokens should be distributed.
     * @param _usdcQuota The amount of USDC that may be redeemed for tokens by `_toAddress`.
     *
     * Requirements:
     *
     * - Must be called by an allocator.
     * - Addresses must be non-zero.
     */
    function setAllocation(
        address _fromAddress,
        address _toAddress,
        uint256 _usdcQuota
    )
    public
    onlyRole(ALLOCATOR_ROLE)
    {
        require(
            _fromAddress != address(0),
            "Zero from address"
        );

        require(
            _toAddress != address(0),
            "Zero to address"
        );

        allocList[_fromAddress] = Allocation(
            {
                toAddress: _toAddress,
                usdcQuota: _usdcQuota
            }
        );

        emit AllocationSet(
            _fromAddress,
            _toAddress,
            _usdcQuota
        );
    }

    /**
     * @dev This function sets the data for multiple allocation list entries, either creating or updating the entries.
     *
     * @param _fromAddresses The addresses which will be sending the USDC.
     * @param _toAddresses The addresses to which the tokens should be distributed.
     * @param _usdcQuotas The amount of USDC that may be redeemed for tokens by `_toAddresses`.
     *
     * Requirements:
     *
     * - Must be called by an allocator.
     * - Array lengths must be non-zero.
     * - Array lengths must match.
     */
    function setAllocationBatch(
        address[] memory _fromAddresses,
        address[] memory _toAddresses,
        uint256[] memory _usdcQuotas
    )
    external
    onlyRole(ALLOCATOR_ROLE)
    {
        uint256 batchLength = _fromAddresses.length;

        require(
            batchLength != 0,
            "Zero batch length"
        );

        require(
            _toAddresses.length == batchLength,
            "Batch length mismatch"
        );

        require(
            _usdcQuotas.length == batchLength,
            "Batch length mismatch"
        );

        for ( uint256 i = 0; i < batchLength; i++ )
        {
            setAllocation(
                _fromAddresses[i],
                _toAddresses[i],
                _usdcQuotas[i]
            );
        }
    }

    // TODO: Add mass allocation function.

    /**
     * @dev This function deletes an allocation from the allocation list.
     *
     * @param _fromAddress The address for which the allocation list entry should be deleted.
     *
     * Requirements:
     *
     * - Must be called by an allocator.
     */
    function clearAllocation(
        address _fromAddress
    )
    external
    onlyRole(ALLOCATOR_ROLE)
    {
        Allocation memory alloc = allocList[_fromAddress];

        delete allocList[_fromAddress];

        emit AllocationSet(
            _fromAddress,
            alloc.toAddress,
            0
        );
    }

    /* Capitalization */

    /**
     * @dev This function is called by people on the allocation list in order to deposit USDC in exchange for tokens.
     *
     * @param _usdcAmount The amount of USDC being deposited.
     * @param _termsAgreement This must be set to 0xACC in order to indicate acceptance of the terms and conditions.
     *
     * Terms & Conditions: ipfs://QmfAKFbB2C13MgoLUbJQTbXpG4NkxquckCuWPGYUqSgAdt
     *
     * Requirements:
     *
     * - Terms and conditions must be accepted.
     * - USDC amount must be less than or equal to the remaining quota.
     * - USDC transfer must be allowed.
     */
    function contributeCapital(
        uint256 _usdcAmount,
        uint256 _termsAgreement
    )
    external
    {
        require(
            _termsAgreement == 0xACC,
            "Terms not accepted"
        );

        require(
            _usdcAmount <= allocList[_msgSender()].usdcQuota,
            "Not enough USDC quota"
        );

        USDC.safeTransferFrom(
            _msgSender(),
            treasuryAddress,
            _usdcAmount
        );
        
        uint256 tokenAmount = usdcToTokensDuringCapitalization(_usdcAmount);

        _transfer(
            treasuryAddress,
            allocList[_msgSender()].toAddress,
            tokenAmount
        );

        _addTokenLock(
            allocList[_msgSender()].toAddress,
            tokenAmount,
            // Six month lockup, approximated as 180 days.
            // solhint-disable-next-line not-rely-on-time
            block.timestamp + ( 180 days )
        );

        allocList[_msgSender()].usdcQuota -= _usdcAmount;

        emit TokenDistribution(
            allocList[_msgSender()].toAddress,
            tokenAmount
        );
    }

    //
    // Views
    //

    /**
     * @dev Provides a multiplier for number of tokens to be paid out in exchange for a given amount of USDC.
     *
     * @param _usdcAmount Amount of USDC to be converted to a number of tokens.
     *
     * @return A number of tokens.
     */
    function usdcToTokensDuringCapitalization(
        uint256 _usdcAmount
    )
    public
    view
    returns (uint256)
    {
        return ( ( _usdcAmount * totalSupply() ) / capitalizationValue );
    }

    //
    // Override functions
    //

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * @param from See {ERC20-_beforeTokenTransfer}.
     * @param to See {ERC20-_beforeTokenTransfer}.
     * @param amount See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
    internal
    virtual
    override(ERC20, ERC20Lockup)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}