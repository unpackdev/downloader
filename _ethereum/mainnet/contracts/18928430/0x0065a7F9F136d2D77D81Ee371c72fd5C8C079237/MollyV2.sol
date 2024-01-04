// SPDX-License-Identifier: MIT

import "./MerkleProofLib.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20.sol";
import "./ERC20Upgradeable.sol";
import "./Ownable2StepUpgradeable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

/**
 * @title MollyV2 ERC20 Contract
 */

pragma solidity 0.8.20;

contract MollyV2 is ERC20Upgradeable, Ownable2StepUpgradeable, EIP712, UUPSUpgradeable {
    /// @custom:storage-location erc7201:molly.storage.version.one
    struct MollyStorage {
        address controllerWallet; //  ─┐ 20
        uint96 swapTokensAtAmount; // ─┘ 12
        address uniswapV2Pair; //     ─┐ 20
        uint16 sellFees; //            │ 2
        uint16 buyFees; //             │ 2
        bool restrictionLifted; //     │ 1
        bool swapping; //              │ 1
        bool tradingActive; //         │ 1
        bool swapEnabled; //          ─┘ 1
        address admin; //             ── 20
        bytes32 merkleRoot; //        ── 32
        bytes32 verifyRoot; //        ── 32
        bytes32 privateMerkleRoot; // ── 32
        uint256 accumulatedFees; //   ── 32
        mapping(address => bool) _isExcludedFromFees;
        mapping(address => bool) automatedMarketMakerPairs;
        mapping(uint256 => uint256) blockSwaps;
        mapping(address => bool) isAngelBuyer;
        mapping(address => bool) isPrivateSaleBuyer;
        mapping(address => bool) isVerified;
        mapping(address => bool) isBlacklisted;
    }

    // keccak256(abi.encode(uint256(keccak256("molly.storage.version.one")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant MOLLY_STORAGE_LOCATION = 0xaf55c982f34119f23f18c6e7a8f26e157a325f42412af363a36aa8341c186900;

    IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public constant DEAD_ADDRESS = address(0xdead);

    uint256 public constant ANGEL_DAILY_DECREASE = 75;
    uint256 public constant FEE_DENOMINATOR = 10_000;
    uint256 public constant INITIAL_ANGEL_FEE = 9000;
    uint256 public constant INITIAL_PRIVATE_FEE = 8000;
    uint256 public constant MAX_SUPPLY = 100_000_000_000 * 1 ether;
    uint256 public constant PRIVATE_DAILY_DECREASE = 89;
    uint256 public constant START_DATE = 1_702_742_015; //OG Molly start timestamp

    event AngelClaimed(address indexed user, uint256 amount);
    event ControllerWalletUpdated(address indexed newWallet, address indexed oldWallet);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event PrivateSaleClaimed(address indexed user, uint256 amount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    error AlreadyClaimed();
    error AlreadyVerified();
    error Blacklisted();
    error CannotRemovePair();
    error ExceedsMaxSupply();
    error InvalidAmount();
    error InvalidProof();
    error InvalidSignature();
    error MerkleRootNotSet();
    error OnlyAdmin();
    error OnlyVerified();
    error TransferRestricted();
    error TradingSuspended();
    error TradingActive();
    error UnauthorizedCalled();

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __ERC20_init("Molly", "MOLLY");

        address _uniswapV2Pair =
            IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), UNISWAP_V2_ROUTER.WETH());

        _getStorage().uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(address(_uniswapV2Pair), true);

        _getStorage().swapTokensAtAmount = 1_000_000 * 1 ether;
        _getStorage().controllerWallet = 0x65849de03776Ef05A9C88E367B395314999826ed;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(DEAD_ADDRESS, true);

        _getStorage().buyFees = 700;
        _getStorage().sellFees = 700;

        _getStorage().admin = msg.sender;
    }

    receive() external payable { }

    /**
     * @notice Verify a user using MerkleProof verification.
     * @dev Verifies that the user's data is a valid MerkleProof. Marks user as verified if successful.
     * @param _merkleProof The Data to verify.
     */
    function verifyUser(bytes32[] calldata _merkleProof) external {
        if (_getStorage().isVerified[msg.sender]) revert AlreadyVerified();
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        if (!MerkleProofLib.verify(_merkleProof, _getStorage().verifyRoot, leaf)) revert InvalidProof();
        _getStorage().isVerified[msg.sender] = true;
    }

    /**
     * @notice Claim tokens allocated for Angel Sale participants.
     * @dev Requires user to be verified and to provide a valid merkle proof. Transfers the specified amount of tokens.
     * @param _amount The amount of tokens to claim.
     * @param _merkleProof The merkle proof proving the allocation.
     */
    function claimAngelSale(uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (_getStorage().merkleRoot == 0) revert MerkleRootNotSet();
        if (!_getStorage().isVerified[msg.sender]) revert OnlyVerified();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        if (!MerkleProofLib.verify(_merkleProof, _getStorage().merkleRoot, leaf)) revert InvalidProof();
        if (_getStorage().isAngelBuyer[msg.sender]) revert AlreadyClaimed();
        _getStorage().isAngelBuyer[msg.sender] = true;
        _transfer(address(this), msg.sender, _amount);
        emit AngelClaimed(msg.sender, _amount);
    }

    /**
     * @notice Claim tokens allocated for Private Sale participants.
     * @dev Similar to claimAngelSale but for Private Sale allocations.
     * @param _amount The amount of tokens to claim.
     * @param _merkleProof The merkle proof proving the allocation.
     */
    function claimPrivateSale(uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (_getStorage().privateMerkleRoot == 0) revert MerkleRootNotSet();
        if (!_getStorage().isVerified[msg.sender]) revert OnlyVerified();

        bytes32 leaf = keccak256(abi.encodePacked((msg.sender), _amount));

        if (!MerkleProofLib.verify(_merkleProof, _getStorage().privateMerkleRoot, leaf)) revert InvalidProof();
        if (_getStorage().isPrivateSaleBuyer[msg.sender]) revert AlreadyClaimed();

        _getStorage().isPrivateSaleBuyer[msg.sender] = true;
        _transfer(address(this), msg.sender, _amount);

        emit PrivateSaleClaimed(msg.sender, _amount);
    }

    /**
     * @notice Use to transfer tokens to another address if sender is angel/private sale buyer.
     * @dev Becomes obsolete once the restriction is lifted.
     * @param recipient The address to send tokens to.
     * @param amount The total amount of tokens to send.
     * @param signature The signature signed by the recipient.
     */
    function transferRestrictedTokens(address recipient, uint256 amount, bytes memory signature) external {
        if (!_validateSignature(msg.sender, recipient, signature)) revert InvalidSignature();

        if (_getStorage().isAngelBuyer[msg.sender]) {
            _getStorage().isAngelBuyer[recipient] = true;
        } else if (_getStorage().isPrivateSaleBuyer[msg.sender]) {
            _getStorage().isPrivateSaleBuyer[recipient] = true;
        }
        _getStorage().restrictionLifted = true;
        _transfer(msg.sender, recipient, amount);
        _getStorage().restrictionLifted = false;
    }

    /**
     * @notice View function to get the current dynamic fee for private sale buyers.
     * @dev Calculates the fee based on the time elapsed since start date. Fee decreases daily.
     * @return uint256 The current fee percentage.
     */
    function getCurrentFee() public view returns (uint256) {
        uint256 daysPassed = (block.timestamp - START_DATE) / 60 / 60 / 24;

        // Check if the fee would go negative and return 0 in that case
        if (daysPassed * PRIVATE_DAILY_DECREASE >= INITIAL_PRIVATE_FEE) {
            return 0;
        }

        // Calculate the current fee, knowing now it won't underflow
        uint256 currentFee = INITIAL_PRIVATE_FEE - (daysPassed * PRIVATE_DAILY_DECREASE);

        return currentFee;
    }

    /**
     * @notice View function to get the current dynamic fee for angel investors.
     * @dev Similar to getCurrentFee but with different parameters for angel investors.
     * @return uint256 The current fee percentage.
     */
    function getCurrentAngelFee() public view returns (uint256) {
        uint256 daysPassed = (block.timestamp - START_DATE) / 60 / 60 / 24;

        // Check if the fee would go negative and return 0 in that case
        if (daysPassed * ANGEL_DAILY_DECREASE >= INITIAL_ANGEL_FEE) {
            return 0;
        }

        // Calculate the current fee, knowing now it won't underflow
        uint256 currentFee = INITIAL_ANGEL_FEE - (daysPassed * ANGEL_DAILY_DECREASE);

        return currentFee;
    }

    /**
     * @notice Returns private sale status for _address.
     * @param _address The address to check.
     * @return bool status of _address.
     */
    function isPrivateSaleBuyer(address _address) external view returns (bool) {
        return _getStorage().isPrivateSaleBuyer[_address];
    }

    /**
     * @notice Returns angel sale status for _address.
     * @param _address The address to check.
     * @return bool status of _address.
     */
    function isAngelBuyer(address _address) external view returns (bool) {
        return _getStorage().isAngelBuyer[_address];
    }

    /**
     * @notice Returns verification status for _address.
     * @param _address The address to check.
     * @return bool status of _address.
     */
    function isVerified(address _address) external view returns (bool) {
        return _getStorage().isVerified[_address];
    }

    /**
     * @notice Returns current buy fees.
     */
    function buyFees() external view returns (uint256) {
        return _getStorage().buyFees;
    }

    /**
     * @notice Returns current sell fees.
     */
    function sellFees() external view returns (uint256) {
        return _getStorage().sellFees;
    }

    /**
     * @notice Returns the address of the controllerWallet.
     */
    function controllerWallet() external view returns (address) {
        return _getStorage().controllerWallet;
    }

    /**
     * @notice Returns the status ow whether pair is an AMM pair.
     * @param pair The address to check.
     * @return bool status of pair.
     */
    function isAutomatedMarketMakerPair(address pair) external view returns (bool) {
        return _getStorage().automatedMarketMakerPairs[pair];
    }

    /**
     * @notice Returns the merkle root used in verifyUser.
     */
    function verifyRoot() external view returns (bytes32) {
        return _getStorage().verifyRoot;
    }

    /**
     * @notice Returns the merkle root used in claimAngelSale.
     */
    function merkleRoot() external view returns (bytes32) {
        return _getStorage().merkleRoot;
    }

    /**
     * @notice Returns the merkle root used in claimPrivateSale.
     */
    function privateMerkleRoot() external view returns (bytes32) {
        return _getStorage().privateMerkleRoot;
    }

    /**
     * @notice Returns the status of swapEnabled.
     */
    function swapEnabled() external view returns (bool) {
        return _getStorage().swapEnabled;
    }

    /**
     * @notice Returns the status of whether account is excluded from paying fees.
     * @param account The address to check.
     * @return bool status of account.
     */
    function isExcludedFromFees(address account) external view returns (bool) {
        return _getStorage()._isExcludedFromFees[account];
    }

    /**
     * @notice Returns the value of swapTokensAtAmount.
     */
    function swapTokensAtAmount() external view returns (uint256) {
        return _getStorage().swapTokensAtAmount;
    }

    /**
     * @notice Returns the address of admin.
     */
    function admin() external view returns (address) {
        return _getStorage().admin;
    }

    /**
     * @notice Returns the status of whether user is blacklisted.
     * @param user The address to check.
     * @return bool status of user.
     */
    function isBlacklisted(address user) external view returns (bool) {
        return _getStorage().isBlacklisted[user];
    }

    /**
     * @notice Returns the address of uniswapV2Pair.
     */
    function uniswapV2Pair() external view returns (address) {
        return _getStorage().uniswapV2Pair;
    }

    //                             //
    // Access Controlled Functions //
    //                             //

    /**
     * @notice Update buy and sell fees for transactions.
     * @dev Only callable by the contract owner. Sets fees for buy and sell transactions.
     * @param _buyFee The fee percentage to set for buy transactions.
     * @param _sellFee The fee percentage to set for sell transactions.
     */
    function updateFees(uint16 _buyFee, uint16 _sellFee) external onlyOwner {
        _getStorage().buyFees = _buyFee;
        _getStorage().sellFees = _sellFee;
    }

    /**
     * @notice Update the controllerWallet that receives fees.
     * @dev Only callable by the contract owner.
     * @param newControllerWallet The address of the new controllerWallet.
     */
    function updateControllerWallet(address newControllerWallet) external onlyOwner {
        emit ControllerWalletUpdated(newControllerWallet, _getStorage().controllerWallet);
        _getStorage().controllerWallet = newControllerWallet;
    }

    /**
     * @notice Airdrop tokens to multiple addresses.
     * @dev Distributes specified amounts of tokens to a list of addresses. Only callable by the owner.
     * @param addresses Array of addresses to receive tokens.
     * @param amounts Array of token amounts corresponding to the addresses.
     */
    function distributeTokens(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amounts[i]);
        }
        if (totalSupply() > MAX_SUPPLY) revert ExceedsMaxSupply();
    }

    /**
     * @notice Sets the verification status for an array of addresses.
     * @dev Only callable by the owner.
     * @param _addresses Array of addresses to set verification status for.
     * @param _state bool status to set all _addresses.
     */
    function bulkSetVerified(address[] calldata _addresses, bool _state) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _getStorage().isVerified[_addresses[i]] = _state;
        }
    }

    /**
     * @notice Sets the private sale status for an array of addresses.
     * @dev Only callable by the owner.
     * @param _addresses Array of addresses to set private sale status for.
     * @param _state bool status to set all _addresses.
     */
    function bulkSetPrivateBuyers(address[] calldata _addresses, bool _state) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _getStorage().isPrivateSaleBuyer[_addresses[i]] = _state;
        }
    }

    /**
     * @notice Sets the angel sale status for an array of addresses.
     * @dev Only callable by the owner.
     * @param _addresses Array of addresses to set angel sale status for.
     * @param _state bool status to set all _addresses.
     */
    function bulkSetAngelBuyers(address[] calldata _addresses, bool _state) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _getStorage().isAngelBuyer[_addresses[i]] = _state;
        }
    }

    /**
     * @notice Sets the merkle root used in user verification.
     * @dev Only callable by the owner.
     * @param _verifyRoot new merkle root.
     */
    function setVerifyRoot(bytes32 _verifyRoot) external onlyOwner {
        _getStorage().verifyRoot = _verifyRoot;
    }

    /**
     * @notice Sets the merkle root used to control angel sale claims.
     * @dev Only callable by the owner.
     * @param _merkleRoot new merkle root.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _getStorage().merkleRoot = _merkleRoot;
    }

    /**
     * @notice Sets the merkle root used to control private sale claims.
     * @dev Only callable by the owner.
     * @param _merkleRoot new merkle root.
     */
    function setPrivateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _getStorage().privateMerkleRoot = _merkleRoot;
    }

    /**
     * @notice Update the state of swap functionality.
     * @dev Emergency function to enable/disable contract's ability to swap. Only callable by the contract owner.
     * @param enabled Boolean to enable or disable swapping.
     */
    function updateSwapEnabled(bool enabled) external onlyOwner {
        _getStorage().swapEnabled = enabled;
    }

    /**
     * @notice Exclude an address from paying transaction fees.
     * @dev Only callable by the contract owner. Can be used to exclude certain addresses like presale contracts from
     * fees.
     * @param account The address to exclude.
     * @param excluded Boolean to indicate if the address should be excluded.
     */
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _getStorage()._isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    /**
     * @notice Allows the owner to manually swap tokens for ETH.
     * @dev Only callable by the controller wallet. Swaps specified token amount for ETH.
     * @param amount The amount of tokens to swap.
     */
    function manualSwap(uint256 amount) external {
        if (msg.sender != owner() && msg.sender != _getStorage().controllerWallet) revert UnauthorizedCalled();
        if (amount > balanceOf(address(this)) || amount == 0) revert InvalidAmount();

        swapTokensForEth(amount);
    }

    /**
     * @notice Manually transfer ETH from contract to controller wallet.
     * @dev Function to send all ETH balance of the contract to the controller wallet. Only callable by the owner.
     */
    function manualWithdraw() external {
        if (msg.sender != owner() && msg.sender != _getStorage().controllerWallet) revert UnauthorizedCalled();

        bool success;
        (success,) = address(_getStorage().controllerWallet).call{ value: address(this).balance }("");
    }

    /**
     * @notice Set or unset a pair as an Automated Market Maker pair.
     * @dev Only callable by the contract owner. Useful for adding/removing liquidity pools.
     * @param pair The address of the pair to update.
     * @param value Boolean to set the pair as AMM pair or not.
     */
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        if (pair == _getStorage().uniswapV2Pair) revert CannotRemovePair();

        _setAutomatedMarketMakerPair(pair, value);
    }

    /**
     * @notice Open trading on Uniswap by providing initial liquidity.
     * @dev Only callable by the contract owner. Approves Uniswap router and adds liquidity using contract's balance.
     */
    function openTrading(uint256 _amount) external payable onlyOwner {
        _approve(address(this), address(UNISWAP_V2_ROUTER), MAX_SUPPLY);
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: address(this).balance }(
            address(this), _amount, 0, 0, owner(), block.timestamp
        );

        IERC20(_getStorage().uniswapV2Pair).approve(address(UNISWAP_V2_ROUTER), type(uint256).max);

        _getStorage().tradingActive = true;
        _getStorage().swapEnabled = true;
    }

    /**
     * @notice Update the state of swap enabled and trading active.
     * @dev Emergency function to enable/disable contract's ability to trade tokens. Only callable by the contract
     * owner.
     * @param _status Boolean to enable or disable trading.
     */
    function emergencyToggleTrading(bool _status) external onlyOwner {
        _getStorage().tradingActive = _status;
        _getStorage().swapEnabled = _status;
    }

    /**
     * @notice Update the minimum token amount required before swapped for ETH.
     * @dev Only callable by the contract owner. Sets the threshold amount that triggers swap and liquify.
     * @param newAmount The new threshold amount in tokens.
     */
    function updateSwapTokensAtAmount(uint96 newAmount) external onlyOwner {
        _getStorage().swapTokensAtAmount = newAmount * 1 ether;
    }

    /**
     * @notice Updates the value of admin.
     * @dev Only callable by the contract owner.
     * @param _admin The new admin address.
     */
    function setAdmin(address _admin) external onlyOwner {
        _getStorage().admin = _admin;
    }

    /**
     * @notice Blacklists a user, preventing them from transfering or receiving tokens.
     * @dev Only callable by the admin.
     * @param _user User to blacklist.
     * @param _status Blacklist status.
     */
    function blacklistUser(address _user, bool _status) external {
        _onlyAdmin();
        _getStorage().isBlacklisted[_user] = _status;
    }

    //                    //
    // Internal Functions //
    //                    //

    function getDigest(address sender, address recipient) public view returns (bytes32) {
        return _hashTypedData(keccak256(abi.encode(sender, recipient)));
    }

    function _validateSignature(
        address sender,
        address recipient,
        bytes memory signature
    )
        internal
        view
        returns (bool)
    {
        bytes32 digest = _hashTypedData(keccak256(abi.encode(sender, recipient)));
        address signer = ECDSA.recover(digest, signature);
        return signer == recipient;
    }

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory contractName, string memory version)
    {
        contractName = "Molly";
        version = "1";
    }

    /**
     * @notice Swap contract's tokens for ETH and handle liquidity and controller wallet transfers.
     * @dev Private function to facilitate swap and liquify. Called within _transfer when conditions are met.
     */
    function swapBack() private {
        uint256 contractBalance = _getStorage().accumulatedFees;
        bool success;

        if (contractBalance == 0) {
            return;
        }

        swapTokensForEth(contractBalance);

        uint256 totalETH = address(this).balance;
        _getStorage().accumulatedFees = 0;
        (success,) = address(_getStorage().controllerWallet).call{ value: totalETH }("");
    }

    /**
     * @notice Swap tokens in contract for ETH and send to controller wallet.
     * @dev Private function to swap contract's token balance for ETH. Used in swapBack mechanism.
     * @param tokenAmount The amount of tokens to swap.
     */
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_V2_ROUTER.WETH();

        _approve(address(this), address(UNISWAP_V2_ROUTER), tokenAmount);

        // make the swap
        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _onlyAdmin() internal view {
        if (msg.sender != _getStorage().admin) {
            revert OnlyAdmin();
        }
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (from == address(0)) {
            super._update(from, to, amount);
            return;
        }

        if (_getStorage().isBlacklisted[from] || _getStorage().isBlacklisted[to]) {
            revert Blacklisted();
        }

        if (!_getStorage().automatedMarketMakerPairs[to] && to != _getStorage().controllerWallet) {
            if (START_DATE + 120 days > block.timestamp && !_getStorage().restrictionLifted) {
                if (_getStorage().isAngelBuyer[from]) revert TransferRestricted();
            }
            if (START_DATE + 90 days > block.timestamp && !_getStorage().restrictionLifted) {
                if (_getStorage().isPrivateSaleBuyer[from]) revert TransferRestricted();
            }
        }

        if (from != owner() && to != owner() && to != address(0) && to != DEAD_ADDRESS && !_getStorage().swapping) {
            if (!_getStorage().tradingActive) {
                if (!_getStorage()._isExcludedFromFees[from] && !_getStorage()._isExcludedFromFees[to]) {
                    revert TradingSuspended();
                }
            }
        }

        uint256 contractTokenBalance = _getStorage().accumulatedFees;

        bool canSwap = contractTokenBalance >= _getStorage().swapTokensAtAmount;

        if (
            canSwap && _getStorage().swapEnabled && !_getStorage().swapping
                && !_getStorage().automatedMarketMakerPairs[from] && !_getStorage()._isExcludedFromFees[from]
                && !_getStorage()._isExcludedFromFees[to]
        ) {
            // Limit swaps per block
            if (_getStorage().blockSwaps[block.number] < 3) {
                _getStorage().swapping = true;

                swapBack();

                _getStorage().swapping = false;

                _getStorage().blockSwaps[block.number] = _getStorage().blockSwaps[block.number] + 1;
            }
        }

        bool takeFee = !_getStorage().swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_getStorage()._isExcludedFromFees[from] || _getStorage()._isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 additionalFees;

        if (takeFee) {
            // on sell

            if (_getStorage().automatedMarketMakerPairs[to]) {
                if (_getStorage().isAngelBuyer[from]) {
                    additionalFees = (amount * getCurrentAngelFee()) / FEE_DENOMINATOR;
                    if (additionalFees > 0) _transfer(from, _getStorage().controllerWallet, additionalFees);
                } else if (_getStorage().isPrivateSaleBuyer[from]) {
                    additionalFees = (amount * getCurrentFee()) / FEE_DENOMINATOR;
                    if (additionalFees > 0) _transfer(from, _getStorage().controllerWallet, additionalFees);
                }
                fees = (amount * _getStorage().sellFees) / FEE_DENOMINATOR;
            }
            // on buy
            else if (_getStorage().automatedMarketMakerPairs[from]) {
                if (_getStorage().isAngelBuyer[to]) {
                    additionalFees = (amount * getCurrentAngelFee()) / FEE_DENOMINATOR;
                    if (additionalFees > 0) _transfer(from, _getStorage().controllerWallet, additionalFees);
                } else if (_getStorage().isPrivateSaleBuyer[to]) {
                    additionalFees = (amount * getCurrentFee()) / FEE_DENOMINATOR;
                    if (additionalFees > 0) _transfer(from, _getStorage().controllerWallet, additionalFees);
                }
                fees = (amount * (_getStorage().buyFees)) / FEE_DENOMINATOR;
            }

            if (fees > 0) {
                _getStorage().accumulatedFees += fees;
                super._update(from, address(this), fees);
            }

            amount -= (fees + additionalFees);
        }
        super._update(from, to, amount);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        _getStorage().automatedMarketMakerPairs[pair] = value;
    }

    function _getStorage() private pure returns (MollyStorage storage $) {
        assembly {
            $.slot := MOLLY_STORAGE_LOCATION
        }
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner { }
}
