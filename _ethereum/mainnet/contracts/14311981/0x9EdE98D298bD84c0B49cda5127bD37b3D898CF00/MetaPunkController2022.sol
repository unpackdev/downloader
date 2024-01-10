// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./console.sol";

import "./IMetaPunk2018.sol";
import "./IPunk.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Strings.sol";

// Ownable, reentrancyguard, ERC721 interface

contract MetaPunkController2022 is Ownable, ReentrancyGuard {
    using Address for address payable;

    // connected contracts
    IMetaPunk2018 public metaPunk;

    uint256 public mintFee;

    address payable public vault;

    bool public paused = false;

    uint256 public tokenId = 0;

    string public baseUri;

    uint public SKIP2851 = 2851;
    uint public SKIP6485 = 6485;

    event MetaPunk2022Created(uint256 tokenId);

    // events
    event PunkClaimed(uint256 punkId, address claimer);
    event PausedState(bool paused);

    // Set the MetaPunk2018 contracts' Punk Address to address(this)
    // Set the v1 Wrapped Punk Address
    // Set the v2 CryptoPunk Address
    function setup(
        uint256 _mintFee,
        string memory _baseUri,
        IMetaPunk2018 _metaPunk,
        address payable _vault
    ) public onlyOwner {
        metaPunk = _metaPunk;
        mintFee = _mintFee;
        baseUri = _baseUri;
        vault = _vault;
        metaPunk.Existing(address(this));
    }

    // Mint new Token

    modifier whenNotPaused() {
        require(!paused, "Err: Contract is paused");
        _;
    }

    // function _mint() nonRentrant

    // function retrive money
    //

    function mint(uint256 _requstedAmount) public payable nonReentrant whenNotPaused {
        require(_requstedAmount < 10000, "err: requested amount too high");
        require(tokenId < 10000, "err: all pride punks minted");

        require(msg.value >= _requstedAmount * mintFee, "err: not enough funds sent");

        // send msg.value to vault
        vault.sendValue(msg.value);

        for (uint256 x = 0; x < _requstedAmount; x++) {

            //this is to skip these tokens
            if(tokenId == SKIP2851 || tokenId == SKIP6485){
                tokenId++;
            }

            metaPunk.makeToken(tokenId, tokenId);
            metaPunk.seturi(tokenId, string(abi.encodePacked(baseUri, Strings.toString(tokenId))));
            emit MetaPunk2022Created(tokenId);

            // transfer metaPunk to msg.sender
            metaPunk.safeTransferFrom(address(this), msg.sender, tokenId);
            tokenId++;
        }
    }

    function togglePause() public onlyOwner {
        paused = !paused;
        emit PausedState(paused);
    }

    // MetaPunk2018 Punk Contract replacement
    // Must be implemented for the 2018 version to work
    function punkIndexToAddress(uint256) external returns (address) {
        // Return the address of the MetaPunk Contract
        return address(metaPunk);
    }

    function balanceOf(address _user) external returns (uint256) {
        return metaPunk.balanceOf(_user);
    }

    // This is needed in case this contract doesn't work and we need to transfer it again
    function transferOwnershipUnderlyingContract(address _newOwner) public onlyOwner {
        metaPunk.transferOwnership(_newOwner);
    }

    function sendToVault() public {
        vault.sendValue(address(this).balance);
    }
}
