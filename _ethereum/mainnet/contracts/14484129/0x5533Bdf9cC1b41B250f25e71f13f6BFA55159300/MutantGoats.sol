// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./PreSalesActivation.sol";
import "./PublicSalesActivation.sol";
import "./Whitelist.sol";
import "./ERC721A.sol";
import "./Withdrawable.sol";

//             (\\          
//          .--,\\\__       
//           `-.    a`-.__
//             |         ')
//            / \ _.-'-,`;
//           /     |   { /
// ..-"``~"-'      ;    )
//                ;'    `
//               ;'
//             ;'
//     ,    /;'|
//  ,;';\   |\ |       _____          __                 __     ________              __           
//       \  || |      /     \  __ ___/  |______    _____/  |_  /  _____/  _________ _/  |_  ______ 
//        | )| )     /  \ /  \|  |  \   __\__  \  /    \   __\/   \  ___ /  _ \__  \\   __\/  ___/ 
//        | || |    /    Y    \  |  /|  |  / __ \|   |  \  |  \    \_\  (  <_> ) __ \|  |  \___ \  
//        | \| \    \____|__  /____/ |__| (____  /___|  /__|   \______  /\____(____  /__| /____  > 
//        `##`##            \/                 \/     \/              \/           \/          \/  
//

contract MutantGoats is
    Ownable,
    ERC721A,
    PreSalesActivation,
    PublicSalesActivation,
    Whitelist,
    Withdrawable
{
    uint256 public constant TOTAL_MAX_QTY = 4888;
    uint256 public constant AIRDROP_MINT_MAX_QTY = 88;
    uint256 public constant PRESALES_MAX_QTY = 4000;
    uint256 public constant SALES_MAX_QTY = TOTAL_MAX_QTY - AIRDROP_MINT_MAX_QTY;
    uint256 public constant MAX_QTY_PER_MINTER = 5;
    uint256 public constant PRE_SALES_PRICE = 0.06 ether;
    uint256 public constant PUBLIC_SALES_START_PRICE = 0.08 ether;

    mapping(address => uint256) public preSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    uint256 public preSalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public mintedForAirdropQty = 0;

    string private _tokenBaseURI;

    constructor() ERC721A("Mutant Goats", "MUTANTGOAT") Whitelist("MutantGoats", "1") {}

    function getPrice() public view returns (uint256) {
        // Public sales
        if (isPublicSalesActivated()) {
            return PUBLIC_SALES_START_PRICE;
        }
        return PRE_SALES_PRICE;
    }

    function preSalesMint(
        uint256 _mintQty,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPreSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(
            preSalesMintedQty + publicSalesMintedQty + _mintQty <=
                SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            preSalesMintedQty + _mintQty <= PRESALES_MAX_QTY,
            "Exceed pre-sales max limit"
        );
        require(
            preSalesMinterToTokenQty[msg.sender] + _mintQty <= _signedQty,
            "Exceed signed quantity"
        );
        require(msg.value >= _mintQty * getPrice(), "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        preSalesMinterToTokenQty[msg.sender] += _mintQty;
        preSalesMintedQty += _mintQty;

        _safeMint(msg.sender, _mintQty);
    }

    function publicSalesMint(uint256 _mintQty)
        external
        payable
        isPublicSalesActive
    {
        require(
            preSalesMintedQty + publicSalesMintedQty + _mintQty <=
                SALES_MAX_QTY,
            "Exceed sales max limit"
        );
        require(
            publicSalesMinterToTokenQty[msg.sender] + _mintQty <=
                MAX_QTY_PER_MINTER,
            "Exceed max mint per minter"
        );
        require(msg.value >= _mintQty * getPrice(), "Insufficient ETH");
        require(tx.origin == msg.sender, "Contracts not allowed");

        publicSalesMinterToTokenQty[msg.sender] += _mintQty;
        publicSalesMintedQty += _mintQty;

         _safeMint(msg.sender, _mintQty);
    }

    function mintAirdrop(uint256 amount) external onlyOwner {
        require(
            mintedForAirdropQty + amount <= AIRDROP_MINT_MAX_QTY,
            "Exceed gift max limit"
        );

        mintedForAirdropQty += amount;

        _safeMint(msg.sender, amount);
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}