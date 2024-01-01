// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./LERC20.sol";
import "./IAccess.sol";

/**
 * @title NTZCToken
 * @notice Contract for the NTZCToken
 * @dev All function calls are currently implemented without side effects
 */
contract NTZCToken is Initializable, PausableUpgradeable, LERC20Upgradeable {
    using AddressUpgradeable for address;

    // Events
    event CommissionUpdate(uint256 percent, string data);
    event DelegateApprove(
        address caller,
        address owner,
        address spender,
        uint256 amount
    );
    event DelegateTransfer(
        address caller,
        address sender,
        address recipient,
        uint256 amount
    );
    event FeeWalletUpdated(address feeWallet);
    event SellingWalletUpdated(address sellingWallet);
    event AllowedContractUpdated(address contractAddr, bool isAllowed);
    event FreeOfFeeContractUpdated(address contractAddr, bool isFree);

    uint256 public mintingProofsCounter;
    uint256 public burningProofsCounter;
    uint8 private decimal;

    uint256 public TRANSFER_FEE_PERCENT; // Commission percentage on transfer
    uint256 public PERCENT_COEFFICIENT; // Denominator for percentage calculation

    address public feeWallet;
    address public sellingWallet;
    address public accessControl;

    mapping(uint256 => string) public mintingProofs;
    mapping(uint256 => string) public burningProofs;
    mapping(address => bool) public allowedContracts;
    mapping(address => bool) public freeOfFeeContracts;

    // Modifiers
    modifier onlyOwner() {
        require(
            IAccess(accessControl).isOwner(msg.sender),
            "NTZCToken: Only the owner is allowed"
        );
        _;
    }

    modifier onlyManager() {
        require(
            IAccess(accessControl).isSender(msg.sender),
            "NTZCToken: Only managers are allowed"
        );
        _;
    }

    modifier onlyAllowedContracts() {
        require(
            (address(msg.sender).isContract() &&
                allowedContracts[msg.sender]) ||
                !address(msg.sender).isContract(),
            "NTZCToken: Contract doesn't have permission to transfer tokens"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _sellingWallet,
        address _feeWallet,
        address _accessControl
    ) external initializer {
        __LERC20_init(
            "NTZCToken",
            "NTZC",
            msg.sender,
            msg.sender,
            86400,
            address(0xe91D7cEBcE484070fc70777cB04F7e2EfAe31DB4)
        );
        __Pausable_init();
        feeWallet = _feeWallet;
        sellingWallet = _sellingWallet;
        accessControl = _accessControl;
        decimal = 8;
        TRANSFER_FEE_PERCENT = 1; // 0.001%
        PERCENT_COEFFICIENT = 100000; // 100000 = 100%, minimum value is 0.001%.
    }

    /**
     * @notice Prevent the contract from accepting ETH
     * @dev Contracts can still be sent ETH with self-destruct. If anyone deliberately does that, the ETH will be lost
     */
    receive() external payable {
        revert("Contract does not accept ethers");
    }

    /**
     * @notice Pause all operations with NTZC
     * @dev Only the owner can call this function
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause all operations with NTZC
     * @dev Only the owner can call this function
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Update addresses of contracts that are allowed to transfer tokens
     * @dev Only the owner can call this function
     * @param _contractAddress The address of the contract
     * @param _isAllowed Bool variable that indicates whether the contract is allowed to transfer tokens
     */
    function updateAllowedContracts(
        address _contractAddress,
        bool _isAllowed
    ) external onlyOwner {
        allowedContracts[_contractAddress] = _isAllowed;
        emit AllowedContractUpdated(_contractAddress, _isAllowed);
    }

    /**
     * @notice Update addresses of contracts that are free of transfer fee
     * @dev Only the owner can call this function
     * @param _contractAddress The address of the contract
     * @param _isFree Bool variable that indicates whether the contract is free of transfer fee
     */
    function updateFreeOfFeeContracts(
        address _contractAddress,
        bool _isFree
    ) external onlyOwner {
        freeOfFeeContracts[_contractAddress] = _isFree;
        emit FreeOfFeeContractUpdated(_contractAddress, _isFree);
    }

    /**
     * @notice Burn tokens from contract
     * @dev Only the owner can call this function, tokens will be transferred, and an equivalent amount of ZToken will be burnt.
     * @param signature Minters signature
     * @param _value The amount of tokens to be transferred
     * @param _hashes The array of IPFS hashes of the gold burn proofs
     */
    function burn(
        bytes memory signature,
        bytes32 token,
        uint256 _value,
        string[] memory _hashes
    ) external onlyManager whenNotPaused {
        require(_hashes.length > 0, "NTZCToken: No proofs provided");
        require(_value > 0, "NTZCToken: Value must be greater than 0");
        bytes32 message = burnProof(token, _value, _hashes);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isMinter(signer),
            "NTZCToken: Signer is not minter"
        );
        for (uint256 i = 0; i < _hashes.length; i++) {
            burningProofs[burningProofsCounter] = _hashes[i];
            burningProofsCounter++;
        }
        _burn(sellingWallet, _value);
    }

    /**
     * @notice Minting of NTZC tokens backed by gold tokens
     * @param signature Minters signature
     * @param _value The amount transferred
     * @param _hashes The array of IPFS hashes of the gold mint proofs
     */
    function mint(
        bytes memory signature,
        bytes32 token,
        uint256 _value,
        string[] memory _hashes
    ) public onlyManager whenNotPaused {
        require(_hashes.length > 0, "NTZCToken: No proofs provided");
        require(_value > 0, "NTZCToken: Value must be greater than 0");
        bytes32 message = mintProof(token, _value, _hashes);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isMinter(signer),
            "NTZCToken: Signer is not minter"
        );
        for (uint256 i = 0; i < _hashes.length; i++) {
            mintingProofs[mintingProofsCounter] = _hashes[i];
            mintingProofsCounter++;
        }
        _mint(sellingWallet, _value);
    }

    /**
     * @notice Delegate approve for manager contract only.
     * @param signature Sign of the user who wants to delegate approve
     * @param owner User who wants to delegate approve
     * @param spender Contract-spender of user funds
     * @param amount The amount of allowance
     * @param networkFee Commission for manager for delegate transaction sending
     */
    function delegateApprove(
        bytes memory signature,
        bytes32 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 networkFee
    )
        external
        whenNotPaused
        onlyManager
        lssAprove(owner, spender, amount)
        returns (bool)
    {
        bytes32 message = delegateApproveProof(
            token,
            owner,
            spender,
            amount,
            networkFee
        );
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(signer == owner, "NTZCToken: Signer is not owner");
        _privateTransfer(owner, feeWallet, networkFee, false);
        _approve(owner, spender, amount);
        emit DelegateApprove(msg.sender, owner, spender, amount);
        return true;
    }

    /**
     * @notice Delegate transfer.
     * @param signature Sign of the user who wants to delegate approve
     * @param owner User who wants to delegate approve
     * @param spender Contract-spender of user funds
     * @param amount The amount of allowance
     * @param networkFee Commission for manager for delegate transaction sending
     */
    function delegateTransfer(
        bytes memory signature,
        bytes32 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 networkFee
    )
        external
        whenNotPaused
        onlyManager
        lssTransfer(owner, spender, amount)
        returns (bool)
    {
        bytes32 message = delegateTransferProof(
            token,
            owner,
            spender,
            amount,
            networkFee
        );
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(signer == owner, "NTZCToken: Signer is not owner");
        _privateTransfer(owner, feeWallet, networkFee, false);
        _privateTransfer(owner, spender, amount, true);
        emit DelegateTransfer(msg.sender, owner, spender, amount);
        return true;
    }

    /**
     * @dev Get the message hash for signing for burn NTZC
     */
    function burnProof(
        bytes32 token,
        uint256 _value,
        string[] memory _hashes
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(getChainID(), token, _value, _hashes[0])
        );
    }

    /**
     * @dev Get the message hash for signing for mint NTZC
     */
    function mintProof(
        bytes32 token,
        uint256 _value,
        string[] memory _hashes
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(getChainID(), _value, token, _hashes[0])
        );
    }

    // Overridden functions
    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }

    /**
     * @notice Standard transfer function to transfer tokens
     * @param recipient Receiver's address
     * @param amount The amount to be transferred
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        whenNotPaused
        onlyAllowedContracts
        lssTransfer(msg.sender, recipient, amount)
        returns (bool)
    {
        _privateTransfer(msg.sender, recipient, amount, true);
        return true;
    }

    /**
     * @notice Standard transferFrom. Send tokens on behalf of spender
     * @param sender Transfer token from account
     * @param recipient Receiver's address
     * @param amount The amount to be transferred
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        whenNotPaused
        onlyAllowedContracts
        lssTransferFrom(sender, recipient, amount)
        returns (bool)
    {
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        _privateTransfer(sender, recipient, amount, true);
        return true;
    }

    /**
     * @notice Get message for the user's delegate approve signature
     */
    function delegateApproveProof(
        bytes32 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 networkFee
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(
                getChainID(),
                token,
                owner,
                spender,
                amount,
                networkFee
            )
        );
    }

    /**
     * @notice Get message for the user's delegate transfer signature
     */
    function delegateTransferProof(
        bytes32 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 networkFee
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(
                getChainID(),
                token,
                amount,
                owner,
                spender,
                networkFee
            )
        );
    }

    /**
     * @notice Update the address at which fees are transferred
     * @dev Only the owner can call this function
     * @param _feeWallet The fee address
     */
    function updateFeeWallet(address _feeWallet) public onlyOwner {
        require(
            _feeWallet != address(0),
            "NTZCToken: Zero address is not allowed"
        );
        feeWallet = _feeWallet;
        emit FeeWalletUpdated(_feeWallet);
    }

    /**
     * @notice Update the address at which tokens are sold
     * @dev Only the owner can call this function
     * @param _sellingWallet The selling address
     */
    function updateSellingWallet(address _sellingWallet) public onlyOwner {
        require(
            _sellingWallet != address(0),
            "NTZCToken: Zero address is not allowed"
        );
        sellingWallet = _sellingWallet;
        emit SellingWalletUpdated(_sellingWallet);
    }

    /**
     * @notice Update commission to be charged on token transfer
     * @dev Only the owner can call this function
     * @param _transferFeePercent The commission percent
     */
    function updateCommissionTransfer(
        uint256 _transferFeePercent
    ) public onlyOwner {
        require(
            _transferFeePercent <= PERCENT_COEFFICIENT,
            "NTZCToken: Commission cannot be more than 100%"
        );
        TRANSFER_FEE_PERCENT = _transferFeePercent;
        emit CommissionUpdate(TRANSFER_FEE_PERCENT, "Transfer commission");
    }

    /**
     * @notice Calculate transfer fee
     * @param _amount The intended amount of transfer
     * @return uint256 Calculated commission
     */
    function calculateCommissionTransfer(
        uint256 _amount
    ) public view returns (uint256) {
        return (_amount * TRANSFER_FEE_PERCENT) / PERCENT_COEFFICIENT;
    }

    /**
     * @dev Get the ID of the executing chain
     * @return uint value
     */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @notice Internal method to handle transfer logic
     * @param _from Sender address
     * @param _recipient Recipient address
     * @param _amount Amount of tokens to be transferred
     * @return bool
     */
    function _privateTransfer(
        address _from,
        address _recipient,
        uint256 _amount,
        bool _feeMode
    ) internal returns (bool) {
        require(
            _recipient != address(0),
            "ERC20: transfer to the zero address"
        );
        uint256 fee = calculateCommissionTransfer(_amount);
        if (fee > 0 && !freeOfFeeContracts[msg.sender] && _feeMode) {
            _transfer(_from, feeWallet, fee);
        }
        _transfer(_from, _recipient, _amount);
        return true;
    }
}
