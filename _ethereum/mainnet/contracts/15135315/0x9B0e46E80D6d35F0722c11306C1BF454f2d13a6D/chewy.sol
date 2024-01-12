// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Royalty.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./EIP712Whitelist.sol";


contract CHEWYHK is ERC721, ERC721Enumerable, Ownable,  ERC721Burnable, ERC721Royalty, EIP712Whitelist, PaymentSplitter{
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant PRICE = 2 ether; 
    uint256 public constant MAX_SUPPLY = 100;   
    uint256 private constant MAX_PER_MINT = 20;
    uint96 private constant SELLER_FEE = 1000; //10%
    uint256 private constant REDEEM_STARTAT = 1672531200; //Jan 01 2023
    string private baseURI_ = "ipfs://Qmad1jMvG1vHo9QoNcrAmFX5ZyoidL8Srk7vixAH9w8aNH/";

    address[] private _payees = [
        0x56d6a4Fd7241b0F3Cd252f02Ba7096F5b09bc305,
        0xFE6E729eC5a4587991217E4A23CBB8b3410A42c1,
        0x989ede9bBF387dC2f68A2F05f42D7a0E95Af04C4
    ];

    uint256[] private _shares = [205,205,590];
    
    Counters.Counter private _tokenIdCounter;
    bool public onSale = true; 
    uint256[] private _redeemed;
    mapping(uint256 => address) public redeemedBy;

    event Redeem(address redeemedBy, uint256 tokenId);

    constructor() ERC721("CHEWYHK", "CHEWYHK") PaymentSplitter(_payees, _shares ) {
        _setDefaultRoyalty(address(this), SELLER_FEE);
    }

    /**
        @notice get the total supply including burned token
    */
    function tokenIdCurrent() external view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
        @notice air drop tokens to recievers
        @param recievers each account will receive one token
    */
    function airDrop(address[] calldata recievers) external onlyOwner {
        require(recievers.length <= MAX_PER_MINT, "High Quntity");
        require(_tokenIdCounter.current() + recievers.length <= MAX_SUPPLY,  "Out of Stock");

        for (uint256 i = 0; i < recievers.length; i++) {
            _safeMint(recievers[i]);
        }
    }

    /**
        @notice  mint with valid signature 
        @param tokenQuantity number of token to be minted
        @param signature signature of typed data TicketSigner
    */
    function privateMint(uint256 tokenQuantity, bytes calldata signature) external payable{
        require(onSale, "Private Sale Not Allowed");
        require(tokenQuantity <= MAX_PER_MINT, "High Quntity");
        require(tokenQuantity > 0, "Mint At Least One");
        require(_tokenIdCounter.current() + tokenQuantity <= MAX_SUPPLY,  "Out of Stock");
        require(PRICE * tokenQuantity <= msg.value,  "INSUFFICIENT_ETH");
        require(simpleVerify(signature), "Invalid Signature");

        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender);
        }
    }
    
    /**
        @notice enable/disable privateMint 
    */
    function toggleSaleStatus() external onlyOwner {
        onSale = !onSale;
    }

    function redeem(uint256 tokenId) external {
        require(block.timestamp > REDEEM_STARTAT, "Redemption has not started");
        require(ownerOf(tokenId) == msg.sender, "Unauthorized");
        burn(tokenId);
        _redeemed.push(tokenId);
        redeemedBy[tokenId] = msg.sender;
        emit Redeem(msg.sender, tokenId);
    }

    /**
        @notice  get number of redeemed token 
    */
    function totalRedemption() public view returns(uint256){
        return _redeemed.length;
    }

    /**
        @notice  get the tokenId by the  redeemed index
        @param index redeemed index
    */
    function tokenOfRedemptionByIndex(uint256 index) external view returns(uint256){
        require(index<totalRedemption(), "global index out of bounds");
        return _redeemed[index];
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), ".json")) : "";
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721Royalty){
        super._burn(tokenId);
    }
}
