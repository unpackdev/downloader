// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.18;

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";


contract Treasury is
    Initializable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ENTREPRENEUR_ROLE = keccak256("ENTREPRENEUR_ROLE");
    bytes32 public constant VOLUNTEER_ADMIN_ROLE = keccak256("VOLUNTEER_ADMIN_ROLE");
    event FundWithdrawn(
        IERC20Upgradeable tokenAddress,
        address to,
        uint amount
    );
    event ReceivedEther(address payer, uint amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice  Initialize contract,provides _superAdmin wallet address DEFAULT_ADMIN and ADMIN role and sets role ADMIN as a role admin for ENTREPRENEUR role  .
     * @param   _superAdmin  .
     */
    function initialize(address _superAdmin) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _superAdmin);
        _grantRole(ADMIN_ROLE, _superAdmin);
        _setRoleAdmin(ENTREPRENEUR_ROLE, ADMIN_ROLE);
    }

    /**
     * @notice Provides functionality to check if the given account has Admin role .
     * @param   _account  .
     * @return  bool  .
     */
    function isAdmin(address _account) external view returns (bool) {
        return hasRole(ADMIN_ROLE, _account);
    }

    /**
     * @notice Provides functionality to check if the given account has Entrepreneur role .
     * @param   _account  .
     * @return  bool  .
     */
    function isEntrepreneur(address _account) external view returns (bool) {
        return hasRole(ENTREPRENEUR_ROLE, _account);
    }

    /**
     * @notice Provides functionality to check if the given account has Volunteer Admin role .
     * @param   _account  .
     * @return  bool  .
     */
    function isVolunteerAdmin(address _account) external view returns (bool) {
        return hasRole(VOLUNTEER_ADMIN_ROLE, _account);
    }
    /**
     * @notice  Provides functionality to withdraw ERC20 token and ethers from the contract,caller must have Admin role .
     * @param   _tokenAddress  .
     * @param   _to  .
     * @param   _amount  .
     */
    function withdrawFunds(
        IERC20Upgradeable _tokenAddress,
        address _to,
        uint _amount
    ) external onlyRole(ADMIN_ROLE) nonReentrant {
        require(
            (_to != address(0)),
            "GoodTreasury: address zero not allowed"
        );
        uint256 amount;
        if (address(_tokenAddress) == address(0)) {
            uint256 balance = address(this).balance;
            amount = _amount == 0 ? balance : _amount;
            bool sent = _sendEthersTo(_to, amount);
            require(sent, "GoodTreasury: Failed to send Ether");
        } else {
            uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(
                address(this)
            );
            amount = _amount == 0 ? balance : _amount;
            require(balance > 0, "GoodTreasury: Insufficient balance");
            IERC20Upgradeable(_tokenAddress).safeTransfer(_to, amount);
        }
        emit FundWithdrawn(_tokenAddress, _to, amount);
    }

    function _sendEthersTo(
        address _receiver,
        uint256 _amount
    ) internal returns (bool) {
        (bool sent, ) = payable(_receiver).call{value: _amount}("");
        return sent;
    }

    /**
     * @dev Receive function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }

    /**
     * @notice  Provides functionality to upgrade the contract by adding new implementation contract,caller must have Admin role .
     * @param   _newImplementation  .
     */
    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyRole(ADMIN_ROLE) {}
}
