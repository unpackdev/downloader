// SPDX-License-Identifier: MITs
pragma solidity 0.8.18;

import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ITroveDebt.sol";
import "./ITroveManager.sol";
import "./WadRayMath.sol";
import "./Errors.sol";

contract TroveDebt is ContextUpgradeable, OwnableUpgradeable, ITroveDebt {
    using SafeMathUpgradeable for uint256;
    using WadRayMath for uint256;

    ITroveManager internal troveManager;

    mapping(address => uint256) internal _balances;

    uint256 internal _totalSupply;

    /**
     * @dev Only troveManager can call functions marked by this modifier
     **/
    modifier onlyTroveManager() {
        if (_msgSender() != address(troveManager)) {
            revert Errors.Caller_NotCM();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setAddress(address _troveManagerAddress) external onlyOwner {
        _requireIsContract(_troveManagerAddress);
        troveManager = ITroveManager(_troveManagerAddress);
    }

    function balanceOf(
        address user
    ) public view virtual override returns (uint256) {
        uint256 scaledBalance = _balances[user];
        if (scaledBalance == 0) {
            return 0;
        }
        return scaledBalance.rayMul(troveManager.getTroveNormalizedDebt());
    }

    function addDebt(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyTroveManager returns (bool) {
        uint256 previousBalance = _balances[user];
        uint256 amountScaled = amount.rayDiv(index);
        if (amountScaled == 0) {
            revert Errors.TD_ZeroValue();
        }

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply.add(amountScaled);

        uint256 oldAccountBalance = _balances[user];
        _balances[user] = oldAccountBalance.add(amountScaled);

        return previousBalance == 0;
    }

    function subDebt(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyTroveManager {
        uint256 amountScaled = amount.rayDiv(index);
        if (amountScaled == 0) {
            revert Errors.TD_ZeroValue();
        }

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply.sub(amountScaled);

        uint256 oldAccountBalance = _balances[user];
        _balances[user] = oldAccountBalance.sub(amountScaled);
    }

    /**
     * @dev Returns the principal debt balance of the user from
     * @return The debt balance of the user since the last burn/mint action
     **/
    function scaledBalanceOf(
        address user
    ) public view virtual override returns (uint256) {
        return _balances[user];
    }

    /**
     * @dev Returns the total supply of the variable debt token. Represents the total debt accrued by the users
     * @return The total supply
     **/
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply.rayMul(troveManager.getTroveNormalizedDebt());
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev Returns the principal balance of the user and principal total supply.
     * @param user The address of the user
     * @return The principal balance of the user
     * @return The principal total supply
     **/
    function getScaledUserBalanceAndSupply(
        address user
    ) external view override returns (uint256, uint256) {
        return (_balances[user], _totalSupply);
    }

    function _requireIsContract(address _contract) internal view {
        if (_contract.code.length == 0) {
            revert Errors.NotContract();
        }
    }
}
