// SPDX-License-Identifier: GPL-3.0
//
/// @title  Anonymous Peeps Genesis Collection
/// @author tmtlab.eth (https://twitter.com/tmtlabs) & tanujd.eth (https://twitter.com/tanujdamani)
/// @notice Artist PRM, reviewed by BrainyPeep

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract APGenesis is ERC721A, Ownable {
    string public baseURI;
    address public stakeContract;
    uint256 public maxGenesis;

    /// Contructor that will initialize the contract with the owner address
    constructor(string memory _BaseURI, uint256 _maxGenesis, uint256 _qty) ERC721A("AnonymousPeeps Genesis", "APGEN") {
        baseURI = _BaseURI;
        maxGenesis = _maxGenesis;
        _mint(msg.sender, _qty);
    }

    /// @notice update the base URI of the collection
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice update the base URI of the collection
    function setMaxGenesis(uint256 _maxGenesis) public onlyOwner {
        maxGenesis = _maxGenesis;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    // @dev Override ERC721A to start token from 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice sets the staking contract address
    function setStakeContract(address _stakeContract) public onlyOwner {
        stakeContract = _stakeContract;
    }

    /// @dev Transfer NFT to staking contract without needing to set approval.
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {      
        if (_operator == stakeContract) {
          return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function artistMint (uint256 _qty) public onlyOwner {
        require(totalSupply()+_qty <= maxGenesis, "Exceded Genesis tokens");
        _mint(owner(), _qty);
    }

    /// @notice Failsafe if someone mistakingly sends money to the contract, so it can be returned
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }
}