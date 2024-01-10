// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./IERCHandler.sol";
import "./IFeeManager.sol";
import "./IHandlerReserve.sol";

/**
    @title Function used across handler contracts.
    @author Router Protocol.
    @notice This contract is intended to be used with the Bridge contract.
 */
contract HandlerHelpersUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable, IERCHandler {
    address public _bridgeAddress;
    address public _oneSplitAddress;
    address public override _ETH;
    address public override _WETH;
    bool public _isFeeEnabled;
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    IFeeManagerUpgradeable public feeManager;
    IHandlerReserve public _reserve;

    // resourceID => token contract address
    mapping(bytes32 => address) internal _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping(address => bytes32) public _tokenContractAddressToResourceID;


    // token contract address => is whitelisted
    mapping(address => bool) public _contractWhitelist;

    // token contract address => is burnable
    mapping(address => bool) public _burnList;

    // bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    function __HandlerHelpersUpgradeable_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _msgSender());
        _isFeeEnabled = false;
    }

    function __HandlerHelpersUpgradeable_init_unchained() internal initializer {}

    // function grantFeeRole(address account) public virtual override onlyRole(BRIDGE_ROLE) {
    //     grantRole(FEE_SETTER_ROLE, account);
    //     totalFeeSetters = totalFeeSetters + 1;
    // }

    // function revokeFeeRole(address account) public virtual override onlyRole(BRIDGE_ROLE) {
    //     revokeRole(FEE_SETTER_ROLE, account);
    //     totalFeeSetters = totalFeeSetters - 1;
    // }

    function setFeeManager(IFeeManagerUpgradeable _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = _feeManager;
    }

    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress)
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return feeManager.getFee(destinationChainID, feeTokenAddress);
    }

    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, transferFee, exchangeFee, accepted);
    }

    function toggleFeeStatus(bool status) public virtual override onlyRole(BRIDGE_ROLE) {
        _isFeeEnabled = status;
    }

    function getFeeStatus() public view virtual override returns (bool) {
        return _isFeeEnabled;
    }

    function resourceIDToTokenContractAddress(bytes32 resourceID) public view virtual override returns (address) {
        return _resourceIDToTokenContractAddress[resourceID];
    }

    /**
        @notice First verifies {_resourceIDToContractAddress}[{resourceID}] and
        {_contractAddressToResourceID}[{contractAddress}] are not already set,
        then sets {_resourceIDToContractAddress} with {contractAddress},
        {_contractAddressToResourceID} with {resourceID},
        and {_contractWhitelist} to true for {contractAddress}.
        @param resourceID ResourceID to be used when making deposits.
        @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
     */
    function setResource(bytes32 resourceID, address contractAddress) public virtual override onlyRole(BRIDGE_ROLE) {
        _setResource(resourceID, contractAddress);
    }

    /**
        @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
        to true.
        @param contractAddress Address of contract to be used when making or executing deposits.
        @param status Boolean flag to change burnable status.
     */
    function setBurnable(address contractAddress, bool status) public virtual override onlyRole(BRIDGE_ROLE) {
        _setBurnable(contractAddress, status);
    }

    /**
        @notice Used to manually release funds from ERC safes.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amount the amount of ERC20 tokens to release.
     */
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override {}

    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override {}

    /**
        @notice Sets oneSplitAddress for the handler
        @param contractAddress Address of oneSplit contract
     */
    function setOneSplitAddress(address contractAddress) public virtual override onlyRole(BRIDGE_ROLE) {
        _setOneSplitAddress(contractAddress);
    }

    /**
        @notice Sets liquidity pool for given ERC20 address. These pools will be used to
        stake and unstake liqudity.
        @param contractAddress Address of contract for which LP contract should be created.
     */
    function setLiquidityPool(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address contractAddress,
        address lpAddress
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        address newLPAddress = _reserve._setLiquidityPool(name, symbol, decimals, contractAddress, lpAddress);
        _contractWhitelist[newLPAddress] = true;
        _setBurnable(newLPAddress, true);
    }

    function setLiquidityPoolOwner(
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve._setLiquidityPoolOwner(newOwner, tokenAddress, lpAddress);
    }

    function _setResource(bytes32 resourceID, address contractAddress) internal virtual {
        require(contractAddress != address(0), "contract address can't be zero");
        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
        _tokenContractAddressToResourceID[contractAddress] = resourceID;
        _contractWhitelist[contractAddress] = true;
    }

    function _setBurnable(address contractAddress, bool status) internal virtual {
        require(_contractWhitelist[contractAddress], "provided contract is not whitelisted");
        _burnList[contractAddress] = status;
    }

    function _setOneSplitAddress(address contractAddress) internal virtual {
        require(contractAddress != address(0), "ERC20Handler: contractAddress cannot be null");
        _oneSplitAddress = address(contractAddress);
    }
}
