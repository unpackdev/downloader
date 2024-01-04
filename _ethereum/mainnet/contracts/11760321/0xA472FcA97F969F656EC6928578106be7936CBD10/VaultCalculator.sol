pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";
import "./IVault.sol";


contract VaultCalculator is AccessControlUpgradeSafe {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TokenInfo {
        address addr;
        bool LPtoken;
        uint256 vaultId;
    }
    // Unitokens
    TokenInfo[] public tokens;

    // Underlying token
    IERC20 token;

    IVault vault;

    /** @dev Add token and vault to check the LP + tokens balances from */
    function initialize(address _token, address _vault) external initializer {
        require(_token != address(0), "!constructor address");
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        token = IERC20(_token);
        vault = IVault(_vault);
    }

    /** @dev Set a contract LP tokens */
    function setContract(TokenInfo[] memory _tokens) external onlyAdmin {
        // Add LP Tokens for the contract
        uint256 tLength = _tokens.length;
        for (uint256 i; i < tLength; i++) {
            tokens.push(_tokens[i]);
        }
    }

    /** @dev Get the underlying Token balance in the uniswap lp token  */
    function getUnderlyingTokenInLP(IERC20 _uniToken) public view returns (uint256) {
        return token.balanceOf(address(_uniToken));
    }

    /** @dev Get the users uniswap lp token amount wrapped */
    function getUserUNIBalance(IERC20 _uniToken, address _account) public view returns (uint256) {
        uint256 totalUserBalanceInContracts;
        uint256 length = tokens.length;
        for (uint256 i; i < length; i++) {
            if (tokens[i].addr == address(_uniToken)) {
                totalUserBalanceInContracts = totalUserBalanceInContracts.add(
                    vault.getUserAmount(_account, tokens[i].vaultId)
                );
            }
        }
        return totalUserBalanceInContracts;
    }

    /** @dev Total uniswap lp token supply */
    function getTotalUNISupply(IERC20 _uniToken) public view returns (uint256) {
        return _uniToken.totalSupply();
    }

    /** @dev Calculate the total underlying Token for user */
    function getUnderlyingToken(address _account) external view returns (uint256) {
        // Total Token in UNI LP * users UNI balance / total UNI Supply = user Token amount
        uint256 length = tokens.length;
        uint256 underlyingTokenAmount;
        for (uint256 i; i < length; i++) {
            IERC20 uniToken = IERC20(tokens[i].addr);
            if (tokens[i].LPtoken) {
                underlyingTokenAmount = underlyingTokenAmount.add(
                    getUnderlyingTokenInLP(uniToken).mul(getUserUNIBalance(uniToken, _account)).div(
                        getTotalUNISupply(uniToken)
                    )
                );
            } else {
                underlyingTokenAmount = underlyingTokenAmount.add(getUserUNIBalance(uniToken, _account));
            }
        }
        return underlyingTokenAmount;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "!admin");
        _;
    }
}
