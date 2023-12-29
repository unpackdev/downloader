pragma solidity 0.8.3;

import "./Clones.sol";
import "./Context.sol";
import "./IBondFactory.sol";
import "./BondController.sol";

/**
 * @dev Factory for BondController minimal proxy contracts
 */
contract BondFactory is IBondFactory, Context {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public immutable target;
    address public immutable trancheFactory;

    uint256 public factoryNonce;

    constructor(address _target, address _trancheFactory) {
        target = _target;
        trancheFactory = _trancheFactory;
        factoryNonce = 0;
    }

    /**
     * @dev Deploys a minimal proxy instance for a new bond with the given parameters.
     * @param _collateralToken The address of the ERC20 token that the bond will use as collateral
     * @param trancheRatios the ratios that the bond will use to generate tranche tokens
     * @param maturityDate The unix timestamp in seconds at which the bond is maturable
     * @return  The address of the newly created bond
     */
    function createBond(
        address _collateralToken,
        uint256[] memory trancheRatios,
        uint256 maturityDate
    ) external override returns (address) {
        return _createBond(_collateralToken, trancheRatios, maturityDate, 0);
    }

    /**
     * @dev Deploys a minimal proxy instance for a new bond with the given parameters.
     * @param _collateralToken The address of the ERC20 token that the bond will use as collateral
     * @param trancheRatios the ratios that the bond will use to generate tranche tokens
     * @param maturityDate The unix timestamp in seconds at which the bond is maturable
     * @param depositLimit The maximum amount of collateral that can be deposited into the bond
     * @return  The address of the newly created bond
     */
    function createBondWithDepositLimit(
        address _collateralToken,
        uint256[] memory trancheRatios,
        uint256 maturityDate,
        uint256 depositLimit
    ) external returns (address) {
        return _createBond(_collateralToken, trancheRatios, maturityDate, depositLimit);
    }

    /**
     * @dev Deploys a minimal proxy instance for a new bond with the given parameters.
     * @param _collateralToken The address of the ERC20 token that the bond will use as collateral
     * @param trancheRatios the ratios that the bond will use to generate tranche tokens
     * @param maturityDate The unix timestamp in seconds at which the bond is maturable
     * @param depositLimit The maximum amount of collateral that can be deposited into the bond
     * @return  The address of the newly created bond
     */
    function _createBond(
        address _collateralToken,
        uint256[] memory trancheRatios,
        uint256 maturityDate,
        uint256 depositLimit
    ) internal returns (address) {
        bytes32 salt = keccak256(abi.encode(_msgSender(), factoryNonce));
        factoryNonce = factoryNonce + 1;
        address clone = Clones.cloneDeterministic(target, salt);
        BondController(clone).init(
            trancheFactory,
            _collateralToken,
            _msgSender(),
            trancheRatios,
            maturityDate,
            depositLimit
        );
        emit BondCreated(_msgSender(), clone);
        return clone;
    }
}
