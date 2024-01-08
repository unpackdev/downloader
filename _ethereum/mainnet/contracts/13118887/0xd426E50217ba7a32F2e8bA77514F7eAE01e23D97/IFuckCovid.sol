// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IFuckCovid {
    function contractURI() external view returns (string memory);
    function baseURI() external view returns (string memory);
    function maxTotalSupply() external view returns (uint16);
    function timestamp() external view returns (uint64);
    function getTokensOfOwner(address _owner) external view returns (uint16[] memory);
    function mintToken(address _to) external returns (uint16);
    function mintTokens(address _to, uint16 _amount) external returns (uint16);
    function setBaseURI(string memory _baseUri) external;
    function setStubURI(string memory _stubUri) external;
    function setContractURI(string memory _contractURI) external;
    function setTimestamp(uint64 _newTimestamp) external;
}
