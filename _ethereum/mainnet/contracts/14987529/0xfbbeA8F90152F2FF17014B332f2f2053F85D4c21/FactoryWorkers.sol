// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

/*

                                                             á▓▀╟▓▓▌                                
                                                             ▓▒░╟▓▓▓                                
                                                  ,╓@▓▓      ▓░░╟▓▓▓                                
                                                ]▓╩░▓▓▓     ]▓░░╟▓▓▓                                
                                         ,,     ║▌░░▓▓▓⌐    ▐▓░░╟▓▓▓▒                               
                                     ╓#▓▓▓▓     ╣▒░░▓▓▓▌    ║▌░░╟▓▓▓▌                               
                                    ▐▓░░╫▓▓     ▓░░░▓▓▓▌    ╟▌░░╟▓▓▓▓                               
                             ╓#▓    ▐▌░░╫▓▓    ]▓░░░▓▓▓▓    ╣▒░░╟▓▓▓▓                               
                          @▓╩╟▓▓    ║▌░░╫▓▓⌐   ▐▌░░░▓▓▓▓    ▓▒░░╟▓▓▓▓                               
                          ▓░░╟▓▓L   ╫▒░░╫▓▓▒   ╟▒░░░▓▓▓▓▒   ▓░░░╟▓▓▓▓L                              
                          ▓░░╟▓▓▌   ▓▒░░╫▓▓▌   ▓▒░░░▓▓▓▓▌  ]▓░░░╟▓▓▓▓▌                              
                         ]▓░░╟▓▓▌   ▓░░░╫▓▓▓╓▄╗▓▓▓▀▀╩╙╚╟▓▓▓▓▓▄▒░╟▓▓▓▓▌                              
                         ▐▌░▒╟▓▓▓╗#▒╣▀▀▀╙╙╙░│░░░░░░░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓                              
                     .@▒▓▀▀╚╚╚╚│░░░░░░░░░░░░░░░░░░░░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╗╖,                         
                     ║▌░░░░░░░░░░░░░░░░░░░░░▄▄▓▓▓▒░░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄                     
                     ║▌░░░░▒▄▄▄▄░░░╣▓▓▓▓▓▒░╫▓▓▓▓▓▓▒░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░▓▓▓▓▓▓▒░╟▓▓▓▓▓▓▒░╫▓▓▓╝▓▓▌░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░▓▓▀▀▀▓▌░╟▓▌   ▓▒░╫▓▒   ▓▌░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░▓▓   ╫▌░╟▓▒   ▓▒░╫▓L   ▓▌░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░▓▓   ╫▌░╟▓▒   ▓▒░╫▓▌,,╓▓▒░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░╫▓▓▓▓▓▒░░╫▓▓▓╣╩░░░╚▀▀▀╬▒░░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░░░│░░░░░░░░░░░░░░░░░░░░░░░░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░░╣▓#╣╣╝▓╝╝╝╝╝▓╝╝▀▀▀▓▀▀▀▀▀▓▒░░░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌░░▓▓⌐    ╣     ╣     ╣     ╣╩▓▒░║▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ║▌╔▓ ╫⌐    ╣     ╣     ╣     ╣  ╚▓╟▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                     ╚▓▓▄╓╣▄╓╓╓╓▓▄╓╓╓╓▓▄╓╓╓╓▓▄╓╓╓╓▓▄╓╓╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                     
                                                                                       

             
         ▄, ▄    ▄▄▄▄    ╓▄▄▄┐        ▄▄▄▄,   ╓▄▄▄▄   ╓▄▄▄▄   .▄▄▄▄    ▄▄▄▄    ▄▄▄▄    ▄┐ ▄         
         ██▄█⌐   █▌└└    └╙█╨└        █▌└└`   ╟█└██   ╟█└└└    └█▌└    █▌╙█⌐   █▌└█▌   █▌ █▌        
         ████⌐   ██▀      j█⌐         ██▀     ╟█▀██   ╟█        █▌     █⌐j█⌐   ███▀    ▀▀█▀▀        
         █▌╙█⌐   █▌       j█⌐         █▌      ╟█ ╫█   ╟████     █▌     ████⌐   █▌╙█µ    ▐█          
                                                                                                                                                                                                       
*/

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./ShuffledIds.sol";


contract FactoryWorkers is Ownable,ERC721,ERC721Enumerable {

    uint256 constant MAX_MINT_AMOUNT = 10;

    string constant DESCRIPTION = "ewogICAgIm5hbWUiOiJGYWN0b3J5V29ya2VycyIsCiAgICAiZGVzY3JpcHRpb24iOiJPdXIgV29ya2VycyBhcmUgdGhlIHJlYWwgYnVpbGRpbmcgYmxvY2tzIG9mIHRoZSBGYWN0b3J5OiBwYXNzaW9uLCBleHBlcnRpc2UgYW5kIGRlZGljYXRpb24gYXJlIHRocmVlIGtleSBlbGVtZW50cyBvZiB0aGVpciB3b3JrLCB3aGljaCBpcyBjbGVhcmx5IHJlZmxlY3RlZCBvbiB0aGUgcXVhbGl0eSBvZiBvdXIgcHJvZHVjdHMuIEF0IGEgZmlyc3QgZ2xhbmNlIHRoZWlyIHJvYm90aWMgYm9keSBjYW4gbWFrZSB0aGVtIGxvb2sganVzdCBsaWtlIGNvbGQgbWFjaGluZXM7IGhvd2V2ZXIsIHRoZWlyIGNvbW1pdG1lbnQgdG8gdGhlIGpvYiBzb21ldGltZXMgYWxtb3N0IG1ha2VzIHVzIHF1ZXN0aW9uaW5nIHRoZWlyIG5vbi1odW1hbiBuYXR1cmUsIGFzIGlmIGEgdHJ1ZSBoZWFydCB3ZXJlIGJlYXRpbmcgdW5kZXIgdGhlaXIgaXJvbiBjaGVzdC4uLiBGYWN0b3J5V29ya2VycyBpcyBhIGNvbGxlY3Rpb24gb2YgMjAwMCBORlRzIGxpdmluZyBvbiB0aGUgRXRoZXJldW0gYmxvY2tjaGFpbiwgd2hpY2ggd2lsbCBiZSByZWxlYXNlZCBpbiAxMCBkaXN0aW5jdCByb3VuZHMgb2YgMjAwIHVuaXRzIGVhY2guIEluIGVhY2ggcm91bmQgYSBmaXhlZCBudW1iZXIgb2YgZ29sZGVuIHRva2VucyB3aWxsIGJlIG1pbnRlZCwgdXAgdG8gYSB0b3RhbCBudW1iZXIgb2YgMzMgR29sZGVuIFdvcmtlcnMuIEVhY2ggdG9rZW4gZ3JhbnRzIHRvdGFsIGVuZ2FnZW1lbnQgYW5kIHNldmVyYWwgYmVuZWZpdHMgYW1vbmcgdGhlIE5GVCBGYWN0b3J5IGNvbW11bml0eS4gQnkgb3duaW5nIGEgRmFjdG9yeVdvcmtlciwgeW91IGNob29zZSB0byBzdXBwb3J0IG91ciBGYWN0b3J5IGdpdmluZyB1cyB0aGUgcG9zc2liaWxpdHkgdG8gZ3JvdyBhbmQgcmVsZWFzZSBhbGwgdGhlIGFtYXppbmcgTkZUIGdhbWluZyBwcm9qZWN0cyB3ZSBhbHJlYWR5IGhhdmUgaW4gbWluZC4gVGhhbmtzIGZvciB5b3VyIGhlbHAhIiwgCiAgICAiZXh0ZXJuYWxfbGluayI6ICJodHRwczovL3d3dy5uZnQtZmFjdG9yeS5jbHViL2ZhY3Rvcnktd29ya2VycyIsIAogICAgImltYWdlIjoiaXBmczovL1FtYkxUU1dRRG9nYVpIVkxGRjgzaWM5ZEJLRWk5TDdwTmhIc1ExUVNGRzRXaEIiCn0=";

    struct Discount {
        bool exist;
        uint256 price;
    }

    mapping(address => Discount) public discounts;
    using ShuffledIds for ShuffledIds.Shuffler;
    mapping(uint256 => ShuffledIds.Shuffler) public rounds;

    uint256 maxRound;
    uint256 public currentRound;
    uint256 roundSize;
    string metadataURI;
    uint public price;

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(string memory name_,string memory symbol_,string memory metadataURI_) ERC721(name_,symbol_){
        metadataURI = metadataURI_;

        price = 0;
        maxRound = 10;
        currentRound = 1;
        roundSize = 200;

        for(uint i=1; i<=maxRound; i++){          
            rounds[i].initialize(roundSize*(i-1)+1,roundSize*i);
        }
    }

    /**
     * @dev Set minting price
     * @param price_ new price
     */
    function setPrice(uint price_) public onlyOwner {
        price = price_;
    }

    /**
     * @dev Start new round
     */
    function increaseRound() public onlyOwner {
        require(rounds[currentRound].remaining == 0, "FactoryWorkers: Round not ended");
        require(currentRound < maxRound, "FactoryWorkers: Last round reached");
        currentRound++;
    }

    /**
     * @dev Get contract baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @dev Get metadata uri of a specific token
     * @param tokenId id of the token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,metadataURI,"/", Strings.toString(tokenId),".json")) : "";
    }

        /**
     * @dev Get metadata of the contract
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,",DESCRIPTION));
    }

    /**
     * @dev Mint new tokens and transfer funds to contract owner
     * @param amount amount to mint
     * @param selectedPrice selected minting price
     */
    function _mintAndPay(uint256 amount,uint256 selectedPrice) private {
        require(amount <= MAX_MINT_AMOUNT, "FactoryWorkers: Supplied amount is greater than max mintable amount");
        require(rounds[currentRound].remaining > 0, "FactoryWorkers: Round cap reached");   
        require(rounds[currentRound].remaining >= amount, "FactoryWorkers: Supplied amount exceeds round cap");
        if(msg.sender != owner()){
            require(msg.value >= selectedPrice*amount,"FactoryWorkers: Not enough funds supplied");
        }

        for(uint i=0; i<amount; i++){
            uint256 newId = rounds[currentRound].popRandomId();
            _safeMint(msg.sender,newId,"");
            if(msg.sender != owner()){
                if(i == amount - 1){
                    payable(owner()).transfer(msg.value - selectedPrice*(amount-1));
                } else {
                    payable(owner()).transfer(selectedPrice);
                } 
            }
            emit PermanentURI(tokenURI(newId),newId);
        }
    }

    /**
     * @dev Mint new tokens
     * @param amount amount to mint
     */
    function mint(uint256 amount) public payable {
        _mintAndPay(amount,price);
    }

    /**
     * @dev Mint new tokens with a discounted price (only for holders of approved collections)
     * @param amount amount to mint
     * @param collectionAddress NFT collection which shoud grant the discount
     */
    function mintWithDiscount(uint256 amount,address collectionAddress) public payable {
        require(discounts[collectionAddress].exist == true, "FactoryWorkers: Discount not active for this collection");
        ERC721 collection = ERC721(collectionAddress);
        uint256 balance = collection.balanceOf(msg.sender);
        require(balance > 0, "FactoryWorkers: Sender is not an holder of the supplied collection");
        
        uint256 discountedPrice = discounts[collectionAddress].price;
        
        _mintAndPay(amount,discountedPrice);
    }
    
    /**
     * @dev Grant discounted minting price to the holders of the supplied collection
     * @param collectionAddress NFT collection
     * @param discountedPrice discounted price
     */
    function addDiscount(address collectionAddress,uint256 discountedPrice) public onlyOwner {
        discounts[collectionAddress] = Discount(true, discountedPrice);
    }

    /**
     * @dev Remove discounted minting price for the holders of the supplied collection
     * @param collectionAddress NFT collection
     */
    function removeDiscount(address collectionAddress) public onlyOwner {
        discounts[collectionAddress] = Discount(false, 0);
    }

    /**
     * Solidity required overrides
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }


}