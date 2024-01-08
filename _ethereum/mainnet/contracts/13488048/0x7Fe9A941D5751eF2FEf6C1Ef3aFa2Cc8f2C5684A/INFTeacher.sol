// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Enumerable.sol";

interface INFTeacher is IERC721Enumerable {

    event BonusTokenCreated(address indexed _owner, uint256 _tokenId);
    event MarketplaceApprovalUpdated(address indexed marketplace, bool newStatus, bool oldStatus);

    function mintNFTeacher(uint256 _quantity) external payable;

    function getRoyaltyERC20TokenCount() external view returns (uint256);
    function getRoyaltyERC20Tokens() external view returns (address[] memory);

    function setMintStart(uint256 _mintStart) external;
    function setBaseURI(string memory _uri) external;
    function setMarketplaceApproval(address _marketplace, bool _allowed) external;
    function setErc20RoyaltyTokens(address[] memory _royaltyERC20Tokens) external;
    function setCurrentMaxSupply(uint16 _currentMaxSupply) external;
}
