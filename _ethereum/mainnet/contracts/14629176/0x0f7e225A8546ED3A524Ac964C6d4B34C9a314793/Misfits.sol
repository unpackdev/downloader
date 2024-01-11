// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
contract Misfits is Ownable, ERC721A, ReentrancyGuard, EIP712 {

  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public immutable mintlistPrice;
  address private immutable treasuryWallet;
  //added purely to verify collectionsize, is it needed?
  uint256 public immutable maxCollectionSize;
  bool public publicSale;
  /// @dev list of public sale voucherId's which have been redeemed. ?? will it clash if i use signature?
  mapping(bytes => uint256) private _publicSaleVoucherIds;
  struct NFTVoucher {
      // specify client to redeem this voucher
      address client;
      // ID to check if valid
      uint256 time;
      // token price
      uint256 price;
      // max amount to mint
      uint256 max_mint;

  }
  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_,
    uint256 mintlistPriceWei_,
    address treasuryWallet_
  ) 
  ERC721A("Misfits", "MFT", maxBatchSize_, collectionSize_) 
  EIP712("Misfits-Voucher", "1")
  {
    publicSale = false;
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
    mintlistPrice = mintlistPriceWei_;
    treasuryWallet = treasuryWallet_;
    maxCollectionSize = collectionSize_;
    require(
      amountForDevs <= collectionSize_,
      "larger collection size needed"
    );
    // is there a point of checking it here again? since it can catch error on init
    require(
      amountForDevs % maxPerAddressDuringMint == 0,
      "amount for devs must be multiple of batch size"
    );

  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

    /// @notice Redeem the voucher
    /// @param voucher Raw voucher info
    /// @param signature Voucher signature signed with owner's private key
    function whitelistMint(NFTVoucher calldata voucher, bytes calldata signature, uint qty)
        external
        payable
        callerIsUser
    {
        _verify(voucher, signature);
        require(voucher.max_mint >= qty ,"you are not eligible for so many");
        require(totalSupply() + qty <= collectionSize, "reached max supply");
        require(numberMinted(msg.sender) == 0,"you are only allowed to buy once");
        require(
            voucher.time > block.timestamp ,
            "redeem: Voucher has expired"
        );
        _safeMint(msg.sender, qty);
        refundIfOver(mintlistPrice * qty);
    }
    function publicMint(NFTVoucher calldata voucher, bytes calldata signature, uint qty)
        external
        payable
        callerIsUser
    {
        _verify(voucher, signature);
        require(voucher.max_mint >= qty ,"you are not eligible for so many");
        require(totalSupply() + qty <= collectionSize, "reached max supply");
        require(publicSale == true,"public sale is not on yet");
        require(
            voucher.time > block.timestamp ,
            "redeem: Voucher has expired"
        );
        require(
            _publicSaleVoucherIds[signature] == 0,
            "redeem: Voucher has been redeemed"
        );
        _publicSaleVoucherIds[signature] = 1;
        _safeMint(msg.sender, qty);
        refundIfOver(mintlistPrice * qty);
    }
    /// @dev Verify signature (EIP-712)
    function _verify(NFTVoucher calldata voucher, bytes calldata signature)
        private
        view
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFTVoucher(address client,uint256 time,uint256 price,uint256 max_mint)"
                    ),
                    _msgSender(),
                    voucher.time,
                    voucher.price,
                    voucher.max_mint
                    
                )
            )
        );
        require(
            owner() == ECDSA.recover(digest, signature),
            "redeem: Signature invalid or unauthorized"
        );
    }



  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }



  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(treasuryWallet, maxBatchSize);
    }
  }

  //  metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  /// @dev set publicSale var
    function togglePublicSale() external onlyOwner {
        if (publicSale == false) {
            publicSale = true;
        } else {
          publicSale = false;
        }
        
        
    } 
  // // contract metadata
  // string private _contractURI;
  // function setContractURI(string calldata URI) external onlyOwner {
  //     _contractURI = URI;
  // }
  // function contractURI() public view returns (string memory) {
  //     return _contractURI;
  // }


  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = treasuryWallet.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

}