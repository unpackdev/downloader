// SPDX-License-Identifier: Unlicensed
pragma solidity ~0.8.13;

interface IExtensionManager {
    function beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function afterTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function beforeTokenApprove(address _to, uint256 _tokenId) external;

    function afterTokenApprove(address _to, uint256 _tokenId) external;

    function beforeApproveAll(address _operator, bool _approved) external;

    function afterApproveAll(address _operator, bool _approved) external;

    function tokenURI(uint256 _tokenId) external view returns (string memory uri_);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address royaltyReceiver_, uint256 royaltyAmount_);

    function getPLOTData(uint256 _tokenId, bytes memory _in)
        external
        view
        returns (bytes memory out_);

    function setPLOTData(uint256 _tokenId, bytes memory _in) external returns (bytes memory out_);

    function payPLOTData(uint256 _tokenId, bytes memory _in)
        external
        payable
        returns (bytes memory out_);

    function getData(bytes memory _in) external view returns (bytes memory out_);

    function setData(bytes memory _in) external returns (bytes memory out_);

    function payData(bytes memory _in) external payable returns (bytes memory out_);
}
