// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ILilDevils {
    // function initialize(
    //     address _proxyRegistryAddress,
    //     uint16 _presaleTokensAmountPerAddress,
    //     uint16 _saleTokensAmountPerAddress,
    //     uint _presalePrice,
    //     uint _salePrice
    // ) external;
    function contractURI() external view returns (string memory);
    function baseURI() external view returns (string memory);
    function maxTotalSupply() external view returns (uint16);
    function maxBuyTokensAmountPerTime() external view returns (uint16);
    function presaleAmount() external pure returns (uint16);
    function presalePrice() external view returns (uint);
    function salePrice() external view returns (uint);
    function timestamp() external view returns (uint64);
    function getTokensOfOwner(address _owner) external view returns (uint16[] memory);
    function buyToken(address _to) external payable returns (uint16 _tokenId);
    function buyTokens(address _to, uint16 _amount) external payable returns (uint16 _tokenId);
    function mintToken(address _to) external returns (uint16);
    function mintTokens(address _to, uint16 _amount) external returns (uint16);
    function startSale() external;
    function setSalePrice(uint _salePrice) external;
    function setBaseURI(string memory _baseUri) external;
    function setStubURI(string memory _stubUri) external;
    function setContractURI(string memory _contractUri) external;
    function setPresalePrice(uint _presalePrice) external;
    function increaseMaxTotalSupply(uint16 _maxTotalSupply) external;
    function setTimestamp(uint64 _newTimestamp) external;
    function setMaxBuyTokensAmountPerTime(uint16 _maxBuyTokensAmountPerTime) external;
}
