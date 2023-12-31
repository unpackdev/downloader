pragma solidity ^0.8.17;

import "./ERC20Burnable.sol";
import "./AccessControlEnumerable.sol";

contract LG is ERC20Burnable, AccessControlEnumerable {
    bytes32 public constant MINT_ROLE = bytes32(uint256(1));

    constructor() ERC20("Littlemami game coin", "LG") {
        _setupRole(AccessControl.DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINT_ROLE, _msgSender());
    }

    function mint(
        address _account,
        uint256 _amount
    ) external onlyRole(MINT_ROLE) {
        _mint(_account, _amount);
    }
}
