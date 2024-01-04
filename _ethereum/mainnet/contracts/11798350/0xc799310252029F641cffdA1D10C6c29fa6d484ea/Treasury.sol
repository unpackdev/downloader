pragma solidity 0.7.6;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

/**
 * @title Treasury Contract
 * @notice the treasury of the protocols, allowing storage and transfer of funds
 */
contract Treasury is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /**
     * @notice Initializer of the contract
     * @param _adminAddress the address the admin of the contract
     */
    function initialize(address _adminAddress) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(ADMIN_ROLE, _adminAddress);
    }

    /**
     * @notice send erc20 tokens to an address
     * @param _erc20 the address of the erc20 token
     * @param _recipient the address of the recipient
     * @param _amount the amount of tokens to send
     */
    function sendToken(
        address _erc20,
        address _recipient,
        uint256 _amount
    ) public nonReentrant {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        IERC20Upgradeable(_erc20).transfer(_recipient, _amount);
    }

    /**
     * @notice send ether to an address
     * @param _recipient the address of the recipient
     * @param _amount the amount of ether to send
     */
    function sendEther(address payable _recipient, uint256 _amount) public payable nonReentrant {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
