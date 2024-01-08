// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./IERC20.sol";
import "./ECDSAUpgradeable.sol";
import "./ISTETH.sol";

contract EnderBondLiquidityDeposit is Initializable, EIP712Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    string private constant SIGNING_DOMAIN = "depositContract";
    string private constant SIGNATURE_VERSION = "1";

    address public stEth; // address of stEth
    address public lido; // address of lido
    address public signer; // address of signer
    address public admin; // address of admin
    address public enderBond; // address of enderBond
    uint256 public index; // undex is used to track user info
    uint256 public minDepositAmount; // minimum deposit amount for EnderBondLiquidityDeposit
    uint256 public rewardShareIndex; // overall reward share index for users
    bool public depositEnable; // Used for go live on a particular time
    // @notice A mapping that indicates whether a token is bondable.
    mapping(address => bool) public bondableTokens; // To allow a particular token to deposit
    mapping(uint256 => uint256) public rewardSharePerUserIndexStEth; // reward share index of a user at the time of deposit
    mapping(uint256 => uint256) public totalRewardOfUser;
    // mapping(address => bool) public isWhitelisted;
    mapping(uint256 => Bond) public bonds; // user info struct mapping with index

    // user info
    struct Bond {
        address user;
        uint256 principalAmount;
        uint256 totalAmount;
        uint256 bondFees;
        uint256 maturity;
    }

    struct signData {
        address user;
        string key;
        bytes signature;
    }
    error InvalidAmount();
    error InvalidMaturity();
    error InvalidBondFee();
    error ZeroAddress();
    error NotAllowed();
    error NotBondableToken();
    error addressNotWhitelisted();
    event newSigner(address _signer);
    event depositEnableSet(bool depositEnable);
    event MinDepAmountSet(uint256 indexed newAmount);
    event BondableTokensSet(address indexed token, bool indexed isEnabled);
    event WhitelistChanged(address indexed whitelistingAddress, bool indexed action);
    event Deposit(
        address indexed sender,
        uint256 index,
        uint256 bondFees,
        uint256 principal,
        uint256 maturity,
        address token
    );
    event userInfo(
        address indexed user,
        uint256 index,
        uint256 principal,
        uint256 totalAmount,
        uint256 bondFees,
        uint256 maturity
    );

    function initialize(address _stEth, address _lido, address _signer, address _admin) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        stEth = _stEth;
        lido = _lido;
        signer = _signer;
        admin = _admin;
        _transferOwnership(admin);
        bondableTokens[_stEth] = true;
        minDepositAmount = 100000000000000000;
    }

    modifier depositEnabled() {
        if (depositEnable != true) revert NotAllowed();
        _;
    }

    modifier onlyBond() {
        if (msg.sender != enderBond) revert NotAllowed();
        _;
    }

    function setsigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Address can't be zero");
        signer = _signer;
        emit newSigner(signer);
    }

    /**
     * @notice Updates the bondable status for a list of tokens.
     * @dev Sets the bondable status of a list of tokens. Only callable by the contract owner.
     * @param tokens The addresses of the tokens to be updated.
     * @param enabled Boolean value representing whether each token is bondable.
     */
    function setBondableTokens(address[] calldata tokens, bool enabled) external onlyOwner {
        uint256 length = tokens.length;
        for (uint256 i; i < length; ++i) {
            bondableTokens[tokens[i]] = enabled;
            emit BondableTokensSet(tokens[i], enabled);
        }
    }

    /**
     * @notice Updates the minimum deposit amount.
     * @dev Sets the minimum deposit amount. Only callable by the contract owner.
     * @param _amt The amount to be updated.
     */
    function setMinDepAmount(uint256 _amt) public onlyOwner {
        minDepositAmount = _amt;
        emit MinDepAmountSet(_amt);
    }

    /**
     * @notice Updates whether deposit is enabled or not.
     * @dev Sets whether deposit is enabled or not. Only callable by the contract owner.
     * @param _depositEnable true if enabled otherwise false.
     */
    function setDepositEnable(bool _depositEnable) public onlyOwner {
        depositEnable = _depositEnable;
        emit depositEnableSet(depositEnable);
    }

    /**
     * @notice Updates contract addresses.
     * @dev Sets contract addresses. Only callable by the contract owner.
     * @param _addr The address of the token or contracts to be updated.
     * @param _type 1 ==> stETH address, 2 ==> lido adrress, 3 ==> ender bond address.
     */
    function setAddress(address _addr, uint256 _type) public onlyOwner {
        if (_addr == address(0)) revert ZeroAddress();

        if (_type == 1) stEth = _addr;
        else if (_type == 2) lido = _addr;
        else if (_type == 3) enderBond = _addr;
    }

    /**
     * @notice Allows a user to deposit a specified token into a bond
     * @param principal The principal amount of the bond
     * @param maturity The maturity date of the bond (lock time)
     * @param bondFee Self-set bond fee
     * @param token The address of the token (if token is zero address, then depositing ETH)
     * @param userSign To verify user details for whitelisting
     */
    function deposit(
        uint256 principal,
        uint256 maturity,
        uint256 bondFee,
        address token,
        signData memory userSign
    ) external payable nonReentrant depositEnabled {
        if (principal < minDepositAmount) revert InvalidAmount();
        if (maturity < 7 || maturity > 365) revert InvalidMaturity();
        if (token != address(0) && !bondableTokens[token]) revert NotBondableToken();
        if (bondFee < 0 || bondFee > 10000) revert InvalidBondFee();
        address signAddress = _verify(userSign);
        require(signAddress == signer && userSign.user == msg.sender, "user is not whitelisted");
        // token transfer
        if (token == address(0)) {
            if (msg.value != principal) revert InvalidAmount();
            (bool suc, ) = payable(lido).call{value: msg.value}(
                abi.encodeWithSignature("submit(address)", address(this))
            );
            require(suc, "lido eth deposit failed");
        } else {
            // send directly to the deposit contract
            IERC20(token).transferFrom(msg.sender, address(this), principal);
        }
        index++;
        bonds[index] = Bond(
            msg.sender,
            IStEth(stEth).getSharesByPooledEth(principal),
            IStEth(stEth).getSharesByPooledEth(principal),
            bondFee,
            maturity
        );

        emit Deposit(msg.sender, index, bondFee, principal, maturity, token);
    }

    /**
     * @notice This function is call by ender bond contract when ender bond contract go live
     * @param _index this is used to get user info of a particular user
     */
    function depositedIntoBond(
        uint256 _index
    ) external onlyBond returns (address user, uint256 principal, uint256 bondFees, uint256 maturity) {
        principal = IStEth(stEth).getPooledEthByShares(bonds[_index].principalAmount);
        emit userInfo(
            bonds[_index].user,
            index,
            bonds[_index].principalAmount,
            principal,
            bonds[_index].bondFees,
            bonds[_index].maturity
        );
        return (bonds[_index].user, principal, bonds[_index].bondFees, bonds[_index].maturity);
    }

    /**
     * @notice This function is call by Admin address when ender bond contract go live for approval of stEth
     * @param _bond The address of ender bond
     * @param _amount this input is used for approval
     */
    function approvalForBond(address _bond, uint256 _amount) external onlyOwner {
        require(_bond != address(0), "Address can't be zero");
        IERC20(stEth).approve(_bond, _amount);
    }

    function _hash(signData memory userSign) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("userSign(address user,string key)"),
                        userSign.user,
                        keccak256(bytes(userSign.key))
                    )
                )
            );
    }

    /**
     * @notice verifying the owner signature to check whether the user is whitelisted or not
     */
    function _verify(signData memory userSign) internal view returns (address) {
        bytes32 digest = _hash(userSign);
        return ECDSAUpgradeable.recover(digest, userSign.signature);
    }
}
