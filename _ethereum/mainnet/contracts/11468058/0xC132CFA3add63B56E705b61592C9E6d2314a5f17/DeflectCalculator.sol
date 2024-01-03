pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";


/**
 * @title DeflectCalculator
 * @author DEFLECT PROTOCOL
 * @dev Main purpose is to get the underlying Deflect value from an LP token.
 */
interface PairContract {
    function balanceOf(address) external view returns (uint256);
}

contract DeflectCalculator is AccessControlUpgradeSafe {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contract -> Token mappping.
    mapping(address => address) public uniTokenForContract;
    address[] public lpContainingContracts;

    // The deflect token
    IERC20 deflect;

    /** @dev Add the deflect token,  a pre-known uniswap pair in the constructor and lpContainingContracts containing the token*/
    constructor(address _deflect) public {
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        deflect = IERC20(_deflect);
    }

    /** @dev Add new contract containing LP token */
    function addContract(address _contract, address _uniToken) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Wrong number!");
        require(_contract.isContract(), "Address must be a contract");
        // Add LP Token for the contract
        lpContainingContracts.push(_contract);
        uniTokenForContract[_contract] = _uniToken;
    }

    /** @dev Remove a contract */
    function deleteContract(address _contract) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Wrong number sir!");
        for (uint256 i; i < lpContainingContracts.length; i++) {
            if (lpContainingContracts[i] == _contract) {
                delete lpContainingContracts[i];
                uniTokenForContract[_contract] = address(0);
            }
        }
    }

    /** @dev Get the underlying deflect token balance in the uniswap lp token  */
    function getDEFLECTBalanceInUNI(IERC20 _uniToken) public view returns (uint256) {
        return deflect.balanceOf(address(_uniToken));
    }

    /** @dev Get the users uniswap   lp token amount wrapped */
    function getUserUNIBalance(IERC20 _uniToken, address _account) public view returns (uint256) {
        uint256 totalUserBalanceInContracts;

        for (uint256 i; i < lpContainingContracts.length; i++) {
            if (uniTokenForContract[lpContainingContracts[i]] == address(_uniToken)) {
                PairContract currentContract = PairContract(lpContainingContracts[i]);
                totalUserBalanceInContracts = totalUserBalanceInContracts.add(currentContract.balanceOf(_account));
            }
        }
        return _uniToken.balanceOf(_account).add(totalUserBalanceInContracts);
    }

    /** @dev Total uniswap lp token supply */
    function getTotalUNISupply(IERC20 _uniToken) public view returns (uint256) {
        return _uniToken.totalSupply();
    }

    /** @dev Calculate the total underlying deflect tokens for user */
    function getUnderlyingDeflect(address _account, address _contract) external view returns (uint256) {
        uint256 totalShares;
        // Total deflect in UNI LP * users UNI balance / total UNI Supply = user deflect amount
        IERC20 token = IERC20(uniTokenForContract[_contract]);
        if (address(token) == address(0)) return 0;
        totalShares = totalShares.add(getDEFLECTBalanceInUNI(token)).mul(getUserUNIBalance(token, _account)).div(getTotalUNISupply(token));
        return totalShares;
    }
}
