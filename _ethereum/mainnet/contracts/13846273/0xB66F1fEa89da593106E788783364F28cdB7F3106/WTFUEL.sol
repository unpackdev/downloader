// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20PresetMinterPauser.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation), necessary for bridging tokens to a satellite chain
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract WTFUEL is ERC20PresetMinterPauser {
    constructor(
        address[] memory initialRelays
    ) public ERC20PresetMinterPauser("TFUEL from Theta wrapped by ThetaBridge.io", "WTFUEL") {
        _setupDecimals(18);
        renounceRole(MINTER_ROLE, _msgSender());
        for (uint i = 0; i < initialRelays.length; ++i){
            _setupRole(MINTER_ROLE, initialRelays[i]);
        }
    }

    function mintMulti(address[] calldata toList, uint256[] calldata valueList) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role");
        require(toList.length == valueList.length, "lists must be same length");
        for (uint i = 0; i < toList.length; ++i){
            _mint(toList[i], valueList[i]); 
        }
    }

    function transferMulti(address[] calldata toList, uint256[] calldata valueList) external returns (bool) {
        require(toList.length == valueList.length, "lists must be same length");
        for (uint i = 0; i < toList.length; ++i){
            _transfer(_msgSender(), toList[i], valueList[i]);
        }
        return true;
    }
}
