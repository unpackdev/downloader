// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTGemMultiToken {
    // called by controller to mint a claim or a gem
    function mint(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external;

    // called by controller to burn a claim
    function burn(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external;

    function allHeldTokens(address holder, uint256 _idx) external view returns (uint256);

    function allHeldTokensLength(address holder) external view returns (uint256);

    function allTokenHolders(uint256 _token, uint256 _idx) external view returns (address);

    function allTokenHoldersLength(uint256 _token) external view returns (uint256);

    function totalBalances(uint256 _id) external view returns (uint256);

    function allProxyRegistries(uint256 _idx) external view returns (address);

    function allProxyRegistriesLength() external view returns (uint256);

    function addProxyRegistry(address registry) external;

    function removeProxyRegistryAt(uint256 index) external;

    function getRegistryManager() external view returns (address);

    function setRegistryManager(address newManager) external;

    function lock(uint256 token, uint256 timeframe) external;

    function unlockTime(address account, uint256 token) external view returns (uint256);
}
