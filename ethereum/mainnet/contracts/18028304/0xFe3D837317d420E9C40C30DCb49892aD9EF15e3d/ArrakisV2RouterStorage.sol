// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IRouterSwapExecutor.sol";
import "./IWETH.sol";
import "./IPermit2.sol";
import "./IArrakisV2.sol";
import "./IArrakisV2Resolver.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./EnumerableSet.sol";
import "./SArrakisV2Router.sol";

abstract contract ArrakisV2RouterStorage is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    IWETH public immutable weth;
    IArrakisV2Resolver public immutable resolver;
    IPermit2 public immutable permit2;

    mapping(address => EnumerableSet.AddressSet) internal _mintWhitelist;
    mapping(address => MintRules) public mintRestrictedVaults;
    IRouterSwapExecutor public swapper;

    event LogWhitelist(address vault, address[] whitelisted);
    event LogBlacklist(address vault, address[] blacklisted);
    event LogSetVault(address vault, uint256 supplyCap, bool hasWhitelist);

    event Swapped(
        bool zeroForOne,
        uint256 amount0Diff,
        uint256 amount1Diff,
        uint256 amountOutSwap
    );

    constructor(
        address weth_,
        address resolver_,
        address permit2_
    ) {
        require(
            weth_ != address(0) &&
                resolver_ != address(0) &&
                permit2_ != address(0),
            "Z"
        );
        weth = IWETH(weth_);
        resolver = IArrakisV2Resolver(resolver_);
        permit2 = IPermit2(permit2_);
    }

    receive() external payable {} // solhint-disable-line no-empty-blocks

    function initialize(address owner_) external initializer {
        require(owner_ != address(0), "Z");
        __Pausable_init();
        __ReentrancyGuard_init();
        _transferOwnership(owner_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice updates address of ArrakisV2SwaprExecutor used by this contract
    /// @param swapper_ the RouterSwapExecutor address
    function updateSwapExecutor(address swapper_) external onlyOwner {
        require(swapper_ != address(0), "Z");
        swapper = IRouterSwapExecutor(swapper_);
    }

    function setMintRules(
        address vault_,
        uint256 supplyCap_,
        bool hasWhitelist_
    ) external onlyOwner {
        require(supplyCap_ > 0, "zero");
        address minter = IArrakisV2(vault_).restrictedMint();
        require(minter == address(this), "must be minter");
        mintRestrictedVaults[vault_] = MintRules({
            supplyCap: supplyCap_,
            hasWhitelist: hasWhitelist_
        });

        emit LogSetVault(vault_, supplyCap_, hasWhitelist_);
    }

    function whitelist(address vault_, address[] memory toWhitelist_)
        external
        onlyOwner
    {
        require(mintRestrictedVaults[vault_].supplyCap > 0, "vault not set");
        for (uint256 i; i < toWhitelist_.length; i++) {
            require(_mintWhitelist[vault_].add(toWhitelist_[i]), "add failed");
        }

        emit LogWhitelist(vault_, toWhitelist_);
    }

    function blacklist(address vault_, address[] memory toBlacklist_)
        external
        onlyOwner
    {
        require(mintRestrictedVaults[vault_].supplyCap > 0, "vault not set");
        for (uint256 i; i < toBlacklist_.length; i++) {
            require(
                _mintWhitelist[vault_].remove(toBlacklist_[i]),
                "remove failed"
            );
        }

        emit LogBlacklist(vault_, toBlacklist_);
    }

    function getWhitelist(address vault_)
        external
        view
        returns (address[] memory)
    {
        return _mintWhitelist[vault_].values();
    }
}
