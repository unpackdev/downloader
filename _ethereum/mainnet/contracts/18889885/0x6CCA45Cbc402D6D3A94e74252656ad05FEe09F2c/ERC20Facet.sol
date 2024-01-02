// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./SolidStateERC20.sol";
import "./Pausable.sol";
import "./IERC20.sol";

import "./IERC20Facet.sol";
import "./LibAccessControlEnumerable.sol";
import "./LibFeeStoreStorage.sol";
import "./LibFeeStore.sol";
import "./LibDiamond.sol";
import "./GenericErrors.sol";
import "./Constants.sol";

/// @title ERC20 Token Facet
/// @author Daniel <danieldegendev@gmail.com>
/// @notice Provides the functionality of an ERC20 token to an EIP-2535 based diamond
/// @custom:version 1.1.0
contract ERC20Facet is SolidStateERC20, Pausable, IERC20Facet {
    /// Storage Slot
    bytes32 internal constant ERC20_FACET_STORAGE_SLOT = keccak256("degenx.erc20.storage.v1.1.0");

    event AddLP(address lp);
    event RemoveLP(address lp);
    event ExcludeAccountFromTax(address account);
    event IncludeAccountToTax(address account);
    event FeeAdded(bytes32 id, bool buyFee);
    event FeeRemoved(bytes32 id, bool buyFee);
    event BridgeSupplyCapUpdated(address bridge, uint256 cap);

    error FeeIdAlreadySet(bytes32 id);
    error FeeIdNotSet(bytes32 id);
    error FeeIdMissing();
    error InvalidFeeId(bytes32 id);
    error NoBurnPossible();
    error BridgeSupplyExceeded(uint256 candidate, uint256 supply);

    /// @param cap maximum tokens to mint for a specific account/contract
    /// @param total currently minted amount of tokens for a specific account/contract
    struct BridgeSupply {
        uint256 cap;
        uint256 total;
    }

    /// @param initialized A flag that defines if the contract is initialized already
    /// @param buyFee An array of bytes32 to configure buy fee ids
    /// @param sellFee An array of bytes32 to configure sell fee ids
    /// @param lps A map of addresses which are identified as a liquidity pool
    /// @param excludes A map of addresses which can get flagged to be from paying fees
    /// @param fees A map of fee ids to its charged amounts
    /// @param bridges A map of fee ids to its charged amounts
    struct ERC20FacetStorage {
        bool initialized;
        bytes32[] buyFee;
        bytes32[] sellFee;
        mapping(address => bool) lps;
        mapping(address => bool) excludes;
        mapping(bytes32 => uint256) fees;
        mapping(address => BridgeSupply) bridges;
    }

    /// Initializes the contract
    /// @param __name The name of the token
    /// @param __symbol The symbol of the token
    /// @param __decimals The number of decimals of the token
    function initERC20Facet(string calldata __name, string calldata __symbol, uint8 __decimals) external {
        LibAccessControlEnumerable.checkRole(Constants.DEPLOYER_ROLE);
        ERC20FacetStorage storage s = _store();
        if (s.initialized) revert("initialized");
        _pause();
        _setName(__name);
        _setSymbol(__symbol);
        _setDecimals(__decimals);
        s.initialized = true;
    }

    /// @inheritdoc IERC20Facet
    function mint(address _to, uint256 _amount) external returns (bool _success) {
        ERC20FacetStorage storage s = _store();
        if (s.bridges[msg.sender].cap == 0) revert NotAllowed();
        s.bridges[msg.sender].total += _amount;
        if (s.bridges[msg.sender].total > s.bridges[msg.sender].cap) revert BridgeSupplyExceeded(_amount, s.bridges[msg.sender].cap);
        _mint(_to, _amount);
        _success = true;
    }

    /// @inheritdoc IERC20Facet
    function burn(uint256 _amount) external returns (bool _success) {
        _burn(msg.sender, _amount);
        _success = true;
    }

    /// @inheritdoc IERC20Facet
    function burn(address _from, uint256 _amount) external returns (bool _success) {
        _success = _burnFrom(_from, _amount);
    }

    /// @inheritdoc IERC20Facet
    function burnFrom(address _from, uint256 _amount) external returns (bool _success) {
        _success = _burnFrom(_from, _amount);
    }

    /// @inheritdoc IERC20Facet
    function enable() external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _unpause();
    }

    /// @inheritdoc IERC20Facet
    function disable() external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        _pause();
    }

    /// @inheritdoc IERC20Facet
    function addLP(address _lp) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        s.lps[_lp] = true;
        emit AddLP(_lp);
    }

    /// @inheritdoc IERC20Facet
    function removeLP(address _lp) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        s.lps[_lp] = false;
        emit RemoveLP(_lp);
    }

    /// @inheritdoc IERC20Facet
    function excludeAccountFromTax(address _account) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        s.excludes[_account] = true;
        emit ExcludeAccountFromTax(_account);
    }

    /// @inheritdoc IERC20Facet
    function includeAccountForTax(address _account) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        delete s.excludes[_account];
        emit IncludeAccountToTax(_account);
    }

    /// @inheritdoc IERC20Facet
    function addBuyFee(bytes32 _id) external {
        _addFee(_id, true);
    }

    /// Removes a buy fee based on a fee id
    /// @param _id fee id
    function removeBuyFee(bytes32 _id) external {
        _removeFee(_id, true);
    }

    /// @inheritdoc IERC20Facet
    function addSellFee(bytes32 _id) external {
        _addFee(_id, false);
    }

    /// Removes a sell fee based on a fee id
    /// @param _id fee id
    function removeSellFee(bytes32 _id) external {
        _removeFee(_id, false);
    }

    /// Updates a supply cap for a specified bridge
    /// @param _bridge address of the bridge
    /// @param _cap supply cap of the bridge
    function updateBridgeSupplyCap(address _bridge, uint256 _cap) external {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        // cap == 0 means revoking bridge role
        s.bridges[_bridge].cap = _cap;
        emit BridgeSupplyCapUpdated(_bridge, _cap);
    }

    /// viewables

    /// Checks if an account is whether excluded from paying fees or not
    /// @param _account account to check
    function isExcluded(address _account) external view returns (bool _isExcluded) {
        ERC20FacetStorage storage s = _store();
        _isExcluded = s.excludes[_account];
    }

    /// Checks whether a fee id is a buy fee or not
    /// @param _id fee id
    function isBuyFee(bytes32 _id) external view returns (bool _itis) {
        _itis = _isFee(_id, true);
    }

    /// Check whether a fee id is a sell fee or not
    /// @param _id fee id
    function isSellFee(bytes32 _id) external view returns (bool _itis) {
        _itis = _isFee(_id, false);
    }

    /// @inheritdoc IERC20Facet
    function hasLP(address _lp) external view returns (bool _has) {
        ERC20FacetStorage storage s = _store();
        _has = s.lps[_lp];
    }

    /// Returns all buy fee ids
    /// @return _fees array of fee ids
    function getBuyFees() external view returns (bytes32[] memory _fees) {
        ERC20FacetStorage storage s = _store();
        _fees = s.buyFee;
    }

    /// Returns all sell fee ids
    /// @return _fees array of fee ids
    function getSellFees() external view returns (bytes32[] memory _fees) {
        ERC20FacetStorage storage s = _store();
        _fees = s.sellFee;
    }

    /// Returns the supply information of the given bridge
    /// @param _bridge address of the bridge
    /// @return _supply bridge supply
    function bridges(address _bridge) external view returns (BridgeSupply memory _supply) {
        _supply = _store().bridges[_bridge];
    }

    /// @notice Returns the owner address
    /// @return _owner owner address
    function getOwner() external view returns (address _owner) {
        _owner = LibDiamond.contractOwner();
    }

    /// internals

    /// Returns if a fee is an actual fee from the buy fees or from the sell fees
    /// @param _id fee id
    /// @param _isBuyFee flag to decide whether it is a buy fee or not
    /// @return _itis returns true if it is a fee
    function _isFee(bytes32 _id, bool _isBuyFee) internal view returns (bool _itis) {
        ERC20FacetStorage storage s = _store();
        bytes32[] storage _fees = _isBuyFee ? s.buyFee : s.sellFee;
        for (uint256 i = 0; i < _fees.length; ) {
            if (_fees[i] == _id) {
                _itis = true;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// Adds a fee based on a fee id and a flag if it should be added as buy fee or sell fee
    /// @param _id fee id
    /// @param _isBuyFee flag if fee id should be processed as buy fee or sell fee
    function _addFee(bytes32 _id, bool _isBuyFee) internal {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        LibFeeStoreStorage.FeeStoreStorage storage feeStore = LibFeeStoreStorage.feeStoreStorage();
        if (_id == bytes32("")) revert FeeIdMissing();
        if (feeStore.feeConfigs[_id].id != _id) revert InvalidFeeId(_id);
        bytes32[] storage _fees = _isBuyFee ? s.buyFee : s.sellFee;
        for (uint256 i = 0; i < _fees.length; ) {
            if (_fees[i] == _id) revert FeeIdAlreadySet(_id);
            unchecked {
                i++;
            }
        }
        _fees.push(_id);
        emit FeeAdded(_id, _isBuyFee);
    }

    /// Removes a fee based on a fee id and a flag if it should be removed as buy fee or sell fee
    /// @param _id fee id
    /// @param _isBuyFee flag if fee id should be processed as buy fee or sell fee
    function _removeFee(bytes32 _id, bool _isBuyFee) internal {
        LibAccessControlEnumerable.checkRole(Constants.ADMIN_ROLE);
        ERC20FacetStorage storage s = _store();
        if (!_isFee(_id, _isBuyFee)) revert FeeIdNotSet(_id);
        bytes32[] storage _fees = _isBuyFee ? s.buyFee : s.sellFee;
        for (uint256 i = 0; i < _fees.length; ) {
            if (_fees[i] == _id) _fees[i] = _fees[_fees.length - 1];
            unchecked {
                i++;
            }
        }
        _fees.pop();
        emit FeeRemoved(_id, _isBuyFee);
    }

    /// Transfers the token from one address to another
    /// @param _from holder address
    /// @param _to receiver address
    /// @param _amount amount of tokens to transfer
    /// @notice During this process, it will be checked if the provided address are a liquidity pool address and then
    ///         being marked as a buy transfer or sell transfer. During a buy or sell, desired fees will be charged.
    ///         But only if non of the addresses is excluded from the fees and the router is set. Since swapping tokens
    ///         during a buy process, it will be only done in a sell process. The charged fees are getting cut of from
    ///         the initial amount of tokens and the rest is getting transfered.
    function _transfer(address _from, address _to, uint256 _amount) internal override returns (bool) {
        ERC20FacetStorage storage s = _store();
        bool isBuy = s.lps[_from];
        bool isSell = s.lps[_to];
        if ((isBuy || isSell) && !s.excludes[_from] && !s.excludes[_to]) {
            uint256 _totalFee = 0;
            bytes32[] storage _fees = isBuy ? s.buyFee : s.sellFee;
            for (uint256 i = 0; i < _fees.length; ) {
                (, uint256 _singleFee, ) = LibFeeStore.calcFeesRelative(_fees[i], address(this), _amount);
                LibFeeStore.putFees(_fees[i], _singleFee);
                _totalFee += _singleFee;
                unchecked {
                    i++;
                }
            }
            if (_totalFee > 0) {
                super._transfer(_from, address(this), _totalFee);
                _amount -= _totalFee;
            }
        }
        return super._transfer(_from, _to, _amount);
    }

    /// Internal method to burn a specified amount of tokens for an address
    /// @param _from address to burn from
    /// @param _amount amount to burn
    /// @return Returns true is it succeeds
    /// @dev It checks if there is an exceeded amount of tokens tried to be burned for a specific bridge
    function _burnFrom(address _from, uint256 _amount) internal returns (bool) {
        ERC20FacetStorage storage s = _store();
        if (s.bridges[msg.sender].cap > 0 || s.bridges[msg.sender].total > 0) {
            if (_amount > s.bridges[msg.sender].total) revert BridgeSupplyExceeded(_amount, s.bridges[msg.sender].total);
            unchecked {
                s.bridges[msg.sender].total -= _amount;
            }
        }
        _decreaseAllowance(_from, msg.sender, _amount);
        _burn(_from, _amount);
        return true;
    }

    /// @dev Store
    function _store() internal pure returns (ERC20FacetStorage storage _s) {
        bytes32 slot = ERC20_FACET_STORAGE_SLOT;
        assembly {
            _s.slot := slot
        }
    }
}
