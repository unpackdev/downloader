// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;
import "Ownable.sol";

contract FranklinTokenWhitelist is Ownable {
    /// ============ EVENTS ============
    /// @notice Emits address of the ERC20 token approved
    event TokenApproved(address _token);
    /// @notice Emits address of the ERC20 token removed
    event TokenRemoved(address _token);

    /// ============ STORAGE VARIABLES ============

    /** @dev
      The approvedTokens array and registeredToken mapping are used to manage
      the tokens approved for payroll. This is used to ensure that tokens in
      the treasury which are not allocated to Payroll are not accidentally
      used in a payroll run */
    address[] private approvedTokens;

    /// @dev Mapping manages registerdTokens and indicates if a _token is registered
    mapping(address => bool) private registeredToken;

    constructor(address[] memory initially_approved_tokens) {
        for (uint256 i = 0; i < initially_approved_tokens.length; ) {
            addApprovedToken(initially_approved_tokens[i]);
            unchecked {
                i++;
            }
        }
    }

    /// Protect owner by overriding renounceOwnership
    function renounceOwnership() public virtual override {
        revert("Cant renounce");
    }

    /// ============ MODIFIERS ============

    modifier onlyApprovedTokens(address _token) {
        require(registeredToken[_token], "Token not approved");
        _;
    }

    /// ============ VIEW FUNCTIONS ============

    function getApprovedTokens() external view returns (address[] memory) {
        return (approvedTokens);
    }

    function isApprovedToken(address _token) external view returns (bool) {
        return (registeredToken[_token]);
    }

    /// ============ TOKEN MANAGEMENT FUNCTIONS ============

    /** @notice
      Adds the ERC20 token address to the registeredToken array and creates a
      mapping that returns a boolean showing the token is approved. */
    /// @dev This function is public because it is called by the initializer
    /// @param _token The ERC20 token to be approved
    function addApprovedToken(address _token) public onlyOwner {
        require(!registeredToken[_token], "Token already approved");
        require(_token != address(0), "No 0x0 address");

        registeredToken[_token] = true;
        approvedTokens.push(_token);

        emit TokenApproved(_token);
    }

    /** @notice
      Removes the ERC20 token from the registeredToken array and
      deletes the mapping used to confirm a token is approved */
    /// @param _token The ERC20 token to be removed
    function removeApprovedToken(address _token)
        external
        onlyOwner
        onlyApprovedTokens(_token)
    {
        // set mapping to false
        registeredToken[_token] = false;

        // remove from approved token array
        for (uint256 i = 0; i < approvedTokens.length; ) {
            if (approvedTokens[i] == _token) {
                // replace deleted _token with last _token in array
                approvedTokens[i] = approvedTokens[approvedTokens.length - 1];
                // remove last spot in array
                approvedTokens.pop();
                break;
            }
            unchecked {
                i++;
            }
        }

        emit TokenRemoved(_token);
    }
}
