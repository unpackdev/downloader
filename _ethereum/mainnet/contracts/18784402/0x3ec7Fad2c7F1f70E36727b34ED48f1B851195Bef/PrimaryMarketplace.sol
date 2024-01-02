//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC1155URIStorageUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./FNVvoucher.sol";


contract Fanverse is
    ERC1155URIStorageUpgradeable,
    ERC2981Upgradeable,
    EIP712Upgradeable,
    OwnableUpgradeable
{
    uint256 public platformFees; 
    struct TokenId {
        bool isNFT;
        bool isTokenId;
    }
    address public Admin;
    mapping(uint256 => uint256) allMinted; //mapping to keep track whether all tokens of a tokenId have been minted or not
    mapping(uint256 => uint256) primaryListingAmountLeft; //mapping to keep track of copies left of the listed NFT
    mapping(uint256 => uint256) mintAmountLeft; //mapping to keep track of copies left to be minted of an NFT
    mapping(uint256 => uint256) primaryCounterStatus; //mapping to keep track of counter status
    mapping(uint256 => TokenId) public detailsNFT;  //mapping to store detail of NFT
    IERC20 public fanversetokenInstance;
    event primaryFixBuy(
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        uint256 nftBatchAmount,
        uint256 nftPrice
    );
    event primaryAuction(
        address indexed seller,
        address indexed buyer,
        uint256 tokenId,
        uint256 nftPrice
    );
/**
 * Constructor function for disabling the initialization of the implementation.
 */
    constructor() {
        // _disableInitializers();
    }
/**
 * @notice Initializes the contract with the specified parameters.
 * @param uri The base URI for the token metadata.
 * @param _platformFees The platform fees percentage to be applied to transactions.
 * @param _adminAddress The address of the admin.
 * @dev This function is external and initializer.
 * @dev It requires the _adminAddress parameter to be non-zero.
 * @dev It initializes the contract by calling various initialization functions and setting up the necessary values.
 * @dev The __ERC1155_init function sets the base URI for the token metadata.
 * @dev The __ERC1155URIStorage_init function initializes storage for token IDs and URIs.
 * @dev The __ERC2981_init function initializes the royalty standard.
 * @dev The __EIP712_init function sets up the domain and version.
 * @dev The _setDefaultRoyalty function sets the royalty for the message sender.
 * @dev It assigns the _adminAddress to the Admin variable.
 * @dev It sets the fanversetokenInstance variable to an instance of the IERC20 interface pointing to the fanverseToken address.
 * @dev It assigns the _platformFees value to the platformFees variable.
 * @dev This function ensures that the necessary values are set correctly during contract initialization.
 */
    function initialize(
        string memory uri,
        uint256 _platformFees,
        address _adminAddress
    ) external initializer {
        //AZ--> Admin address can't be zero
        require(_adminAddress != address(0), "AZ");
        __ERC1155_init(uri); //Sets the base uri as uri
        __ERC1155URIStorage_init(); // Used for storage of tokenids and tokenuri
        __ERC2981_init(); //Initialization of royalty standard
        __EIP712_init("Fanverse", "1"); //Setting up the domain and version
        __Ownable_init();
        // _setDefaultRoyalty(msg.sender, 500); //Setting of royalty
        Admin = _adminAddress;
        platformFees = _platformFees;
    }

    /**
 * @notice Processes the primary purchase of an NFT.
 * @param mintVoucher The struct containing information about the minted NFT.
 * @param primaryListingvoucher The struct containing information about the primary listing.
 * @param redeemer The address of the redeemer who is purchasing the NFT.
 * @param nftAmount The amount of NFTs being purchased.
 * @param _fanvAmount The amount of Fanv Tokens being paid.
 * @dev This function is public and payable.
 * @dev It calls the fixBuyFlow function to handle the necessary steps for finalizing the purchase.
 * @dev After the purchase is finalized, it emits a primaryFixBuy event with the relevant information.
 * @dev This function allows users to purchase NFTs from the primary market and emits an event to notify interested parties.
 */

    function primaryBuy(
        FNVvoucher.mintVoucher memory mintVoucher,
        FNVvoucher.priListing memory primaryListingvoucher,
        address redeemer,
        uint256 nftAmount,
        uint256 _fanvAmount
    ) public payable {
        fixBuyFlow(
            mintVoucher,
            primaryListingvoucher,
            redeemer,
            nftAmount,
            _fanvAmount
        );
        emit primaryFixBuy(
            mintVoucher.nftOwner,
            redeemer,
            mintVoucher.tokenId,
            mintVoucher.amount,
            primaryListingvoucher.unitprice * (nftAmount)
        );
    }

    function fixBuyFlow(
        FNVvoucher.mintVoucher memory mintVoucher,
        FNVvoucher.priListing memory primaryListingvoucher,
        address redeemer,
        uint256 nftAmount,
        uint256 _fanvAmount
    ) internal {
        //INA--> Invalid NFT address
        require(mintVoucher.nftAddress == address(this), "INA");
        //VE-->Voucher Expired
        require(
            primaryCounterStatus[primaryListingvoucher.countervalue] == 0,
            "VE"
        );
        //ATM->All tokens minted
        require(allMinted[mintVoucher.tokenId] == 0, "ATM");
        //NFTL-->NFT should be listed
        require(primaryListingvoucher.listed == true, "NFTL");
        //MAZ--> Mint amount should be greater than zero
        require(mintVoucher.amount > 0, "MAZ");
        //Listing amount should be greater than zero
        require(primaryListingvoucher.amount > 0, "LAZ");
        //NFT amount should be greater than zero
        require(nftAmount > 0, "NAZ");
        //Mintable NFT should be more than listed NFT
        require(mintVoucher.amount >= primaryListingvoucher.amount, "MGL");

        //LLR-->Listed NFT less than required NFTs
        require(primaryListingvoucher.amount >= nftAmount, "LLR");
        if (primaryListingAmountLeft[primaryListingvoucher.countervalue] == 0) {
            primaryListingAmountLeft[
                primaryListingvoucher.countervalue
            ] = primaryListingvoucher.amount;
        }
        if (mintAmountLeft[mintVoucher.tokenId] == 0) {
            mintAmountLeft[mintVoucher.tokenId] = mintVoucher.amount;
        }
        //ODEB--> Owner doesn't have enough balance to be minted
        require(mintAmountLeft[mintVoucher.tokenId] >= nftAmount, "ODEB");
        //NELN--> Owner doesn't have enough listed NFTs
        require(
            primaryListingAmountLeft[primaryListingvoucher.countervalue] >=
                nftAmount,
            "NELN"
        );

        address minter = verifyMinter(mintVoucher);

        //IM-->Invalid Minter
        require(minter == mintVoucher.nftOwner, "IM");
        address lister = verifyLister(primaryListingvoucher);

        //IL--> Invalid Lister
        require(lister == address(primaryListingvoucher.nftOwner), "IL");
        //IU--> Invalid User
        require(lister == minter, "IU");

        mintAmountLeft[mintVoucher.tokenId] -= nftAmount;
        primaryListingAmountLeft[
            primaryListingvoucher.countervalue
        ] -= nftAmount;
        if (mintAmountLeft[mintVoucher.tokenId] == 0) {
            allMinted[mintVoucher.tokenId] = 1;
        }

        if (primaryListingAmountLeft[primaryListingvoucher.countervalue] == 0) {
            primaryCounterStatus[primaryListingvoucher.countervalue] = 1;
        }
        detailsNFT[mintVoucher.tokenId].isTokenId = true;

        _safeMint(
            lister,
            mintVoucher.tokenId,
            nftAmount,
            mintVoucher.tokenUri,
            mintVoucher.royaltyKeeper,
            mintVoucher.royaltyFees
        );
        _setApprovalForAll(lister, redeemer, true);
        
        if (primaryListingvoucher.isEth) {
            //PME--> Pay more eth
            require(
                (primaryListingvoucher.unitprice * (nftAmount)) <= msg.value,
                "PME"
            );
            distributeAmountInEth(lister, msg.value);
        } else {
            //PMF--> Pay more fanverse token
            require(
                (primaryListingvoucher.unitprice * (nftAmount)) <= _fanvAmount,
                "PMF"
            );
            distributeAmountInFanv(lister, _fanvAmount);
        }
        safeTransferFrom(
            lister,
            redeemer,
            primaryListingvoucher.tokenId,
            nftAmount,
            ""
        );

    }

 /**
 * @notice Distributes the specified amount of Fanv Tokens.
 * @param _receiver The address of the receiver who will receive the Fanv Tokens.
 * @param FanvAmount The amount of Fanv Tokens to be distributed.
 * @dev This function is internal.
 * @dev It calculates the service fees based on the platformFees percentage.
 * @dev It calculates the net amount of Fanv Tokens to be transferred to the receiver.
 * @dev It transfers the service fees from the caller to the Admin address.
 * @dev It transfers the net amount of Fanv Tokens from the caller to the receiver.
 * @dev This function allows for the distribution of Fanv Tokens with the deduction of service fees.
 */

    function distributeAmountInFanv(
        address _receiver,
        uint256 FanvAmount
    ) internal {
        uint256 serviceFees = ((FanvAmount * platformFees) / 10000);
        uint256 nftPrice = FanvAmount - serviceFees;
        fanversetokenInstance.transferFrom(msg.sender, Admin, serviceFees);
        fanversetokenInstance.transferFrom(msg.sender, _receiver, nftPrice);
    }

  /**
 * @notice Distributes the specified amount of Ether (ETH).
 * @param _receiver The address of the receiver who will receive the ETH.
 * @param ethAmount The amount of ETH to be distributed.
 * @dev This function is internal.
 * @dev It calculates the service fees based on the platformFees percentage.
 * @dev It calculates the net amount of ETH to be transferred to the receiver.
 * @dev It transfers the net amount of ETH from the contract to the receiver using a low-level call.
 * @dev It transfers the service fees from the contract to the Admin address using a low-level call.
 * @dev This function allows for the distribution of ETH with the deduction of service fees.
 * @dev It throws an error if the transfer of ETH fails.
 */

    function distributeAmountInEth(
        address _receiver,
        uint256 ethAmount
    ) internal {
        uint256 serviceFees = ((ethAmount * platformFees) / 10000);
        uint256 nftPrice = ethAmount - serviceFees;
        (bool success, ) = payable(_receiver).call{value: nftPrice}("");
        //FTP--> Failed to transfer NFT price
        require(success, "FTP");

        (bool success1, ) = payable(Admin).call{value: serviceFees}("");
        //FTS--> Failed to transfer NFT service fees
        require(success1, "FTS");
    }

   /**
 * @notice Safely mints a new token and assigns it to the specified address.
 * @param to The address to which the minted token will be assigned.
 * @param tokenId The ID of the minted token.
 * @param mintAmount The amount of tokens to be minted.
 * @param tokenURI The URI of the minted token.
 * @param royaltyKeeper The address of the royalty keeper for the token.
 * @param royaltyFees The amount of royalty fees to be assigned to the token.
 * @dev This function is internal.
 * @dev It mints the specified amount of tokens and assigns them to the specified address.
 * @dev It sets the URI of the token to the specified tokenURI.
 * @dev If a royalty keeper address is provided, it sets the royalty fees for the token.
 */
    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 mintAmount,
        string memory tokenURI,
        address royaltyKeeper,
        uint96 royaltyFees
    ) internal {
        _mint(to, tokenId, mintAmount, "");
        _setURI(tokenId, tokenURI);
        if (royaltyKeeper != address(0)) {
            _setTokenRoyalty(tokenId, royaltyKeeper, royaltyFees);
        }
    }

   /**
 * @notice Verifies the minter of a mint voucher.
 * @param voucher The mint voucher containing the necessary information.
 * @return The address of the minter if the verification is successful.
 * @dev This function is internal and view-only.
 * @dev It calculates the hash of the mint voucher using the _hashMintVoucher function.
 * @dev It recovers the minter's address from the hash and the signature using ECDSA.
 * @dev This function allows for the verification of the minter's address based on the provided mint voucher.
 */

    function verifyMinter(
        FNVvoucher.mintVoucher memory voucher
    ) internal view returns (address) {
        bytes32 digest = _hashMintVoucher(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
@dev this is an internal function that generates a 32 byte hash of a struct like object 
@param voucher struct like voucher that indicates all the required information of ERC1155 tokens of which the hash is to be generated
*/

    function _hashMintVoucher(
        FNVvoucher.mintVoucher memory voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "mintVoucher(uint256 tokenId,uint256 amount,uint96 royaltyFees,address royaltyKeeper,address nftAddress,address nftOwner,string tokenUri)"
                        ),
                        voucher.tokenId,
                        voucher.amount,
                        voucher.royaltyFees,
                        voucher.royaltyKeeper,
                        voucher.nftAddress,
                        voucher.nftOwner,
                        keccak256(bytes(voucher.tokenUri))
                    )
                )
            );
    }

   /**
 * @notice Verifies the lister of a primary listing voucher.
 * @param voucher The primary listing voucher containing the necessary information.
 * @return The address of the lister if the verification is successful.
 * @dev This function is internal and view-only.
 * @dev It calculates the hash of the primary listing voucher using the _hashListVoucher function.
 * @dev It recovers the lister's address from the hash and the signature using ECDSA.
 * @dev This function allows for the verification of the lister's address based on the provided primary listing voucher.
 */

    function verifyLister(
        FNVvoucher.priListing memory voucher
    ) internal view returns (address) {
        bytes32 digest = _hashListVoucher(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
@dev this is an internal function that generates a 32 byte hash of a struct like object 
@param voucher struct like voucher that indicates all the required information of ERC1155 tokens of which the hash is to be generated
*/

    function _hashListVoucher(
        FNVvoucher.priListing memory voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "priListing(uint256 tokenId,uint256 unitprice,uint256 countervalue,uint256 amount,address nftOwner,bool listed,bool isEth)"
                        ),
                        voucher.tokenId,
                        voucher.unitprice,
                        voucher.countervalue,
                        voucher.amount,
                        voucher.nftOwner,
                        voucher.listed,
                        voucher.isEth
                    )
                )
            );
    }

    /**
 * @notice Resets the counter status for a specific primary listing.
 * @param _voucher The primary listing voucher containing the counter value.
 * @dev This function can only be called by the contract owner.
 * @dev It sets the counter status for the specified counter value to 1.
 * @dev This function is used to reset the counter status of a primary listing, allowing it to be listed again.
 */

    function resetCounter(
        FNVvoucher.priListing memory _voucher
    ) external onlyOwner {
        primaryCounterStatus[_voucher.countervalue] = 1;
    }

   /**
 * @notice Sets the platform fees to a new value.
 * @param _newPlatformFees The new platform fees value to be set.
 * @dev This function can only be called by the contract owner.
 * @dev It requires the new platform fees value to be greater than zero.
 * @dev It updates the platform fees with the new value.
 */

    function setPlatformFees(uint256 _newPlatformFees) external onlyOwner {
        //PFCZ--> Platform fees can't be zero
        require(_newPlatformFees > 0, "PFCZ");
        platformFees = _newPlatformFees;
    }

   /**
 * @notice Sets the Fanverse token address for the contract.
 * @dev Only the contract owner can invoke this function.
 * @param _fanvToken The address of the Fanverse token contract to be set.
 * @dev The Fanverse token address cannot be set to the zero address (address(0)).
 */

    function setFanvToken(address _fanvToken) external onlyOwner {
        //FTAZ--> Fanverse token address can't be zero
        require(_fanvToken != address(0), "FTAZ");
        fanversetokenInstance = IERC20(_fanvToken);
    }

/**

@notice Sets the admin address for the contract.
@dev Only the contract owner can invoke this function.
@param _adminAddress The new admin address to be set.
@dev The admin address cannot be set to the zero address (address(0)).
*/
    function setAdminAddress(address _adminAddress) external onlyOwner {
        //AAZ--> Admin address can't be zero
        require(_adminAddress != address(0), "AAZ");
        Admin = _adminAddress;
    }

/**
 * @notice Checks if the contract supports a specific interface.
 * @param interfaceId The interface identifier to check.
 * @return True if the contract supports the interface, false otherwise.
 * @dev This function is public and view.
 * @dev It overrides the supportsInterface function from ERC1155Upgradeable and ERC2981Upgradeable.
 * @dev Calls the supportsInterface function from the parent contracts and returns the result.
 */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

/**
 * @notice Returns the address of the message sender.
 * @return sender The address of the message sender.
 * @dev This function is internal and view.
 * @dev It overrides the _msgSender function from the ContextUpgradeable contract.
 * @dev Calls the _msgSender function from the parent contract and returns the result.
 */
    function _msgSender()
        internal
        view
        override(ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }

/**
 * @notice Retrieves the ID of the current blockchain chain.
 * @return The chain ID as a uint256 value.
 * @dev This function is external and view.
 * @dev It uses assembly code to directly access the chainid opcode.
 * @dev The chain ID is obtained using the chainid() assembly function.
 */
    function getChainID() external view virtual returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }


    /**
 * @notice Executes the primary auction process for the winner.
 * @param seller The auction item seller information.
 * @param buyer The auction item buyer information.
 * @dev This function performs the necessary steps to finalize the auction process for the primary auction winner.
 * @dev It calls the internal function buyAuctionFlow to handle the transaction and distribution of funds.
 * @dev It emits the primaryAuction event with relevant information.
 */
    function primaryAuctionWinner(
        FNVvoucher.auctionItemSeller memory seller,
        FNVvoucher.auctionItemBuyer memory buyer
    ) public payable {
        buyAuctionFlow(seller, buyer);
        emit primaryAuction(
            seller.owner,
            buyer.buyer,
            seller.tokenId,
            buyer.pricePaid
        );
    }

    function buyAuctionFlow(
        FNVvoucher.auctionItemSeller memory seller,
        FNVvoucher.auctionItemBuyer memory buyer
    ) internal {
        //INA-->Invalid NFT Address
        require(seller.nftAddress == address(this), "INA");
        require(seller.nftAddress == buyer.nftAddress, "INA");
        //SBTF--> Seller and buyer token id is diffrent
        require(seller.tokenId == buyer.tokenId, "SBTF");

        require(
            !detailsNFT[seller.tokenId].isNFT &&
                !detailsNFT[seller.tokenId].isTokenId,
            "NFT exists"
        );

        //BSLO--> NFT batch size should be one
        require(seller.nftBatchAmount == 1, "NBSO");
        //Batch size doesn't match
        require(seller.nftBatchAmount == buyer.nftBatchAmount, "BSM");

        address signer = _verifyAucSeller(seller);
        //IS-->Invalid signer
        require(signer == address(seller.owner), "IS");
        address Buyer = _verifyAucBuyer(buyer);
        //IB-->Invalid buyer
        require(Buyer == address(buyer.buyer) && Buyer == msg.sender, "IB");
        //BSS--> buyer and seller are same
        require(Buyer != signer, "BSS");

        _safeMint(
            signer,
            seller.tokenId,
            seller.nftBatchAmount,
            seller.tokenURI,
            address(seller.royaltyKeeper),
            seller.royaltyFees
        );
        _setApprovalForAll(signer, address(buyer.buyer), true);
        
        if (seller.isEth) {
            require(seller.minimumBid <= msg.value, "IBE");
            //MPV--> Mismatch of price paid promised and actually paid
            require(buyer.pricePaid == msg.value, "MPV");
            distributeAmountInEth(signer, msg.value);
        } else {
            //IBFV--> Invalid bid of fanvtoken
            require(seller.minimumBid <= buyer.pricePaid, "IBFV");
            distributeAmountInFanv(signer, buyer.pricePaid);
        }
        safeTransferFrom(
            signer,
            address(buyer.buyer),
            seller.tokenId,
            buyer.nftBatchAmount,
            ""
        );
    }

    /**
 * @notice Verifies the auction item seller's signature.
 * @param voucher The auction item seller information.
 * @return The address recovered from the signature.
 * @dev This function calculates the digest of the auction item seller using the _hashAucSeller internal function.
 * @dev It then recovers the address from the digest using ECDSA.recover function.
 */

    function _verifyAucSeller(
        FNVvoucher.auctionItemSeller memory voucher
    ) internal view returns (address) {
        bytes32 digest = _hashAucSeller(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
@dev this is an internal function that generates a 32 byte hash of a struct like object 
@param voucher struct like voucher that indicates all the required information of ERC1155 tokens of which the hash is to be generated
*/

    function _hashAucSeller(
        FNVvoucher.auctionItemSeller memory voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "auctionItemSeller(uint256 royaltyFees,uint256 tokenId,uint256 nftBatchAmount,uint256 minimumBid,address nftAddress,address owner,address royaltyKeeper,string tokenURI,bool isEth)"
                        ),
                        voucher.royaltyFees,
                        voucher.tokenId,
                        voucher.nftBatchAmount,
                        voucher.minimumBid,
                        voucher.nftAddress,
                        voucher.owner,
                        voucher.royaltyKeeper,
                        keccak256(bytes(voucher.tokenURI)),
                        voucher.isEth
                    )
                )
            );
    }

    /**
 * @notice Verifies the auction item buyer's signature.
 * @param voucher The auction item buyer information.
 * @return The address recovered from the signature.
 * @dev This function calculates the digest of the auction item buyer using the _hashAucBuyer internal function.
 * @dev It then recovers the address from the digest using ECDSA.recover function.
 */

    function _verifyAucBuyer(
        FNVvoucher.auctionItemBuyer memory voucher
    ) internal view returns (address) {
        bytes32 digest = _hashAucBuyer(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    /**
@dev this is an internal function that generates a 32 byte hash of a struct like object 
@param voucher struct like voucher that indicates all the required information of ERC1155 tokens of which the hash is to be generated
*/

    function _hashAucBuyer(
        FNVvoucher.auctionItemBuyer memory voucher
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "auctionItemBuyer(uint256 tokenId,uint256 nftBatchAmount,uint256 pricePaid,address nftAddress,address buyer,string tokenURI)"
                        ),
                        voucher.tokenId,
                        voucher.nftBatchAmount,
                        voucher.pricePaid,
                        voucher.nftAddress,
                        voucher.buyer,
                        keccak256(bytes(voucher.tokenURI))
                    )
                )
            );
    }
}
