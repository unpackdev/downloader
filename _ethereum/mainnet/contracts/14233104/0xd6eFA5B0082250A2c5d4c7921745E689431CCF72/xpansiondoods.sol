// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721EnumerableLite.sol";
import "./Delegated.sol";
import "./Strings.sol";

contract XpansionDoods is ERC721EnumerableLite, Delegated {
    using Strings for uint256;

    uint256 public PRICE = 0.029 ether;
    uint256 private MAX_TOKENS_PER_TRANSACTION = 10;
    uint256 private MAX_TOKENS_FREE_TXN = 3;
    uint256 private MAX_SUPPLY = 10000;
    uint256 private freeLimit = 1250;
    bool private saleLive = false;
    bool private reserved = false;

    string public _baseTokenURI = "";
    string private _baseTokenSuffix = ".json";

    address art = 0x92F8584b308a84bD557faA62919d2e8d9134065F;
    address dev = 0xCd2299e5090b42053FBb1779d6CC5DEcB87A0405;

    constructor() ERC721B("XpansionDoods NFT", "XDOODS") {
    }

    function reserveNFTs(address to) public onlyOwner {
        require(!reserved, "XDoods were already reserved!");
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= 40; ++i) {
            _safeMint(to, supply + i, "");
        }

        reserved = true;
    }

    function mint(uint256 _count) external payable {
        require(saleLive, "Sale is not live yet!");
        uint256 supply = totalSupply();
        if(supply < freeLimit){
            require(_count <= MAX_TOKENS_FREE_TXN, "Max of 2 XDoods per txn during free period!");
        }
        require(
            _count <= MAX_TOKENS_PER_TRANSACTION, 
            "Count exceeded max tokens per transaction."
            );

        require(supply + _count <= MAX_SUPPLY, "Exceeds max XDoods token supply.");
        if (supply + _count <= freeLimit) {
            for (uint256 i = 1; i <= _count; ++i) {
                _safeMint(msg.sender, supply + i, "");
            }
        } else {
            require(msg.value >= PRICE * _count, "Ether sent is not correct.");
            for (uint256 i = 1; i <= _count; ++i) {
                _safeMint(msg.sender, supply + i, "");
            }
        }
    }

    function setSale() external onlyDelegates {
        require(!saleLive, "Sale is already live!");
        saleLive = true;
    }

    function setPrice(uint256 _newPrice) external onlyDelegates {
        PRICE = _newPrice;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyDelegates {
        _baseTokenURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Provided token ID does not exist."
        );

        string memory baseURI = _baseTokenURI;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _baseTokenSuffix
                    )
                )
                : "";
    }

    function contractURI() public view returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmNdSCNweD5cX2uM5tNvS71TzQcbxwezdVyKK8WzmZ7ttc/contract_metadata.json";
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(art).transfer((balance * 65)/100);
        payable(dev).transfer((balance * 35)/100);
    }
}