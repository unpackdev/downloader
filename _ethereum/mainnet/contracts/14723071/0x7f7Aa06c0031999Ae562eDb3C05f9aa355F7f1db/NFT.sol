// SPDX-License-Identifier: MIT
// written by Cheese Master

pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";

contract NFT is ERC721A, Ownable {

    // collection details
    uint256 public constant price = 0.004 ether;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_TOKENS_PER_MINT = 100;

    // variables and constants
    string public baseURI = 'Possessed://TheseAreNotTheDroidsYouAreLookingFor/';
    bool public isMintActive = false;
    mapping(address => uint256) public MintsPerAddress;
    address public Wallet = 0xc31453E6D438FDF64Db0c0Fe77839676002506E0;

    constructor() ERC721A("PossessedPunks", "PossessedPunks") {

    }

    function mint(uint256 _quantity) external payable {
        // active check
        require(isMintActive
            , "Possessed Punks: public mint is not active");
        // price check
        require(msg.value == _quantity * price
            , "Possessed Punks: insufficient amount paid");
        // supply check
        require(_quantity + totalSupply() < MAX_SUPPLY
            , "Possessed Punks: not enough remaining to mint this many");
        // Max Mint Check
        require(MintsPerAddress[msg.sender] + _quantity <= MAX_TOKENS_PER_MINT
            , "Possessed Punks: max mints per address exceeded");

        // mint
        MintsPerAddress [msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function setWallet(address _newWallet) external onlyOwner {
        Wallet = _newWallet;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function toggleMint() public onlyOwner {
        isMintActive = !isMintActive;
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0
            , "Possessed Punks: nothing to withdraw");

        uint256 _balance = address(this).balance;

        // wallet
        (bool walletSuccess, ) = Wallet.call{
            value: _balance }("");
        require(walletSuccess
            , "Possessed Punks: withdrawal failed");

    }

}

