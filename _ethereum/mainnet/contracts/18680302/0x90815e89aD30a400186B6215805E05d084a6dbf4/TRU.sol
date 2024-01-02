// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Counters.sol";
import "./PlatformFee.sol";
import "./ContractMetadata.sol";
import "./Ownable.sol";
import "./Auction.sol";

contract TRU is
    Ownable,
    ERC721,
    AuctionContract,
    PlatformFee,
    ContractMetadata
{
    struct nft {
        uint256 id;
        string title;
        string description;
        uint256 price;
        string date;
        string authorName;
        address payable author;
        address payable owner;
        // 1 means token has sale status (or still in selling) and 0 means token is already sold,
        // ownership transferred and moved to off-market gallery
        uint256 status;
        string image;
        string _baseURIextended;
    }

    struct nftTxn {
        uint256 id;
        uint256 price;
        address seller;
        address buyer;
        uint256 txnDate;
        uint256 status;
    }

    uint256 private pendingnftCount; // gets updated during minting(creation), buying and reselling
    mapping(uint256 => nftTxn[]) private nftTxns;
    uint256 public index; // uint256 value; is cheaper than uint256 value = 0;.
    nft[] public nfts;
    mapping(uint256 => string) private _tokenURIs;
    /// @dev The % of primary sales collected as platform fees.
    uint256 public firstOwnerPercentFees = 5; // 10% for the owner


    function _TokenURI(uint256 _optionId) public view returns (string memory) {
        string memory baseURI;
        (, , , , , , , , , , baseURI) = findnft(_optionId);
        return baseURI;
    }

    function get_price(uint256 id) public view returns (uint256) {
        uint256 x;
        (, , , x, , , , , , , ) = findnft(id);
        return x;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _TokenURI(_tokenId);
    }

    event LognftSold(
        uint256 _tokenId,
        string _title,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner,
        address _buyer
    );
    event LognftTokenCreate(
        uint256 _tokenId,
        string _title,
        string _category,
        string _authorName,
        uint256 _price,
        address _author,
        address _current_owner
    );
    event LognftResell(uint256 _tokenId, uint256 _status, uint256 _price);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
        // Initialize the auction contract
        auctionIdCounter = 0;
        _setupPlatformFeeInfo(msg.sender, 250);
    }

    /* Create or minting the token */
    function createToken(
        string memory _title,
        string memory _description,
        string memory _date,
        string memory _authorName,
        uint256 _price,
        string memory _image,
        string memory url
    ) public {
        require(bytes(_title).length > 0, "The title cannot be empty");
        require(bytes(_date).length > 0, "The Date cannot be empty");
        require(
            bytes(_description).length > 0,
            "The description cannot be empty"
        );
        require(_price > 0, "The price cannot be empty");
        require(bytes(_image).length > 0, "The image cannot be empty");

        nft memory _nft = nft({
            id: index,
            title: _title,
            description: _description,
            price: _price,
            date: _date,
            authorName: _authorName,
            author: payable(msg.sender),
            owner: payable(msg.sender),
            status: 1,
            image: _image,
            _baseURIextended: url
        });

        nfts.push(_nft); // push to the array
        uint256 tokenId = nfts.length - 1; // array length -1 to get the token ID = 0, 1,2 ...
        _safeMint(msg.sender, tokenId);

        emit LognftTokenCreate(
            tokenId,
            _title,
            _date,
            _authorName,
            _price,
            msg.sender,
            msg.sender
        );
        index++;
        pendingnftCount++;
    }

    /*
     *   The buynft() function verifies whether the buyer has enough balance to purchase the nft.
     *   The function also checks whether the seller and buyer both have a valid account address.
     *   The token owner's address is not the same as the buyer's address. The seller is the owner
     *   of the nft. Once all of the conditions have been verified, it will stnft the payment and
     *   nft token transfer process. _transfer transfers an nft token from the seller to the buyer's
     *   address. _current_owner.transfer will transfer the buyer's payment amount to the nft owner's
     *   account. If the seller pays extra Ether to buy the nft, that ether will be refunded to the
     *   buyer's account. Finally, the buynft() function will update nft ownership information in
     *   the blockchain. The status will change to 0, also known as the sold status. The function
     *   implementations keep records of the nft transaction in the nftTxn array.
     */
    function buynft(uint256 _tokenId) public payable {
        (
            uint256 _id,
            string memory _title,
            ,
            uint256 _price,
            uint256 _status,
            ,
            string memory _authorName,
            address payable _author,
            address payable _current_owner,
            ,

        ) = findnft(_tokenId);

        // Ensure _current_owner address is valid and not the zero address
        require(_current_owner != address(0), "Invalid _current_owner address");
        // Ensure the sender's address is valid and not the zero address
        require(msg.sender != address(0), "Invalid sender address");
        // Ensure the sender is not the current owner to prevent unauthorized transfers
        require(
            msg.sender != _current_owner,
            "Sender cannot be the current owner"
        );
        // Ensure the value sent with the transaction is greater than or equal to the specified _price
        require(msg.value >= _price, "Insufficient payment amount");
        // Ensure the owner of the NFT with the given _tokenId is a valid address and not the zero address
        require(
            nfts[_tokenId].owner != address(0),
            "Invalid NFT owner address"
        );
        // Ensure the NFT with the given _tokenId is available for sale (status == 1)
        require(nfts[_tokenId].status == 1, "NFT is not available for sale");

        _safeTransfer(_current_owner, msg.sender, _tokenId, ""); // transfer ownership of the nft
        //return extra payment
        if (msg.value > _price)
            payable(msg.sender).transfer(msg.value - _price);
        // make a payment to the platformFeeRecipient
        (
            address platformFeeRecipient,
            uint16 platformFeeBps
        ) = getPlatformFeeInfo();
        uint256 contractOwnerAmount = (_price * platformFeeBps) / 10000;
        uint256 _firstOwnerAmount = (_price * firstOwnerPercentFees) / 100;
        uint256 _currentOwnerAmount = (_price - contractOwnerAmount - _firstOwnerAmount);
        address payable contractOwner = payable(platformFeeRecipient);
        contractOwner.transfer(contractOwnerAmount);
        //make a payment to the current owner
        _current_owner.transfer(_currentOwnerAmount);
        _author.transfer(_firstOwnerAmount);

        nfts[_tokenId].owner = payable(msg.sender);
        nfts[_tokenId].status = 0;

        nftTxn memory _nftTxn = nftTxn({
            id: _id,
            price: _price,
            seller: _current_owner,
            buyer: msg.sender,
            txnDate: block.timestamp,
            status: _status
        });

        nftTxns[_id].push(_nftTxn);
        pendingnftCount--;
        emit LognftSold(
            _tokenId,
            _title,
            _authorName,
            _price,
            _author,
            _current_owner,
            msg.sender
        );
    }

    /* Pass the token ID and get the nft Information */
    function findnft(uint256 _tokenId)
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            uint256,
            uint256 status,
            string memory,
            string memory,
            address payable,
            address payable,
            string memory,
            string memory
        )
    {
        nft memory myNft = nfts[_tokenId];
        return (
            myNft.id,
            myNft.title,
            myNft.description,
            myNft.price,
            myNft.status,
            myNft.date,
            myNft.authorName,
            myNft.author,
            myNft.owner,
            myNft.image,
            myNft._baseURIextended
        );
    }

    /*
     * The resellnft() function verifies whether the sender's address is valid and makes sure
     * that only the current nft owner is allowed to resell the nft. Then, the resellnft()
     * function updates the nft status from 0 to 1 and moves to the sale state. It also updates
     * the nft's selling price and increases the count of the current total pending nfts. emit
     * LognftResell() is used to add a log to the blockchain for the nft's status and price
     * changes.
     */
    function resellnft(uint256 _tokenId, uint256 _price) public {
        // Ensure the sender's address is valid and not the zero address
        require(msg.sender != address(0), "Invalid sender address");
        // Ensure the sender is the owner of the NFT with the given _tokenId
        require(
            isOwnerOf(_tokenId, msg.sender),
            "Sender is not the owner of the NFT"
        );

        nfts[_tokenId].owner = payable(ownerOf(_tokenId));
        nfts[_tokenId].status = 1;
        nfts[_tokenId].price = _price;
        pendingnftCount++;
        emit LognftResell(_tokenId, 1, _price);
    }

    function cancel_resellnft(uint256 _tokenId) public {
        require(msg.sender != address(0));
        require(isOwnerOf(_tokenId, msg.sender));
        nfts[_tokenId].status = 0;
        pendingnftCount--;
    }

    /* returns all the pending nfts (status =1) back to the user */
    function findAllPendingnft()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        if (pendingnftCount == 0) {
            return (
                new uint256[](0),
                new address[](0),
                new address[](0),
                new uint256[](0)
            );
        }

        uint256 arrLength = nfts.length;
        uint256[] memory ids = new uint256[](pendingnftCount);
        address[] memory authors = new address[](pendingnftCount);
        address[] memory owners = new address[](pendingnftCount);
        uint256[] memory status = new uint256[](pendingnftCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < arrLength; ++i) {
            nft memory myNft = nfts[i];
            if (myNft.status == 1) {
                ids[idx] = myNft.id;
                authors[idx] = myNft.author;
                owners[idx] = myNft.owner;
                status[idx] = myNft.status;
                idx++;
            }
        }

        return (ids, authors, owners, status);
    }

    /* Return the token ID's that belong to the caller */
    function findMynfts()
        public
        view
        returns (uint256[] memory _mynfts, uint256 tokens)
    {
        require(msg.sender != address(0));
        uint256 numOftokens = balanceOf(msg.sender);
        if (numOftokens == 0) {
            return (new uint256[](0), 0);
        } else {
            uint256[] memory mynfts = new uint256[](numOftokens);
            uint256 idx = 0;
            uint256 arrLength = nfts.length;
            for (uint256 i = 0; i < arrLength; i++) {
                if (ownerOf(i) == msg.sender) {
                    mynfts[idx] = i;
                    idx++;
                }
            }
            return (mynfts, numOftokens);
        }
    }

    /* return true if the address is the owner of the token or else false */
    function isOwnerOf(uint256 tokenId, address account)
        public
        view
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        require(owner != address(0));
        if (owner == account) {
            return true;
        } else {
            return false;
        }
    }

    function get_symbol() external view returns (string memory) {
        return symbol();
    }

    function get_name() external view returns (string memory) {
        return name();
    }

    function withdraw() public payable onlyOwner {
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os, "withdraw failed");
        // =============================================================================
    }

    // Bidding
    function createAuction(uint256 _tokenId, uint256 _startPrice)
        public
        override
    {
        require(
            ownerOf(_tokenId) == msg.sender,
            "Only the owner can create an auction"
        );
        require(_startPrice > 0, "The start price must be greater than zero");

        Auction storage newAuction = auctions[auctionIdCounter];
        newAuction.auctionId = auctionIdCounter;
        newAuction.tokenId = _tokenId;
        newAuction.startPrice = _startPrice;
        newAuction.endTimestamp = block.timestamp + auctionDuration;
        newAuction.highestBidder = payable(address(0));
        newAuction.highestBid = 0;
        newAuction.ended = false;

        emit AuctionStarted(
            newAuction.auctionId,
            newAuction.tokenId,
            newAuction.startPrice,
            newAuction.endTimestamp
        );

        auctionIdCounter++;
    }

    function placeBid(uint256 _auctionId) public payable override {
        Auction storage auction = auctions[_auctionId];
        require(auction.endTimestamp > block.timestamp, "Auction has ended");
        require(
            msg.value > auction.highestBid,
            "Bid amount must be higher than current highest bid"
        );

        if (auction.highestBidder != address(0)) {
            // Return the previous highest bid amount to the previous highest bidder
            auction.highestBidder.transfer(auction.highestBid);
        }

        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;

        emit AuctionEnded(
            auction.auctionId,
            auction.tokenId,
            auction.highestBid
        );
    }

    function endAuction(uint256 _auctionId) public override {
        Auction storage auction = auctions[_auctionId];
        require(
            ownerOf(auction.tokenId) == msg.sender,
            "Only the owner can end the auction"
        );
        require(!auction.ended, "Auction has already ended");
        require(
            auction.endTimestamp <= block.timestamp,
            "Auction has not yet ended"
        );

        address payable tokenOwner = payable(ownerOf(auction.tokenId));
        address payable contractOwner = payable(owner());

        // Calculate the amount to be sent to the contract owner
        uint256 contractOwnerAmount = (auction.highestBid * ownerPercentFees) /
            100;
        uint256 tokenOwnerAmount = (auction.highestBid - contractOwnerAmount);

        // Transfer the highest bid amount to the owner
        if (tokenOwnerAmount > 0) tokenOwner.transfer(tokenOwnerAmount);
        // Transfer the percentage bid amount to the contract owner
        if (contractOwnerAmount > 0)
            contractOwner.transfer(contractOwnerAmount);

        // Transfer the token to the highest bidder
        safeTransferFrom(tokenOwner, auction.highestBidder, auction.tokenId);

        auction.ended = true;

        emit AuctionEnded(
            auction.auctionId,
            auction.tokenId,
            auction.highestBid
        );
    }

    function setAuctionDuration(uint256 duration) external onlyOwner {
        auctionDuration = duration;
    }

    function getAuctionDuration() external view returns (uint256) {
        return auctionDuration;
    }

    function setOwnerPercentFees(uint256 _ownerPercentFees) external onlyOwner {
        ownerPercentFees = _ownerPercentFees;
    }

    function getOwnerPercentFees() external view returns (uint256) {
        return ownerPercentFees;
    }

    function setFirstOwnerPercentFees(uint256 _firstOwnerPercentFees) external onlyOwner {
        firstOwnerPercentFees = _firstOwnerPercentFees;
    }

    function getFirstOwnerPercentFees() external view returns (uint256) {
        return firstOwnerPercentFees;
    }

    /**
     *  This function returns who is authorized to set platform fee info for your contract.
     *
     *  As an EXAMPLE, we'll only allow the contract deployer to set the platform fee info.
     *
     *  You MUST complete the body of this function to use the `PlatformFee` extension.
     */
    function _canSetPlatformFeeInfo()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }

    /**
     *  This function returns who is authorized to set the metadata for your metadata.
     *
     *  As an EXAMPLE, we'll only allow the contract deployer to set the contract's metadata.
     *
     *  You MUST complete the body of this function to use the `ContractMetadata` extension.
     */
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }
}
