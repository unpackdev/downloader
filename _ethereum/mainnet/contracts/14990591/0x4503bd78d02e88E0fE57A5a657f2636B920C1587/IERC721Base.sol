pragma solidity ^0.8.6;

interface IERC721Base {
    function setContractURI(string memory _contractURI) external;

    function setBaseURI(string memory _baseUri) external;

    function totalSupply() external view returns (uint256);
}
