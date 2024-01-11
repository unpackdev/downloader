// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./AccessControlUpgradeable.sol";

interface IWATTs {
	function burn(address _from, uint256 _amount) external;
    function burnClaimable(address _from, uint256 _amount) external;
    function balanceOf(address user) external view returns (uint256);
}

interface ITransferExtenderV2 {
    function WATTSOWNER_seeClaimableBalanceOfUser(address user) external view returns (uint256);
}

contract WattsBurnerUpgradable is AccessControlUpgradeable {

    IWATTs public watts;
    ITransferExtenderV2 public transferExtender;
    bytes32 public GameAdminRole;    

    constructor(address[] memory _admins, address _watts, address _transferExtender) {}

    function watts_burner_initialize(address[] memory _admins, address _watts, address _transferExtender) public initializer {
        __AccessControl_init();

        watts = IWATTs(_watts);
        transferExtender = ITransferExtenderV2(_transferExtender);

        GameAdminRole = keccak256("GAME_ADMIN");

        for (uint i = 0; i < _admins.length; i++) {
            _grantRole(GameAdminRole, _admins[i]);
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _burnWatts(uint256 amount) internal {
        require(watts.balanceOf(msg.sender) >= amount, "User does not have enough balance");
        require(amount > 0, "Cannot burn zero watts");
        
        uint256 claimableBalance = transferExtender.WATTSOWNER_seeClaimableBalanceOfUser(msg.sender);
        uint256 burnFromClaimable = claimableBalance >= amount ? amount : claimableBalance;
        uint256 burnFromBalance = claimableBalance >= amount ? 0 : amount - claimableBalance;

        if (claimableBalance > 0) {
            watts.burnClaimable(msg.sender, burnFromClaimable);
        }
        
        if (burnFromBalance > 0) {
            watts.burn(msg.sender, burnFromBalance);
        }
    }

    function setContracts(address _watts, address _extender) external onlyRole(DEFAULT_ADMIN_ROLE) {
        watts = IWATTs(_watts);
        transferExtender = ITransferExtenderV2(_extender);
    }
}