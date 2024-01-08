// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

interface IFiat24Account is IERC721Upgradeable, IAccessControlUpgradeable {

    enum Status { Live, SoftBlocked, Invitee, Blocked, Closed }

    function historicOwnership(address owner) external view returns(uint256);
    function nickNames(uint256 tokenId) external view returns(string memory);
    function isMerchant(uint256 tokenId) external view returns(bool);
    function merchantRate(uint256 tokenId) external view returns(uint256);
    function status(uint256 tokenId) external view returns(Status);

    function mint(address _to, uint256 _tokenId, bool _isMerchant, uint256 _merchantRate) external;

    function mintByClient(uint256 _tokenId) external;

    function burn(uint256 tokenId) external;


    function removeHistoricOwnership(address owner) external;

    function changeClientStatus(uint256 tokenId, Status _status) external;

    function setMinDigitForSale(uint8 minDigit) external;
    function setMerchantRate(uint256 tokenId, uint256 _merchantRate) external;
    function setNickname(uint256 tokenId, string memory nickname) external;  
}