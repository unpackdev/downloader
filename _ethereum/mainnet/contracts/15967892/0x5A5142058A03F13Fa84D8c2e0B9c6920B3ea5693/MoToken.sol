// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "./ERC20PresetMinterPauser.sol";
import "./IERC20Basic.sol";
import "./AccessControlManager.sol";

/// @title The ERC20 token contract
/** @dev This contract is an extension of ERC20PresetMinterPauser which has implementations of ERC20, Burnable, Pausable,
 *  Access Control and Context.
 *  In addition to serve as the ERC20 implementation this also serves as a vault which will hold
 *  1. stablecoins transferred from the users during token purchase and
 *  2. tokens themselves which are transferred from the users while requesting for redemption
 *  3. restrict transfers to only whitelisted addresses
 */

contract MoToken is ERC20PresetMinterPauser {
    /// @dev Address of contract which manages whitelisted addresses
    address public accessControlManagerAddress;
    address public seniorTokenAddress;
    address public juniorTokenAddress;
    bool public isTradable;

    bytes32 public constant UNDERWRITER_ROLE = keccak256("UNDERWRITER_ROLE");

    event AccessControlManagerSet(address indexed accessControlAddress);
    event TradabilitySet(bool indexed tradable);
    event SeniorTokenLinked(address indexed token);
    event JuniorTokenLinked(address indexed token);

    /// @notice Constructor which only serves as passthrough for _tokenName and _tokenSymbol

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC20PresetMinterPauser(_tokenName, _tokenSymbol)
    {
        isTradable = true;
    }

    /// @notice Returns if the address is an underwriter
    /// @param _account The address being checked
    /// @return bool Underwriter check success/failure

    function isUnderwriter(address _account) public view returns (bool) {
        return hasRole(UNDERWRITER_ROLE, _account);
    }

    /// @notice Overrides decimals() function to restrict decimals to 4
    /// @return uint8 returns number of decimals for display

    function decimals() public pure override returns (uint8) {
        return 4;
    }

    /// @notice Burns tokens from the given address
    /// @param _tokens The amount of tokens to burn
    /// @param _address The address which holds the tokens

    function burn(uint256 _tokens, address _address) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        require(balanceOf(_address) >= _tokens, "NT");
        _burn(_address, _tokens);
    }

    /// @notice Transfers MoTokens from self to an external address
    /// @param _address External address to transfer tokens to
    /// @param _tokens The amount of tokens to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function transferTokens(address _address, uint256 _tokens)
        external
        returns (bool)
    {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        IERC20Basic ier = IERC20Basic(address(this));
        return (ier.transfer(_address, _tokens));
    }

    /// @notice Transfers stablecoins from self to an external address
    /// @param _contractAddress Stablecoin contract address on chain
    /// @param _address External address to transfer stablecoins to
    /// @param _amount The amount of stablecoins to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function transferStableCoins(
        address _contractAddress,
        address _address,
        uint256 _amount
    ) external returns (bool) {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        IERC20Basic ier = IERC20Basic(_contractAddress);
        return (ier.transfer(_address, _amount));
    }

    /// @notice Transfers MoTokens from an external address to self
    /// @param _address External address to transfer tokens from
    /// @param _tokens The amount of tokens to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function receiveTokens(address _address, uint256 _tokens)
        external
        returns (bool)
    {
        IERC20Basic ier = IERC20Basic(address(this));
        return (ier.transferFrom(_address, address(this), _tokens));
    }

    /// @notice Transfers stablecoins from an external address to self
    /// @param _contractAddress Stablecoin contract address on chain
    /// @param _address External address to transfer stablecoins from
    /// @param _amount The amount of stablecoins to transfer
    /// @return bool Boolean indicating whether the transfer was success/failure

    function receiveStableCoins(
        address _contractAddress,
        address _address,
        uint256 _amount
    ) external returns (bool) {
        IERC20Basic ier = IERC20Basic(_contractAddress);
        return (ier.transferFrom(_address, address(this), _amount));
    }

    /// @notice Checks if the given address is whitelisted
    /// @param _account External address to check

    function _onlywhitelisted(address _account) internal view {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isWhiteListed(_account), "NW");
    }

    /// @notice Hook that is called before any transfer of tokens
    /// @param from Extermal address from which tokens are transferred
    /// @param to External address to which tokesn are transferred
    /// @param amount Amount of tokens to be transferred

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (to == address(0) || to == address(this)) return;
        _onlywhitelisted(to);

        if (seniorTokenAddress != address(0)) {
            // Token is tradable and recipient is an underwriter
            require(isUnderwriter(to), "NU");
            if (from == address(0)) return;
            require(isTradable, "TNT");

            // Juniormost token is not tradable among underwriters
            if (juniorTokenAddress == address(0)) {
                require((from == address(this) || to == address(this)), "NA");
            }
        }
    }

    /// @notice Setter for isTradable
    /// @param tradable tradability set to true/false

    function setTradability(bool tradable) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NO");
        require(juniorTokenAddress != address(0), "NA");
        isTradable = tradable;
        emit TradabilitySet(tradable);
    }

    /// @notice Link to a Senior token
    /// @param seniorToken Token address

    function linkToSeniorToken(address seniorToken) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        require(seniorTokenAddress == address(0), "NA");
        seniorTokenAddress = seniorToken;
        isTradable = false;
        emit SeniorTokenLinked(seniorToken);
    }

    /// @notice Link to a Junior token
    /// @param juniorToken Token address

    function linkToJuniorToken(address juniorToken) external {
        require(hasRole(MINTER_ROLE, msg.sender), "NM");
        juniorTokenAddress = juniorToken;
        emit JuniorTokenLinked(juniorToken);
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _address Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(address _address) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "NO");
        accessControlManagerAddress = _address;
        emit AccessControlManagerSet(_address);
    }
}
