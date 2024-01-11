// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721A.sol";

contract NFT is ERC721A, Ownable {
    // state
    uint public _price = 0.06 ether;
    uint public _allowlist_price = 0.04 ether;
    uint public _max_supply = 6000;
    uint public _max_supply_per_mint = 6;
    uint public start_time = 0;
    uint public end_time = 0;

    address public _server = 0x7eFb785389b55699378d6A531E5ecf0b3bF30625;
    string public _baseTokenURI;
    bool public paused = true;
    address public contractOwner;

    event Pause();
    event Unpause();

    constructor() ERC721A("Atticus", "ATTC") {}

    // view
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    // public
    function purchase_presale(uint256 nonce, bytes memory signature, uint quantity) public payable whenNotPaused {
        require(verify_code(nonce, signature), "Invalid presale code");
        require(_allowlist_price * quantity <= msg.value, "Ether value sent is not correct");
        mintToSender(quantity);
    }

    function purchase(uint quantity) public payable whenNotPaused {
        require(_price * quantity <= msg.value, "Ether value sent is not correct");
        mintToSender(quantity);
    }

    // admin
    function reserve(uint256 num) public onlyOwner {
         require(totalSupply()+ num <= _max_supply, "Minting would exceed max supply");

        _safeMint(msg.sender, num);
    }

    function update_price(uint256 price) public onlyOwner {
        _price = price;
    }

    function update_allowlist_price(uint256 price) public onlyOwner {
        _allowlist_price = price;
    }

    function update_max_supply(uint256 max_supply) public onlyOwner {
        _max_supply = max_supply;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    function setServer(address server) public onlyOwner {
        _server = server;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        start_time = 0;
        end_time = 0;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        start_time =  block.timestamp;
        end_time = start_time + 3600 seconds;
        emit Unpause();
    }

    // internal
    function mintToSender(uint numberOfTokens) internal {
        require(totalSupply() + numberOfTokens <= _max_supply, "Minting would exceed max supply");
        require(numberOfTokens <= _max_supply_per_mint, "Minting would exceed max supply per mint");

        _safeMint(msg.sender, numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function verify_code(uint256 nonce, bytes memory signature) internal returns (bool) {
        bytes memory encoded = abi.encode(
            msg.sender,
            nonce
        );
        bytes32 messageHash = keccak256(encoded);
        require(signature.length == 65, "invalid signature length ");

        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }
        return ecrecover(messageHash, 27, r, s) == _server || ecrecover(messageHash, 28, r, s) == _server;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    // modifiers
    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }
}