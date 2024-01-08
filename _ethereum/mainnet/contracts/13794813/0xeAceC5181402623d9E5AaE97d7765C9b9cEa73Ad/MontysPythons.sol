// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/****************************************
 * A GOLDENX CONTRACT
 * @author: hammm.eth                     
 ****************************************/

import "./ERC721EnumerableLite.sol";
import "./Delegated.sol";
import "./PaymentSplitter.sol";
import "./Strings.sol";

contract MontysPythons is ERC721EnumerableLite, Delegated, PaymentSplitter {
    using Strings for uint256;

    uint256 public PRICE = 0.0314 ether;
    uint256 public MAX_TOKENS_PER_TRANSACTION = 20;
    uint256 public MAX_SUPPLY = 6282;

    string public _baseTokenURI = 'https://herodev.mypinata.cloud/ipfs/QmXSRMcKn777aCVhozaymReFoj8R3RNpcVmKZMYzp3Ratf/'; 
    string public _baseTokenSuffix = '.json';

    uint256 public _startTime = 1640952000; 
    bool public paused = false;

    // Withdrawal addresses
    address t1 = 0x3a8C9B9846df39E3a23c18722Fb82e93B81C0FFc;
    address t2 = 0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a;

    address[] addressList = [t1, t2];
    uint256[] shareList = [85, 15];

    constructor()
    ERC721B("Monty's Pythons", "MNTY")
    PaymentSplitter(addressList, shareList)  {
    }

    function mint(uint256 _count) external payable {
        require( _count <= MAX_TOKENS_PER_TRANSACTION, "Count exceeded max tokens per transaction." );
        require( block.timestamp >= _startTime, "Public sale has not started yet." );

        uint256 supply = totalSupply();
        require( supply + _count <= MAX_SUPPLY,        "Exceeds max Python supply." );
        require( msg.value >= PRICE * _count,         "Ether sent is not correct." );

        for(uint256 i = 0; i < _count; ++i){
            _safeMint( msg.sender, supply + i, "" );
        }
    }

    //onlyDelegates
    function airdrop(address _wallet, uint256 _count) external onlyDelegates {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Python supply");
        
        for(uint256 i = 0; i < _count; ++i){
            _safeMint(_wallet, supply + i, "" );
        }
    }

    function setPrice(uint256 _newPrice) external onlyDelegates {
        PRICE = _newPrice;
    }

    function setMaxSupply (uint256 _newMaxSupply) external onlyDelegates { 
        MAX_SUPPLY = _newMaxSupply;
    }

    function setStartTime(uint256 _newStartTime) external onlyDelegates {
        _startTime = _newStartTime;
    }

    function setmaxMintAmount(uint256 _newMaxTokensPerTransaction) public onlyDelegates {
        MAX_TOKENS_PER_TRANSACTION = _newMaxTokensPerTransaction;
    }

    function pause(bool _updatePaused) public onlyDelegates {
        require( paused != _updatePaused, "New value matches old" );
        paused = _updatePaused;
    }

    function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates {
        _baseTokenURI = _newBaseURI;
        _baseTokenSuffix = _newSuffix;
    }

    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), _baseTokenSuffix)) : "";
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
}