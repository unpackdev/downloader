// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC1155Upgradeable.sol";

interface IUnikuraMembership is IERC1155Upgradeable {
    /**
     * @dev Emit an event when the URI for the token-level metadata
     *      is updated.
     */
    event TokenURIUpdated(string newUri);

    function initialize(string memory uri) external;

    function setName(string calldata newName) external;

    function setSymbol(string calldata newSymbol) external;

    function getSilverMintLimit() external view returns (uint256);

    function setSilverMintLimit(uint256 _limit) external;

    function getSilverMinted() external view returns (uint256);

    function ownsMembership(address account) external view returns (bool);

    function mint(address account, uint256 id, uint256 amount) external;

    function setURI(string calldata newUri) external;

    function setSalesAddress(address newSalesAddress) external;

    function getSalesAddress() external view returns (address);

    function setBurnAddress(address newBurnAddress) external;

    function getBurnAddress() external view returns (address);

    function burn(address from, uint256 id, uint256 amount) external;

    function renounceOwnership() external view;
}
