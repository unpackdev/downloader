// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./console.sol";
import "./Strings.sol";

contract TheBirdCage is ERC721A {
    using Strings for uint256;

    uint public maxSupply = 10000;

    constructor() ERC721A("TheBirdCage", "TBC") {
        _mint(msg.sender, 1000);
    }

//PAUSE_________________________________________________________________________
    bool public paused = false;
    
    function setPaused(bool _value) public onlyGang{
        paused = _value;
    }

//MINTING_______________________________________________________________________
    uint public price = 0.003 ether;

    function setPrice(uint _value) public onlyGang{
        price = _value;
    }
    
    uint public maxTokensPerTx = 3;

    function setMaxTokenPerTx(uint _value) public onlyGang{
        maxTokensPerTx = _value;
    }

    function mint(uint256 quantity) external payable {
        require(!paused, "minting is paused");
        require(msg.sender == tx.origin,"be yourself");
        require(msg.value == quantity * price,"Please send the exact amount.");

        _internalMint(msg.sender, quantity);
    }

    function gift(address _addr, uint _amount) external onlyGang {
        _internalMint(_addr, _amount);
    }

    function _internalMint(address _addr,uint256 _qtty) internal
    {
        require(totalSupply() + _qtty < maxSupply + 1,"no more tokens available for minting");
        require( _qtty < maxTokensPerTx + 1, "max per tx reached.");

        _mint(_addr, _qtty);
    }

//URI_______________________________________________________________________
    string metadataPrefx = "ipfs://QmfLcGLW5H2aXEoxAdkauoGUJPxKTsX38g1fawepx6TFa1/";
    string metadataSuffix = ".json";

    function setMetadataPrefix(string memory _value) public onlyGang{
        metadataPrefx = _value;
    }
    function setMetadataSuffix(string memory _value) public onlyGang{
        metadataSuffix = _value;
    }

    function tokenURI(uint _tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(metadataPrefx, _tokenId.toString(), metadataSuffix));
    }

//MONEY______________________________________________________________________
    address private _dude = 0x4aa9185A643376B684EbA25754DcD1660992bf59;
    address private _dev = 0xF445F101982336A29Edfa9d90844D11b89C68C4f;
    
    modifier onlyGang() {
        require (
            msg.sender == _dude ||
            msg.sender == _dev,
            "unauthorized"
        );
        _;
    }

    function withdraw() public onlyGang {
        uint256 balance = address(this).balance;
        uint256 portion = balance/2;
        payable(_dude).transfer(portion);
        payable(_dev).transfer(balance-portion);
    }
}