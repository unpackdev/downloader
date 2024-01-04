pragma solidity 0.7.6;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20.sol";
import "./IFuture.sol";

/**
 * @title Future vault contract
 * @notice Handles the future vault mecanisms
 * @dev The future vault contract stores the IBT locked during the different periods
 */
contract FutureVault is Initializable, AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IFuture private future;

    event TokenApproved(address _tokenAddress);

    /**
     * @notice Intializer
     * @param _futureAddress the address of the corresponding future
     * @param _adminAddress the address of the corresponding admin
     */
    function initialize(address _futureAddress, address _adminAddress) public virtual initializer {
        future = IFuture(_futureAddress);
        ERC20(future.getIBTAddress()).approve(_futureAddress, uint256(-1));
        _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);
        _setupRole(ADMIN_ROLE, _adminAddress);
    }

    /**
     * @notice Getter for the future address
     * @return the future address linked to this vault
     */
    function getFutureAddress() public view returns (address) {
        return address(future);
    }

    /**
     * @notice Approve another token to be transfered from this contract by the future
     */
    function approveAdditionalToken(address _tokenAddress) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not allowed to approve another token");
        ERC20(_tokenAddress).approve(address(future), uint256(-1));
        emit TokenApproved(_tokenAddress);
    }
}
