// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface IFactoryERC721 {
    /**
     * @dev Returns the name of this factory.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol for this factory.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns a URL specifying some meta about the option. This meta can be of the
     * same structure as the ERC721 meta.
     */
    function tokenURI(uint256 _optionId) external view returns (string memory);

    /**
     * @dev Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external view returns (bool);

    /**
     * @dev Number of options the factory supports.
     */
    function numOptions() external view returns (uint256);

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId) external view returns (bool);

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) external returns (uint256);

    event MintSucceed(address _toAddress);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
