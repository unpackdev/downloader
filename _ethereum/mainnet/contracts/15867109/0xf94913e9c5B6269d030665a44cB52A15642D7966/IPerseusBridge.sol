// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20Upgradeable.sol";
import "./IPerseusNFT.sol";

interface IPerseusBridge {
    function adminAddress() external view returns (address);
    function signerAddress() external view returns (address);
    function token() external view returns (IERC20);
    function claims(string calldata _solanaTxId) external view returns (bool);
    function updateAdmin(address _newSignerAddress) external;
    function updateSigner(address _newSignerAddress) external;
    function updateToken(IERC20 _newToken) external;
    function updateNft(IPerseusNFT _newNft) external;
    function claim(
        string calldata _solanaTxId,
        uint256 _amount,
        bytes calldata _signature
    ) external;
    function adminClaim(
        address _receiverAddress,
        string calldata _solanaTxId,
        uint256 _amount
    ) external;
    function withdraw(uint256 _amount) external;
    function nftClaim(
        string calldata _solanaTxId,
        uint256 _silverAmount,
        uint256 _goldAmount,
        uint256 _platinumAmount,
        uint256 _blackAmount,
        bytes calldata _signature
    ) external;
    function adminNftClaim(
        address _receiverAddress,
        string calldata _solanaTxId,
        uint256 _silverAmount,
        uint256 _goldAmount,
        uint256 _platinumAmount,
        uint256 _blackAmount
    ) external;
}
