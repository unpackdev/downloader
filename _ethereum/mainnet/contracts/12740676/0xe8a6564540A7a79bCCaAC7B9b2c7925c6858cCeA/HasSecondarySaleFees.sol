// SPDX-License-Identifier: MIT
// this is copied from chocomintapp/chocofactory
// https://github.com/chocomintapp/chocofactory/blob/main/packages/contracts/contracts/extentions/HasSecondarySaleFees.sol
// modified by TART-tokyo

pragma solidity =0.8.6;

import "./ERC165.sol";

interface IHasSecondarySaleFees {
    function getFeeBps(uint256 id) external view returns (uint256[] memory);

    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}

contract HasSecondarySaleFees is IERC165, IHasSecondarySaleFees {
    address payable[] private commonRoyaltyAddresses;
    uint256[] private commonRoyaltiesWithTwoDecimals;

    mapping(uint256 => address payable[]) private royaltyAddresses;
    mapping(uint256 => uint256[]) private royaltiesWithTwoDecimals;

    constructor(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) {
        _setCommonRoyalties(_commonRoyaltyAddresses, _commonRoyaltiesWithTwoDecimals);
    }

    function _setRoyaltiesOf(
        uint256 _tokenId,
        address payable[] memory _royaltyAddresses,
        uint256[] memory _royaltiesWithTwoDecimals
    ) internal {
        require(_royaltyAddresses.length == _royaltiesWithTwoDecimals.length, "input length must be same");
        for (uint256 i = 0; i < _royaltyAddresses.length; i++) { 
            require(_royaltyAddresses[i] != address(0), "Must not be zero-address");
        }
        
        royaltyAddresses[_tokenId] = _royaltyAddresses;
        royaltiesWithTwoDecimals[_tokenId] = _royaltiesWithTwoDecimals;
    }

    function _setCommonRoyalties(
        address payable[] memory _commonRoyaltyAddresses,
        uint256[] memory _commonRoyaltiesWithTwoDecimals
    ) internal {
        require(_commonRoyaltyAddresses.length == _commonRoyaltiesWithTwoDecimals.length, "input length must be same");
        for (uint256 i = 0; i < _commonRoyaltyAddresses.length; i++) { 
            require(_commonRoyaltyAddresses[i] != address(0), "Must not be zero-address");
        }
        
        commonRoyaltyAddresses = _commonRoyaltyAddresses;
        commonRoyaltiesWithTwoDecimals = _commonRoyaltiesWithTwoDecimals;
    }

    function getFeeRecipients(uint256 _tokenId)
    external view override returns (address payable[] memory)
    {
        if (royaltyAddresses[_tokenId].length == 0) {
            return commonRoyaltyAddresses;
        }
        uint256 length = commonRoyaltyAddresses.length + royaltyAddresses[_tokenId].length;

        address payable[] memory recipients = new address payable[](length);
        for (uint256 i = 0; i < commonRoyaltyAddresses.length; i++) {
            recipients[i] = commonRoyaltyAddresses[i];
        }
        for (uint256 i = 0; i < royaltyAddresses[_tokenId].length; i++) {
            recipients[i + commonRoyaltyAddresses.length] = royaltyAddresses[_tokenId][i];
        }

        return recipients;
    }

    function getFeeBps(uint256 _tokenId) external view override returns (uint256[] memory) {
        if (royaltiesWithTwoDecimals[_tokenId].length == 0) {
            return commonRoyaltiesWithTwoDecimals;
        }
        uint256 length = commonRoyaltiesWithTwoDecimals.length + royaltiesWithTwoDecimals[_tokenId].length;

        uint256[] memory fees = new uint256[](length);
        for (uint256 i = 0; i < commonRoyaltiesWithTwoDecimals.length; i++) {
            fees[i] = commonRoyaltiesWithTwoDecimals[i];
        }
        for (uint256 i = 0; i < royaltiesWithTwoDecimals[_tokenId].length; i++) {
            fees[i + commonRoyaltyAddresses.length] = royaltiesWithTwoDecimals[_tokenId][i];
        }

        return fees;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165)
    returns (bool)
    {
        return interfaceId == type(IHasSecondarySaleFees).interfaceId;
    }

}
