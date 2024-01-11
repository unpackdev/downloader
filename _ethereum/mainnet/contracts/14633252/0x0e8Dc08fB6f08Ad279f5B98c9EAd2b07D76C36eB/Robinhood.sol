/*
         
                                                   /@&*                                   
                                     .@@((((((((((((((@@                            
                                  @#(((((((((((((((((((((%@                         
                               @((((((((((((((((((((((((((((@  %@@&(@(((#(&(/(@@@#  
                            @%((((((((((((((((((((((((((@&##&####(@@&(((((((((/////*
                          @((((((((((((((((((((((#@#%#@@&#####&#(#(@(((((/@,@@@&    
                        @((((((((((((((((((#@@@%#%%%%##%&@@@@@@@@(                  
                      @#(((((((((((((%@@@@@@@@@@@@@@@&(((((((((@                    
                    @((((((#(@@@#(((((((((((((((((((((((((((@@%@(@%                 
                 @@(((@@@(((((((((((((((((((((((((((((((((((((((#(@(#@              
              @@@@@(((((((((((((((((((((((((((((((((((((((((((((((((((@             
          @@(@#(((((((((((((((((((((((((((((((((((((((((((((((((((((&@              
      @##((((((((((((@@@@@@*             ,@@@@@(((((((((((((((((((@@                
     @((((&@@@@#                                   @@@((((((((((@#                  
                                                        @@@@@@%   
       
       ,---.    .---.  ,---.   ,-..-. .-..-. .-. .---.   .---.  ,'|"\   
       | .-.\  / .-. ) | .-.\  |(||  \| || | | |/ .-. ) / .-. ) | |\ \  
       | `-'/  | | |(_)| |-' \ (_)|   | || `-' || | |(_)| | |(_)| | \ \ 
       |   (   | | | | | |--. \| || |\  || .-. || | | | | | | | | |  \ \
       | |\ \  \ `-' / | |`-' /| || | |)|| | |)|\ `-' / \ `-' / /(|`-' /
       |_| \)\  )---'  /( `--' `-'/(  (_)/(  (_) )---'   )---' (__)`--' 
           (__)(_)    (__)       (__)   (__)    (_)     (_)             
                                     ,---.    .--.     .---.   .---.                   
                v .   ._, |_  .,     | .-.\  / /\ \   ( .-._) ( .-._)  
      `-._\/  .  \ /    |/_          | |-' )/ /__\ \ (_) \   (_) \
          \\  _\, y | \//            | |--' |  __  | _  \ \  _  \ \ 
    _\_.___\\, \\/ -.\||             | |    | |  |)|( `-'  )( `-'  ) 
      `7-,--.`._||  / / ,            /(     |_|  (_) `----'  `----'   
      /'     `-. `./ / |/_.'
                |    |//
                |_    /
                |-   |
                |   =|
                |    |
---------------/ ,  . \-------------------------------------------------------------                                        
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "./SignatureChecker.sol";
import "./SignerManager.sol";
import "./BaseTokenURI.sol";
import "./ERC721ACommon.sol";
import "./ArbitraryPriceSeller.sol";
import "./Monotonic.sol";
import "./EnumerableSet.sol";
import "./ERC2981.sol";

contract BeachedWhayules is
    ERC721ACommon,
    BaseTokenURI,
    ArbitraryPriceSeller,
    SignerManager,
    ERC2981
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    constructor(address payable beneficiary, address royaltyReceiver)
        ERC721ACommon("Robinhood Pass", "RHAIO")
        BaseTokenURI("")
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: 2500,
                lockTotalInventory: false,
                maxPerAddress: 100,
                maxPerTx: 10,
                freeQuota: 0,
                lockFreeQuota: false,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _setDefaultRoyalty(royaltyReceiver, 750);
    }

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        _safeMint(to, n);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Flag indicating that public minting is open.
     */
    bool public publicMinting;

    /**
    @notice Set the `publicMinting` flag.
     */
    function setPublicMinting(bool _publicMinting) external onlyOwner {
        publicMinting = _publicMinting;
    }

    /**
    @notice Price to mint for the general public.
     */
    uint256 public publicPrice = 0.04 ether;

    /**
    @notice Update the public-minting price.
     */
    function setPublicPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    /**
    @notice Mint as a member of the public.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(publicMinting, "Minting closed");
        _purchase(to, n, publicPrice);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}