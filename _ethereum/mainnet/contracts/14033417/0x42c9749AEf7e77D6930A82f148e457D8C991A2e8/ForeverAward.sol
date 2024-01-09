//SPDX-License-Identifier: MIT
pragma solidity 0.6.6;


import "ERC721.sol";
import "Ownable.sol";

/**
 * @dev ForeverAward is an NFT that represents senders sending awards that are forever to a recipient
 * ERC721 - defines that NFT, AND Ownable allows the contract to have an owner (contract creator) and allow it to collect a fee for transfer into another wallet
 */
contract ForeverAward is ERC721, Ownable {

    using Strings for uint256;


    /*
     * @dev keep track of all the tokensMinted 
     */
    uint256 public tokensMinted;
    /*
     * @dev the price to mint is $5 US dollars at the time
     */
    uint256 public PRICE = 0.0016 ether;

    /*
     * @dev keep track of who owns what token
     */
    mapping(address => uint256) public senderToTokenId;
    mapping(uint256 => address) public tokenIdToSender;


    /**
     * @dev "log" that we have minted an Award
     */
    event mintAward(uint256 indexed requestId); 

    /**
     * @dev when deploying the contract pass int the tickerDescription and Symbol and initalize that token to 0
     */
    constructor(
            string memory _tickerDescription,
            string memory _tickerSymbol
            )
        public
        ERC721(_tickerDescription, _tickerSymbol)
        {
            tokensMinted = 0;

        }

    /**
     * @dev - createAward by passing in the tokenURI and the amount of awards we want to mint, here we charge the wallet a price to do this
     */
    function createAward(string memory _tokenURI, uint256 _mintAmount)
        public payable returns (uint64)
        {

            require(_mintAmount > 0, "Amount must be greater than 0");
            require(PRICE * _mintAmount <= msg.value, "Insufficient funds");        

            for (uint256 i = 0; i < _mintAmount; i++) {
                tokensMinted = tokensMinted + 1;
                tokenIdToSender[tokensMinted] = msg.sender;
                senderToTokenId[msg.sender] = tokensMinted;
                _safeMint(msg.sender, tokensMinted);
                setTokenURI(tokensMinted, _tokenURI);

                emit  mintAward(tokensMinted);
            }

        }

    /**
     * @dev after the media is uploaded to IPFS, set the token with the correct location of the meta data and change allow that meta data to change
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
               );
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev this is an administration function that allows the contract creator to set the price
     */
    function setCost(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    /**
     * @dev this is an administration function that allows the contract owner to withdraw the contracts balance to an address
     */
    function withdrawToAddress(address payable recipient) public onlyOwner {
        require(address(this).balance > 0, "No contract balance");
        recipient.transfer(address(this).balance);
    }

    /**
     * @dev this is an adminstration function that allows the contract owner to withdraw the contracts balance to their wallet
     */
    function ownerWithdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


}
