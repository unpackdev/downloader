// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";


contract Ukr3in3 is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 10_000;
    uint256 public constant PRICE = 0.01 ether;
    uint public constant MAX_PURCHASE = 3;

    string public baseURI;
    address public signAddress;

    uint256 private _currentId;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _signAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(_uri);
        signAddress = _signAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function mint(uint256 amount) public payable {
        require(
            amount <= MAX_PURCHASE,
            "Can only mint 3 tokens at a time"
        );

        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Purchase would exceed max supply"
        );

        require(
            msg.value == PRICE * amount,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < amount; i++) {
            _currentId++;
            _safeMint(msg.sender, _currentId);
        }
    }

    function raffleMint(uint256 price, uint256 amount, bytes memory _signature) public payable {
        require(
            msg.value == price * amount,
            "Ether value sent is not correct"
        );

        require(
            signatureWallet(msg.sender, price, amount, _signature) == signAddress,
            "Not authorized to mint"
        );

        for (uint256 i = 0; i < amount; i++) {
            _currentId++;
            _safeMint(msg.sender, _currentId);
        }
    }

    function signatureWallet(address wallet, uint256 price, uint256 amount, bytes memory _signature) public pure returns (address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(wallet, price, amount))
            ), _signature
        );
    }

    function setSignAddress(address _signAddress) external onlyOwner {
        signAddress = _signAddress;
    }

    function totalSupply() public view returns (uint256) {
        return _currentId;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}
