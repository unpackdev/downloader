// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20StakedVotesUpgradeable.sol";

contract GatewayGovernanceToken is ERC20StakedVotesUpgradeable {
    mapping(address => bool) private _isLocked;

    /// @dev Jan 03, 2024 10AM PST
    uint256 public constant stakeStoppingDate = 1704304800;

    function initialize(
        string calldata name,
        string calldata symbol,
        uint8 decimals_,
        address admin,
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup,
        IERC20Upgradeable token
    ) public virtual initializer {
        __ERC20StakedVotesUpgradeable_init_unchained(
            name,
            symbol,
            decimals_,
            admin,
            processingCap,
            wrappingRate,
            stakingLockup,
            unstakingLockup,
            token
        );
        __ERC20Permit_init_unchained(name);
        __GatewayGovernanceToken_init_unchained();
    }

    function __GatewayGovernanceToken_init_unchained()
        internal
        onlyInitializing
    {}

    function version() public pure virtual returns (string memory) {
        return "0.1";
    }

    /**
     * @dev allow to get version for EIP712 domain dynamically. We do not need to init EIP712 anymore
     *
     */
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(version()));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *
     */
    function _EIP712NameHash() internal view override returns (bytes32) {
        return keccak256(bytes(name()));
    }

    function chainId() external view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev `burn` but with `burner`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a burn fee amount in Gluwacoin, which the burner will pay for the burn.
     * `sig` is a signature created by signing the burn information with the burner’s private key.
     * Anyone can initiate the burn for the burner by calling the Etherless Burn function
     * with the burn information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Destroys `amount` + `fee` tokens from the burner.
     * Transfers `amount` of base tokens from the contract to the burner and `fee` of base token to the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the burner must have tokens of at least `amount`, the `fee` is included in the amount.
     */
    function burn(
        address burner,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        uint256 burnerBalance = balanceOf(burner);
        require(
            burnerBalance >= amount,
            "ERC20Wrapper: burn amount exceed balance"
        );

        _useWrapperNonce(burner, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Burn,
                block.chainid,
                address(this),
                burner,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, burner, sig);

        _transfer(burner, _msgSender(), fee);
        __burn(burner, amount - fee);
    }

    function lockAccount() external {
        _isLocked[_msgSender()] = true;
    }

    function unlockAccount(address account) external onlyAdmin {
        _isLocked[account] = false;
    }

    function transferLockedAccount(
        address account,
        address recipient,
        uint256 amount,
        bool isLocked_
    ) external onlyAdmin {
        require(
            _isLocked[account],
            "GatewayGovernanceToken: fund must be locked"
        );
        /// @dev allow txn to be processed
        _isLocked[account] = false;
        _transfer(account, recipient, amount);
        _isLocked[account] = isLocked_;
    }

    function isLocked(address account) external view returns (bool) {
        return _isLocked[account];
    }

    function _stakeValidation() internal override {
        require(
            block.timestamp < stakeStoppingDate,
            "GatewayGovernanceToken: Staking is closed"
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20StakedVotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20StakedVotesUpgradeable) {
        /// @dev when a wallet is locked, can't move fund and staking/unstaking.
        require(
            !_isLocked[from] && !_isLocked[to],
            "GatewayGovernanceToken: fund is locked"
        );
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[49] private __gap;
}
