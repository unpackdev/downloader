// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/* fun pfp for degens */

/* no utility */
/* no roadmap */
/* no discord */
/* no bullshit */

/* just fun, long time no degen... */

/* Supply: 1345 Free, 1000 at 0.002 ETH */
/* if sold out, 1 eth to top degen (biggest holder) after the first 24 hours + surprise to holder of 5 degens */
/* royalties will be invested for more degenerry */

/* enjoy */

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

/* Possible Degen errors */

error AmountNFTPerWalletExceeded();
error MaxSupplyExceeded();
error NotEnoughFunds();

error FreeMintNotActivated();
error DegenSaleNotActivated();
error NonExistentToken();

contract DegenBookClub is ERC721A, Ownable {
    using Strings for uint;

    enum Step {
        First,
        FreeDegenMint,
        DegenSale,
        Last
    }

    Step public degenStep;

    uint256 private constant MAX_AMOUNT = 2345;
    uint256 private constant MAX_FREEMINT = 1345;    
    uint256 private constant MINT_PRICE = 0.002 ether;

    string public baseURI;

    mapping(address => uint256) amountNFTperWalletFreeMint;

    mapping(address => uint256) amountNFTperWalletDegenSale;

    address payable gainAddress; 

    constructor(string memory _baseURI, address payable _gainAddress)
    ERC721A("DegenBookClub", "DBC")
    Ownable(msg.sender) {
        baseURI = _baseURI;
        gainAddress = _gainAddress;
    }

    /**
    * @notice How to free mint ?
    *
    * @param _account where you want ? (eth wallet address)
    * @param _quantity how much you want ? you can only get 2 here anyway
    */
    
    function freeMint(address _account, uint256 _quantity) public {
        if(degenStep != Step.FreeDegenMint) {
            revert FreeMintNotActivated();
        }
        if(amountNFTperWalletFreeMint[msg.sender] + _quantity > 2) {
            revert AmountNFTPerWalletExceeded();
        }
        if(totalSupply() + _quantity > MAX_FREEMINT) {
            revert MaxSupplyExceeded();
        }
        amountNFTperWalletFreeMint[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice How to mint ?
    *
    * @param _account where you want ? (eth wallet address)
    * @param _quantity how much you want ? 10 max per wallet, price is 0.002 eth for one
    */
    
    function publicMint(address _account, uint256 _quantity) external payable {
        
        if(degenStep != Step.DegenSale) {
            revert DegenSaleNotActivated();
        }
        if(amountNFTperWalletDegenSale[msg.sender] + _quantity > 10) {
            revert AmountNFTPerWalletExceeded();
        }
        if(totalSupply() + _quantity > MAX_AMOUNT) {
            revert MaxSupplyExceeded();
        }
        if(msg.value < MINT_PRICE * _quantity) {
            revert NotEnoughFunds();
        }
        amountNFTperWalletDegenSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    /**
    * @notice How to change step ?
    */

    function setStep(uint _step) external onlyOwner {
        degenStep = Step(_step);
    }

    /**
    * @notice How to airdrop ? (owner only)
    *
    * @param _to where ?
    * @param _quantity how much ?
    */

    function airdrop(address _to, uint256 _quantity) external onlyOwner {
        if(totalSupply() + _quantity > MAX_AMOUNT) {
            revert MaxSupplyExceeded();
        }
        _safeMint(_to, _quantity);
    }

    /**
    * @notice How to change the degenURI ?
    *
    * @param _baseURI the new degenURI
    */

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
    * @notice How to check token URI of a NFT by his ID ?
    *
    * @param _tokenId The ID of the NFT you want to have the URI of the metadatas
    *
    * @return string URI of an NFT by his ID
    */

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        if(!_exists(_tokenId)) {
            revert NonExistentToken();
        }

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    /**
    * @notice How to eth ? release gains so I can reward degens
    */
    
    function releaseAll() external onlyOwner {
        (bool success,) = gainAddress.call{value: address(this).balance}("");
        require(success);
    }

}