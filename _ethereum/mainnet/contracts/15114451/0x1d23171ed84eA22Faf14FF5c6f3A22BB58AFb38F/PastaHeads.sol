// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ERC721A.sol";

contract PastaHeads is ERC721A, Ownable {
    uint256 public immutable MAX_PER_WALLET;
    uint256 public immutable maxSupply;
    bool public isMintActive;
    string private baseURI_;
    string private _contractURI;

    mapping(address => uint256) private holders;

    constructor(uint256 _maxSupply, uint256 _tokensPerWallet)
        ERC721A("PastaHeads", "PASTA")
    {
        maxSupply = _maxSupply;
        MAX_PER_WALLET = _tokensPerWallet;
    }

    modifier mintIsActive() {
        require(isMintActive, "Sale is not active");
        _;
    }

    modifier notSoldOut(uint256 amount) {
        require(totalSupply() + amount <= maxSupply, "Sold out");
        _;
    }

    modifier correctAmount(uint256 amount) {
        require(
            holders[msg.sender] + amount <= MAX_PER_WALLET,
            "Invalid amount"
        );
        _;
    }

    function changeSaleStatus(bool _status) external onlyOwner {
        isMintActive = _status;
    }

    function ownerMint(uint256 _amount) public onlyOwner notSoldOut(_amount) {
        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount)
        public
        mintIsActive
        correctAmount(_amount)
        notSoldOut(_amount)
        payable
    {
        holders[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI_ = _newBaseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }    
}