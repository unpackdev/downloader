//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Counters.sol";

contract ArtChirick is ERC721
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address contractDeployer;

    constructor() public ERC721("ArtChirick", "ARTC")
    {
        contractDeployer = msg.sender;
        _setBaseURI("ipfs://");
    }

    function mint(string memory ipfsMetadataHash) public returns (uint256)
    {
        require(contractDeployer == msg.sender);

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, ipfsMetadataHash);
        return newTokenId;
    }

    function setBaseURI(string memory newBaseURI) public
    {
        require(contractDeployer == msg.sender);
        _setBaseURI(newBaseURI);
    }

}
