// SPDX-License-Identifier: GPL-3.0

/**
                                                                                                                                                      
                                                                                       
                                
                 ..   8"=,,88,   _.
                  8""=""8'  "88a88'
             .. .;88m a8   ,8"" "8
              "8"'  "88"  A"     8;
                "8,  "8   8  'u'   "8,
                 "8   8,  8,       "8
                  8,  "8, "8,    ___8,
                  "8,  "8, "8mm""""""8m.
                   "8,algo.8"'   ,mm"
                   ,8"  _8"  .lite"
                  ,88P"""""I88con8
                  "'         "much0"
                              "a8,   
                               "m8   
                                 "o8_
                     ,by:jawn.m""i,,r8""  ,johnny,'.
                    m""    . "8.8 I8  ,8"   .  "88
                   i8  . '  ,mi""8I8 ,8 . '  ,8" 88
                   88.' ,mm""    "iain"m,,mm'"    8
                   "8_m""         "I8   ""'
                    "8             I8
                                   I8_ 
                                   I8""
                                   I8
                                  _I8
                                 ""I8
                                   I8     ALGO LITE




*/

pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IMintable.sol";

import "./console.sol";

/// @author Iain Nash @isiain
/// @dev Minting Contract for Algo Lite Project by @jawn
/// @custom:warning UNAUDITED: Use at own risk
contract AlgoLiteSale is ReentrancyGuard {
    /// Public sale amount (0.1 ETH)
    uint256 private constant PUBLIC_SALE_AMOUNT = 0.1 * 10**18;
    /// Private sale amount in tokens (1 Token)
    uint256 private constant PRIVATE_SALE_AMOUNT = 1 * 10**18;

    /// Mintable instance
    IMintable private immutable mintable;
    /// Private sale token
    IERC20 private immutable privateSaleToken;

    uint256 private numberPublicSale;
    uint256 private numberSoldPublic;

    uint256 private numberPrivateSale;
    uint256 private numberSoldPrivate;

    /// @dev Creates a new sales contract
    /// @param _mintable Mintable contract
    /// @param _privateSaleToken token for private sales section
    constructor(IMintable _mintable, IERC20 _privateSaleToken) {
        mintable = _mintable;
        privateSaleToken = _privateSaleToken;
    }

    modifier onlyMintableOwner() {
        require(msg.sender == mintable.owner(), "only owner");
        _;
    }

    /// @dev Public purchase token, limited by number sold public, requires ETH value
    function purchase() public payable nonReentrant {
        require(numberSoldPublic < numberPublicSale, "No sale");
        require(msg.value >= PUBLIC_SALE_AMOUNT, "Too low");
        mintable.mint(msg.sender);
        numberSoldPublic += 1;
        console.log("has");
        console.log(msg.value);
        console.log("bal");
        console.log(address(this).balance);
    }

    /// @dev Returns sales info
    /// @return (numberpublic, soldpublic, numberprivate, soldprivate)
    function saleInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            numberPublicSale,
            numberSoldPublic,
            numberPrivateSale,
            numberSoldPrivate
        );
    }

    /// @dev Purchase with token private sales fn
    /// Requires: 1. token amount to transfer,
    /// @param editions number of editions to purchase (needs to have same tokens)
    function purchaseWithTokens(uint256 editions) public nonReentrant {
        require(numberSoldPrivate + editions <= numberPrivateSale, "No sale");
        require(editions > 0, "Min 1");
        // Attempt to transfer tokens for mint
        try
            privateSaleToken.transferFrom(
                msg.sender,
                mintable.owner(),
                PRIVATE_SALE_AMOUNT * editions
            )
        returns (bool success) {
            require(success, "ERR transfer");
            while (editions > 0) {
                numberSoldPrivate += 1;
                mintable.mint(msg.sender);
                editions -= 1;
            }
        } catch {
            revert("ERR transfer");
        }
    }

    /// @dev Withdraw ETH from public minting
    function withdrawEth() public onlyMintableOwner {
        (bool sent, ) = mintable.owner().call{
            value: address(this).balance,
            gas: 100_000
        }("");
        require(sent, "Failed to send Ether");
    }

    /// @dev Set number of NFTs that can be purchased
    /// @param newPublicNumber new number allowed for public sale
    /// @param newPrivateNumber new number allocated for private sale
    function setSaleNumbers(uint256 newPublicNumber, uint256 newPrivateNumber)
        public
    {
        numberPublicSale = newPublicNumber;
        numberPrivateSale = newPrivateNumber;
    }
}
