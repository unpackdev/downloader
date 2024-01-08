// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IERC721.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

/**
 * @title UZProAccess
 * @author Unizen
 * @notice Simple abstract class to add easy checks
 * for pro membership access token
 **/
abstract contract UZV1ProAccess is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    // internal storage of the erc721 token
    IERC721 internal _membershipToken;

    function initialize(address _token) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        _setMembershipToken(_token);
    }

    function membershipToken() public view returns (address) {
        return address(_membershipToken);
    }

    /* === CONTROL FUNCTIONS === */
    /**
     * @dev pause smart contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause smart contract
     */
    function unPause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev  Allows the owner of the contract, to update
     * the used membership token
     * @param _newToken address of the new erc721 token
     **/
    function setMembershipToken(address _newToken) public onlyOwner {
        _setMembershipToken(_newToken);
    }

    function _setMembershipToken(address _newToken) internal {
        if (_newToken == address(0) && address(_membershipToken) == address(0))
            return;

        require(_newToken != address(_membershipToken), "SAME_ADDRESS");
        _membershipToken = IERC721(_newToken);
    }

    /**
     * @dev  Internal function that checks if the users has any
     * membership tokens. Reverts, if none is found.
     * @param _user address of user to check
     **/
    function _checkPro(address _user) internal view {
        if (address(_membershipToken) != address(0)) {
            require(
                _membershipToken.balanceOf(_user) > 0,
                "FORBIDDEN: PRO_MEMBER"
            );
        }
    }

    /* === MODIFIERS === */
    modifier onlyPro(address _user) {
        _checkPro(_user);
        _;
    }

    /* === EVENTS === */
    event MembershipTokenUpdated(address _newTokenAddress);
}
