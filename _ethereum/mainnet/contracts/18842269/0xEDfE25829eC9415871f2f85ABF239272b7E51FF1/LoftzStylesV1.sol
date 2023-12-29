// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Erc1155V2.sol";
import "./ILoftzStylesV1.sol";

contract LoftzStylesV1 is Erc1155V2, ILoftzStylesV1 {
    // Access Control Roles
    bytes32 public constant ROLE_CAN_MINT_TOKENS = keccak256("ROLE_CAN_MINT_TOKENS");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _royaltiesReceiver,
        uint256 _royaltiesFraction,
        string memory _uriPrefix,
        string memory _uriSuffix
    ) public initializer {
        __Erc1155V2_init(
            _royaltiesReceiver,
            _royaltiesFraction,
            _uriPrefix,
            _uriSuffix
        );
    }

    // =============================================================
    // Main Token Logic
    // =============================================================

    function mint(address _to, uint256 _id, uint256 _amount, bytes memory _data) external onlyRole(ROLE_CAN_MINT_TOKENS) {
        _mint(_to, _id, _amount, _data);
    }

    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) external onlyRole(ROLE_CAN_MINT_TOKENS) {
        _mintBatch(_to, _ids, _amounts, _data);
    }

    // =============================================================
    // Operator Filter
    // =============================================================

    function getOperatorFilterAddress() public pure override returns (address) {
        return address(0xE587E651a267BcEb819FcDE71CB9492797a5F92E);
    }

    // =============================================================
    // Off-chain Indexing Tools
    // =============================================================

    function getBalancesOf(address _owner, uint256[] memory _ids) external view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_ids.length);

        uint256 i = 0;
        for (;;) {
            balances[i] = balanceOf(_owner, _ids[i]);

            if (_ids.length == ++i) break;
        }

        return balances;
    }
}
