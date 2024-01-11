// SPDX-License-Identifier: MIT


// RETROOOOOOOOOOoooooooooooooooooooooooOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOoooooooo
// ooooooOOOOOOOOOOoooooooooooooooooooooooOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOooooo
// OOOOOOOOOOOOOOOOOOOOOOooooooooooooooooooooooOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";

contract NFT is ERC721A, Ownable {

    // collection details
    uint256 public constant price = 0 ether;
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant MAX_TOKENS_PER_TX = 10;

    // variables and constants
    string public baseURI = 'RetroDudes://TheseAreNotTheDudesYouAreLookingFor/';
    bool public isMintActive = false;
    mapping(address => uint256) public MintsPerAddress;
    address public Wallet = 0xc31453E6D438FDF64Db0c0Fe77839676002506E0;

    constructor() ERC721A("RetroDudes", "RetroDudes") {

    }

    function mint(uint256 _quantity) external payable {
        // active check
        require(isMintActive
            , "Retro Dudes: public mint is not active");
        // supply check
        require(_quantity + totalSupply() < MAX_SUPPLY
            , "Retro Dudes: not enough remaining to mint this many");
        // Max Mint Check
        require(_quantity <= MAX_TOKENS_PER_TX
            , "Retro Dudes: max mints per transaction exceeded");
        // Amount to mint Check
        require(_quantity > 0
            , "Retro Dudes: Must mint at least 1");
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

    function devMint() external onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function withdrawBalance() public onlyOwner {
        require(address(this).balance > 0
            , "Retro Dudes: nothing to withdraw");

        uint256 _balance = address(this).balance;

        // wallet
        (bool walletSuccess, ) = Wallet.call{
            value: _balance }("");
        require(walletSuccess
            , "Retro Dudes: withdrawal failed");

    }


}
