//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./AccessControlEnumerable.sol";

interface IAKIR {
    function mint(address to, uint256 amount) external;
}

contract TestController is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public AKIR_ADDRESS;

    constructor(address _akirAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        AKIR_ADDRESS = _akirAddress;
    }

    function batchMint(address[] memory _recipients, uint256[] memory amounts)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            _recipients.length == amounts.length,
            "Array lengths do not match."
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            IAKIR(AKIR_ADDRESS).mint(_recipients[i], amounts[i]);
        }
    }
}
