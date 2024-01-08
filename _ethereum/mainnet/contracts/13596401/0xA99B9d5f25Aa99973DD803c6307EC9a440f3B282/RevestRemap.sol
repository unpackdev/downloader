// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./AccessControlEnumerable.sol";
import "./ERC165Checker.sol";
import "./IRevest.sol";
import "./IAddressRegistry.sol";
import "./ILockManager.sol";
import "./IInterestHandler.sol";
import "./ITokenVault.sol";
import "./IRewardsHandler.sol";
import "./IOracleDispatch.sol";
import "./IOutputReceiver.sol";
import "./IAddressLock.sol";
import "./RevestAccessControl.sol";
import "./RevestReentrancyGuard.sol";
import "./IUnicryptV2Locker.sol";
import "./IWETH.sol";
import "./FNFTHandler.sol";

/**
 * This is the entrypoint for the frontend, as well as third-party Revest integrations.
 * Solidity style guide ordering: receive, fallback, external, public, internal, private - within a grouping, view and pure go last - https://docs.soliditylang.org/en/latest/style-guide.html
 */
contract RevestRemap is IRevest, AccessControlEnumerable, RevestAccessControl, RevestReentrancyGuard {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes4 public constant ADDRESS_LOCK_INTERFACE_ID = type(IAddressLock).interfaceId;

    address immutable WETH;

    uint public erc20Fee = 0; // out of 1000
    uint private constant erc20multiplierPrecision = 1000;
    uint public flatWeiFee = 0;
    uint private constant MAX_INT = 2**256 - 1;
    mapping(address => bool) private approved;

    /**
     * @dev Primary constructor to create the Revest controller contract
     * Grants ADMIN and MINTER_ROLE to whoever creates the contract
     *
     */
    constructor(address provider, address weth) RevestAccessControl(provider) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        WETH = weth;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev creates a single time-locked NFT with <quantity> number of copies with <amount> of <asset> stored for each copy
     * asset - the address of the underlying ERC20 token for this bond
     * amount - the amount to store per NFT if multiple NFTs of this variety are being created
     * unlockTime - the timestamp at which this will unlock
     * quantity – the number of FNFTs to create with this operation     */
    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable override returns (uint) {
        
    }

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable override returns (uint) {
        
    }

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable override returns (uint) {
        
    }

    function withdrawFNFT(uint fnftId, uint quantity) external override revestNonReentrant(fnftId) {
        
    }

    function unlockFNFT(uint fnftId) external override {}

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external override returns (uint[] memory) {}

    /// @return the new (or reused) ID
    function extendFNFTMaturity(
        uint fnftId,
        uint endTime
    ) external returns (uint) {
        
    }

    // Admin function to remap output receiver to new staking contract
    function remapFNFTs(uint[] memory fnftIds, address newStaking) external onlyOwner {
        address vault = addressesProvider.getTokenVault();
        for(uint i = 0; i < fnftIds.length; i++) {
            uint id = fnftIds[i];
            IRevest.FNFTConfig memory config = ITokenVault(vault).getFNFT(id);
            config.pipeToContract = newStaking;
            ITokenVault(vault).mapFNFTToToken(id, config);
        }
    }

    function remapAddLocks(uint[] memory fnftIds, address[] memory newLocks, bytes[] memory data) external onlyOwner {
        for(uint i = 0; i < fnftIds.length; i++) {
            IRevest.LockParam memory addressLock;
            addressLock.addressLock = newLocks[i];
            addressLock.lockType = IRevest.LockType.AddressLock;
            // Get or create lock based on address which can trigger unlock, assign lock to ID
            uint lockId = getLockManager().createLock(fnftIds[i], addressLock);

            if(newLocks[i].supportsInterface(ADDRESS_LOCK_INTERFACE_ID)) {
                IAddressLock(newLocks[i]).createLock(fnftIds[i], lockId, data[i]);
            }
        }
    }


    /**
     * Amount will be per FNFT. So total ERC20s needed is amount * quantity.
     * We don't charge an ETH fee on depositAdditional, but do take the erc20 percentage.
     * Users can deposit additional into their own
     * Otherwise, if not an owner, they must distribute to all FNFTs equally
     */
    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external override returns (uint) {
        return 0;
    }

    /**
     * @dev Returns the cached IAddressRegistry connected to this contract
     **/
    function getAddressesProvider() external view returns (IAddressRegistry) {
        return addressesProvider;
    }

    //
    // INTERNAL FUNCTIONS
    //

    function doMint(
        address[] memory recipients,
        uint[] memory quantities,
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint weiValue
    ) internal {
        

    }

    function burn(
        address account,
        uint id,
        uint amount
    ) internal {
        address fnftHandler = addressesProvider.getRevestFNFT();
        require(IFNFTHandler(fnftHandler).getSupply(id) - amount >= 0, "E025");
        IFNFTHandler(fnftHandler).burn(account, id, amount);
    }

    function setFlatWeiFee(uint wethFee) external override onlyOwner {
        flatWeiFee = wethFee;
    }

    function setERC20Fee(uint erc20) external override onlyOwner {
        erc20Fee = erc20;
    }

    function getFlatWeiFee() external view override returns (uint) {
        return flatWeiFee;
    }

    function getERC20Fee() external view override returns (uint) {
        return erc20Fee;
    }
}
