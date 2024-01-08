// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";

interface ISpookySquad {
    function dvls() external view returns (ERC721);
    function visible() external view returns (bool);
    function contractURI() external view returns (string memory);
    function isMainMintNow() external view returns (bool);
    function baseURI() external view returns (string memory);
    function maxTotalSupply() external view returns (uint16);
    function availableAmountToMint(address _owner) external view returns (uint16);
    function getMintedAmount(address _owner) external view returns (uint16 premintAmount, uint16 mainMintAmount);
    function maxMainMintTokensAmountPerAddress() external view returns (uint16);
    function timestamp() external view returns (uint64);
    function premintTokensAmount() external view returns (uint16);
    function getTokensOfOwner(address _owner) external view returns (uint16[] memory);
    function mintTokens(address _to, uint16 _amount) external returns (uint16);
    function mintBatch(address[] memory _to, uint16[] memory _amounts)
        external
        returns (uint16 _lastMintedId);
    function setVisibility(bool _visible) external;
    function setBaseURI(string memory _baseUri) external;
    function setStubURI(string memory _stubUri) external;
    function setContractURI(string memory _contractUri) external;
    function setTimestamp(uint64 _newTimestamp) external;
    function setMaxMainMintTokensAmountPerAddress(uint16 _maxMainMintTokensAmountPerAddress) external;
}
