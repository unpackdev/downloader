// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./Zora.sol";

interface IPA1D {
    function init(
        uint256 tokenId,
        address payable receiver,
        uint256 bp
    ) external;

    function configurePayouts(address payable[] memory addresses, uint256[] memory bps) external;

    function getPayoutInfo()
        external
        view
        returns (address payable[] memory addresses, uint256[] memory bps);

    function getEthPayout() external;

    function getTokenPayout(address tokenAddress) external;

    function getTokenPayoutByName(string memory tokenName) external;

    function getTokensPayout(address[] memory tokenAddresses) external;

    function getTokensPayoutByName(string[] memory tokenNames) external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function setRoyalties(
        uint256 tokenId,
        address payable receiver,
        uint256 bp
    ) external;

    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

    function getFeeBps(uint256 tokenId) external view returns (uint256[] memory);

    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);

    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    function getFees(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);

    function tokenCreator(address contractAddress, uint256 tokenId) external view returns (address);

    function calculateRoyaltyFee(
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) external view returns (uint256);

    function marketContract() external view returns (address);

    function tokenCreators(uint256 tokenId) external view returns (address);

    function bidSharesForToken(uint256 tokenId)
        external
        view
        returns (Zora.BidShares memory bidShares);

    function getStorageSlot(string calldata slot) external pure returns (bytes32);

    function getTokenAddress(string memory tokenName) external view returns (address);
}
