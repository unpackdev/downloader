// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./ONFT721.sol";

contract ONFT is ONFT721, Pausable, ReentrancyGuard {
    using Strings for uint;

    uint public supply;
    string public contractURI;
    address public feeCollectorAddress;

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _feeCollectorAddress the address fee collector
    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, address _layerZeroEndpoint, address _feeCollectorAddress) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        setBaseURI(_baseTokenURI);
        contractURI = _baseTokenURI;
        feeCollectorAddress = _feeCollectorAddress;
    }

    function mintHonorary(address to, uint tokenId) external onlyOwner {
        _mint(to, tokenId);
        supply++;
    }

    function _beforeSend(address, uint16, bytes memory, uint _tokenId) internal override whenNotPaused {
        _burn(_tokenId);
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function totalSupply() public view virtual returns (uint) {
        return supply;
    }
}
