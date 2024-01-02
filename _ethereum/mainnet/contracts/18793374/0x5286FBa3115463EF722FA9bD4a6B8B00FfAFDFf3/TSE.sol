// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Initializable.sol";
import "./MathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IToken.sol";
import "./ITokenERC1155.sol";
import "./ITSE.sol";
import "./IService.sol";
import "./IPool.sol";
import "./IVesting.sol";
import "./ExceptionsLibrary.sol";
import "./IPausable.sol";
import "./CustomContext.sol";

contract TSE is
    Initializable,
    ReentrancyGuardUpgradeable,
    ITSE,
    ERC2771Context,
    ERC1155HolderUpgradeable
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // CONSTANTS

    uint256 private constant DENOM = 100 * 10 ** 4;

    address public recipient;

    address public seller;

    /// @notice The address of the ERC20/ERC1155 token being distributed in this TSE
    /// @dev Mandatory setting for TSE, only one token can be distributed in a single TSE event
    address public token;

    /// @notice The identifier of the ERC1155 token collection
    /// @dev For ERC1155, there is an additional restriction that units of only one collection of such tokens can be distributed in a single TSE
    uint256 public tokenId;

    /// @dev Parameters for conducting the TSE, described by the ITSE.sol:TSEInfo interface
    TSEInfo public info;

    /**
    * @notice A whitelist of addresses allowed to participate in this TSE
    * @dev A TSE can be public or private. To make the event public, simply leave the whitelist empty.
    The TSE contract can act as an airdrop - a free token distribution. To do this, set the price value to zero.
    To create a DAO with a finite number of participants, each of whom should receive an equal share of tokens, you can set the whitelist when launching the TSE as a list of the participants' addresses, and set both minPurchase and maxPurchase equal to the expression (hardcap / number of participants). To make the pool obtain DAO status only if the distribution is successful under such conditions for all project participants, you can set the softcap value equal to the hardcap. With these settings, the company will become a DAO only if all the initial participants have an equal voting power.
    */
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev The block on which the TSE contract was deployed and the event begins
    uint256 public createdAt;

    /// @dev A mapping that stores the amount of token units purchased by each address that plays a key role in the TSE.
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during the TSE
    uint256 public totalPurchased;

    event Purchased(address buyer, uint256 amount);

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
     * @dev Constructor function, can only be called once. In this method, settings for the TSE event are assigned, such as the contract of the token implemented using TSE, as well as the TSEInfo structure, which includes the parameters of purchase, vesting, and lockup. If no lockup or vesting conditions were set for the TVL value when creating the TSE, then the TVL achievement flag is set to true from the very beginning.
     * @param _token TSE's token
     * @param _tokenId TSE's tokenId
     * @param _tokenId ERC1155TSE's tokenId (token series)
     * @param _info TSE parameters
     */
    function initialize(
        address _token,
        uint256 _tokenId,
        TSEInfo calldata _info,
        address _seller,
        address _recipient
    ) external initializer {
        __ReentrancyGuard_init();

        //if tse is creating for erc20 token
        tokenId = _tokenId;

        token = _token;

        info = _info;

        seller = _seller;

        recipient = _recipient;

        for (uint256 i = 0; i < _info.userWhitelist.length; i++) {
            _isUserWhitelisted[_info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS
    receive() external payable {}

    function purchase(
        uint256 amount
    )
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) / 1 ether;
        uint256 serviceFee = getServiceFee(purchasePrice);
        uint256 partnerFee = getPartnerFee(purchasePrice);
        uint256 balance = 0;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice + serviceFee + partnerFee,
                ExceptionsLibrary.WRONG_AMOUNT
            );
            if (serviceFee != 0) {
                payable(IToken(token).service().protocolTreasury()).sendValue(
                    serviceFee
                );
            }
            if (partnerFee != 0) {
                payable(IToken(token).partnerAddress()).sendValue(partnerFee);
            }
            balance = address(this).balance;

            if (recipient != address(0)) {
                payable(recipient).sendValue(balance);
            } else {
                payable(seller).sendValue(balance);
            }
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                _msgSender(),
                address(this),
                purchasePrice + serviceFee + partnerFee
            );

            if (serviceFee != 0) {
                IERC20Upgradeable(unitOfAccount).safeTransfer(
                    IToken(token).service().protocolTreasury(),
                    serviceFee
                );
            }
            if (partnerFee != 0) {
                IERC20Upgradeable(unitOfAccount).safeTransfer(
                    IToken(token).partnerAddress(),
                    partnerFee
                );
            }

            balance = IERC20Upgradeable(unitOfAccount).balanceOf(address(this));
            if (recipient != address(0)) {
                IERC20Upgradeable(unitOfAccount).safeTransfer(
                    recipient,
                    balance
                );
            } else {
                IERC20Upgradeable(unitOfAccount).safeTransfer(seller, balance);
            }
        }

        this.proceedPurchase(_msgSender(), amount);
    }

    function externalPurchase(
        address account,
        uint256 amount
    )
        external
        onlyManager
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        try this.proceedPurchase(account, amount) {
            return;
        } catch {
            _refund(account, amount);
            return;
        }
    }

    function finishTSE() external whenPoolNotPaused {
        require(_msgSender() == seller, ExceptionsLibrary.INVALID_USER);
        info.amount = totalPurchased;

        if (isERC1155TSE()) {
            ITokenERC1155(token).transfer(
                address(this),
                seller,
                tokenId,
                ITokenERC1155(token).balanceOf(address(this), tokenId)
            );
        } else {
            IToken(token).transfer(
                seller,
                IToken(token).balanceOf(address(this))
            );
        }

        IToken(token).service().registry().log(
            _msgSender(),
            address(this),
            0,
            abi.encodeWithSelector(ITSE.finishTSE.selector)
        );
    }

    // RESTRICTED FUNCTIONS

    function _refund(address account, uint256 amount) private {
        uint256 refundValue = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(account).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                account,
                refundValue
            );
        }
    }

    // VIEW FUNCTIONS

    /**
     * @dev Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TSE.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.amount - totalPurchased
            );
    }

    function state() public view returns (State) {
        // If hardcap is reached TSE is successfull
        if (totalPurchased == info.amount) {
            return State.Successful;
        }

        // If deadline not reached TSE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If totalPurchased > 0  TSE is successfull
        if (block.number > createdAt + info.duration && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TSE
        return State.Failed;
    }

    /**
     * @dev The given getter shows how much info.unitofaccount was collected within this TSE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price.
     * @return uint256 Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10 ** 18;
    }

    function getServiceFee(uint256 amount) public view returns (uint256) {
        return (amount * IToken(token).service().serviceFee()) / DENOM;
    }

    function getPartnerFee(uint256 amount) public view returns (uint256) {
        return (amount * IToken(token).partnerFee()) / DENOM;
    }

    /**
     * @dev This method returns the full list of addresses allowed to participate in the TSE.
     * @return address An array of whitelist addresses
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted.
     * @param account User address
     * @return 'True' if the whitelist is empty (public TSE) or if the address is found in the whitelist, 'False' otherwise.
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    /**
     * @dev This method indicates whether this event was launched to implement ERC1155 tokens.
     * @return bool Flag if ERC1155 TSE
     */
    function isERC1155TSE() public view returns (bool) {
        return tokenId == 0 ? false : true;
    }

    /**
     * @dev Returns the block number at which the event ends.
     * @return uint256 Block number
     */
    function getEnd() external view returns (uint256) {
        return createdAt + info.duration;
    }

    function getInfo() external view returns (TSEInfo memory) {
        return info;
    }

    function validatePurchase(
        address account,
        uint256 amount
    ) public view returns (bool) {
        return
            amount > 0 &&
            amount >= info.minPurchase &&
            amount <= maxPurchaseOf(account);
    }

    //PRIVATE FUNCTIONS

    function proceedPurchase(address account, uint256 amount) public {
        require(_msgSender() == address(this), ExceptionsLibrary.INVALID_USER);

        require(
            validatePurchase(account, amount),
            ExceptionsLibrary.INVALID_PURCHASE_AMOUNT
        );

        // Accrue TSE stats
        totalPurchased += amount;
        purchaseOf[account] += amount;

        if (isERC1155TSE()) {
            ITokenERC1155(token).transfer(
                address(this),
                account,
                tokenId,
                amount
            );
        } else {
            IToken(token).transfer(account, amount);
        }

        // Emit event
        emit Purchased(account, amount);

        IToken(token).service().registry().log(
            account,
            address(this),
            0,
            abi.encodeWithSelector(ITSE.purchase.selector, amount)
        );
    }

    // MODIFIER

    /// @notice Modifier that allows the method to be called only if the TSE state is equal to the specified state.
    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that is whitelisted for the TSE or if the TSE is created as public.
    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(_msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only by an account that has the ADMIN role in the Service contract.
    modifier onlyManager() {
        IService service = IToken(token).service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), _msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    /// @notice Modifier that allows the method to be called only if the pool associated with the event is not in a paused state.
    modifier whenPoolNotPaused() {
        require(
            !IPausable(IToken(token).pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }

    modifier onlyCompanyManager() {
        IRegistry registry = IToken(token).service().registry();
        require(
            registry.hasRole(registry.COMPANIES_MANAGER_ROLE(), _msgSender()),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    function getTrustedForwarder() public view override returns (address) {
        return IToken(token).service().getTrustedForwarder();
    }

    function _msgSender() internal view override returns (address sender) {
        return super._msgSender();
    }

    function _msgData() internal view override returns (bytes calldata) {
        return super._msgData();
    }
}
