// SPDX-License-Identifier: GPL-3.0-or-later
/*
     ___          ___          ___          ___          ___          ___          ___          ___     
    /  /\        /  /\        /  /\        /  /\        /  /\        /  /\        /  /\        /  /\    
   /  /::|      /  /::\      /  /::\      /  /:/_      /  /::\      /  /::\      /  /::\      /  /::\   
  /  /:|:|     /  /:/\:\    /  /:/\:\    /  /:/ /\    /__/:/\:\    /  /:/\:\    /  /:/\:\    /  /:/\:\  
 /  /:/|:|__  /  /::\ \:\  /  /:/  \:\  /  /:/ /:/_  _\_ \:\ \:\  /  /:/  \:\  /  /::\ \:\  /  /:/  \:\ 
/__/:/_|::::\/__/:/\:\ \:\/__/:/ \__\:\/__/:/ /:/ /\/__/\ \:\ \:\/__/:/ \__\:|/__/:/\:\_\:\/__/:/ \__\:\
\__\/  /~~/:/\  \:\ \:\_\/\  \:\ /  /:/\  \:\/:/ /:/\  \:\ \:\_\/\  \:\ /  /:/\__\/  \:\/:/\  \:\ /  /:/
      /  /:/  \  \:\ \:\   \  \:\  /:/  \  \::/ /:/  \  \:\_\:\   \  \:\  /:/      \__\::/  \  \:\  /:/ 
     /  /:/    \  \:\_\/    \  \:\/:/    \  \:\/:/    \  \:\/:/    \  \:\/:/       /  /:/    \  \:\/:/  
    /__/:/      \  \:\       \  \::/      \  \::/      \  \::/      \__\::/       /__/:/      \  \::/   
    \__\/        \__\/        \__\/        \__\/        \__\/           ~~        \__\/        \__\/    

    🐱 Meows(DAO) (0x971B4533EdBFcfE34e0F6eA053D33231a814FD96) Genesis Collection, (c) 2021 🐦 @MeowsDAO, m@meowsdao.xyz 
    Author: @atsignhandle, m@atsignhandle.wtf
    Usage: Call 🐱 adoptKittyCats(numberOfCats) to adopt a numberOfCats.
        * MAX_TOTAL_KITTIES is 25 per account
        * PER_KITTY_PRICE is 0.05 ETH
        * must have (numberOfCats < MAX_TOTAL_KITTIES) * (PER_KITTY_PRICE)      

    TWITTER                 @meowsdao
    ILLUSTRATOR             n@meowsdao.xyz

    The Whiskers' Progeny collection consists of 11,111 (eleven thousand, one hundred, and eleven) 
    pieces, each is a combination of 416 (four-hundred and sixteen)* hand-drawn cat traits, putting 
    the possibilities into the billions. Additionally.17 (seventeen) impossible double-extra-special 
    Whiskers' Progeny sets are buried within the litter. *NFTS were a combination of 708 total 
    traits if you include the backgrounds and t-shirt patterns.
    
    BASE_URI                ipfs://QmRQ9mB8UDRd3adMndj5NGTD9ajbJYuSQkbdm5mVQFWVxN
    PROVENANCE              ipfs://bafybeib2pinjbuwpd5i5n3t6jwgdza5efvai5efrdzmqfvzcj5mpudxrhm
    CONTACT_SHEET_XL_00     ipfs://bafybeicatuytiyhposisgjuxe6z5s47jk5ktjzkdfblt6ajiwva2jmjmwi
    CONTACT_SHEET_XL_01     ipfs://bafybeibyzva3r2ficeya4qqmghwxl2veorepujzb36mqyxl3oheq52wfbe
    CONTACT_SHEET_SM_00     ipfs://bafybeiajon7f4micuwps2gws5opowx5xblfbl4snt6d64qlamynmscdaf4
    CONTACT_SHEET_SM_01     ipfs://bafybeihucsvshysbj75khvfk3uuxoqxjo4oqml7iqf7iayiissjj7dd3pq
    VIDEO                   ipfs://bafybeibm6fmqz2apsu65rdvke7sltf7jy7h2ougw5x5w4xbryogu6ijiy4
    PROFILE_PICTURE         ipfs://bafybeied742ajkn7srlonupkyp275kf37oti6ibmsxhuky3ixt5hlpbmne    
    OPENSEA_CONTRACT_URI    ipfs://bafkreigugk6gwcbwb25zvh7ekvunrduuiiuy2xle5ynmepfwcdja3lftbq    
    UPSIDE_DOWN             ipfs.//bafybeif63rtqvm2moorx6y63tbqp2vdyrqt6fjmbmhmtxkiyqnhd4ukjnm
    DIAMOND_HANDS           ipfs://bafkreid7crecple7cyvpknkmyxx7b625iqrlnthu66c533ebdl6xyaxw7q
    EXAMPLE_ALP_SET         ipfs://bafybeib7eulvibbvpxjqsixb45vrywf3qezrnuj4glol2ywu44wx5bg6pe
    EXAMPLE_SPACE_SET       ipfs://bafybeicpj5lkchb2iv3yql4jba7ah3vexb3537psvgpxord3xqerodcplq
    EXAMPLE_SEAWORLD_SET    ipfs://bafybeidsutyzoxt2mvnoj4yg6e2ju5uzziycgfs3izcqlcj3qekusforq4
    TRAITS_CSV              ipfs://QmaB6q8EBWnw16MPLAXdtw3ETrp7JY5FXxCESrUo5178g7
    RARITY_CSV              ipfs://QmeWFuRHPXK19a6NeGzfx2r8rxnW18w4UpcAWmVDubZajq
*/
pragma solidity ^0.7.0;

import "./console.sol";
import "./Ownable.sol";
import "./ERC721.sol";

/**
 * @title Meows(DAO)'s Genesis Collection
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MeowsDAO is ERC721, Ownable {
    using SafeMath for uint256;

    bool public saleIsActive = false;
    string public PROVENANCE =
        "60fb632188bea0da4b0596e6a697e11fe62c68e37bcc46f378fee5bcfaaa5e85";
    string public OPENSEA_STORE_METADATA =
        "ipfs://bafkreigugk6gwcbwb25zvh7ekvunrduuiiuy2xle5ynmepfwcdja3lftbq";

    uint256 public constant PER_KITTY_PRICE = 50000000000000000;
    uint256 public constant MAX_KITTY_ALLOWANCE = 25;

    uint256 public MAX_TOTAL_KITTIES;
    uint256 public REVEAL_TIMESTAMP;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxNftSupply,
        uint256 saleStart
    ) ERC721(name, symbol) {
        MAX_TOTAL_KITTIES = maxNftSupply;
        REVEAL_TIMESTAMP = saleStart + (86400 * 5);
    }

    /**
     *  @dev Pay the electricity bill
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     *  @dev Set aside a portion of the total supply for the team
     */
    function reserveKittyCats() public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < 25; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setRevealTimestamp(uint256 revealTimeStamp) public onlyOwner {
        REVEAL_TIMESTAMP = revealTimeStamp;
    }

    /**
     *  @dev Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(
            bytes(PROVENANCE).length == 0,
            "Provenance has already been set, no do-overs!"
        );
        PROVENANCE = provenanceHash;
    }

    /**
     *  @dev Set metadata to make OpenSea happy
     */
    function setContractURI(string memory _contractMetadataURI)
        public
        onlyOwner
    {
        OPENSEA_STORE_METADATA = _contractMetadataURI;
    }

    /**
     *  @dev Get contract metadata to make OpenSea happy
     */
    function contractURI() public view returns (string memory) {
        return OPENSEA_STORE_METADATA;
    }

    /**
     *  @dev Set the IPFS baseURI, including ending `/` where JSON is located
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    /**
     *  @dev Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     *  @dev Adopt new kitty cats
     */
    function adoptKittyCats(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Mr. Whiskers");
        require(
            numberOfTokens <= MAX_KITTY_ALLOWANCE,
            "Can only mint 25 tokens at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= MAX_TOTAL_KITTIES,
            "Purchase would exceed max supply of Mr. Whiskers"
        );
        require(
            PER_KITTY_PRICE.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_TOTAL_KITTIES) {
                _safeMint(msg.sender, mintIndex);
            }
        }

        /*
            If we haven't set the starting index and this is either 
                1) the last saleable token or 
                2) the first token to be sold after
            the end of pre-sale, set the starting index block
        */
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == MAX_TOTAL_KITTIES ||
                block.timestamp >= REVEAL_TIMESTAMP)
        ) {
            startingIndexBlock = block.number;
        }
    }

    /**
     * @dev Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        startingIndex =
            uint256(blockhash(startingIndexBlock)) %
            MAX_TOTAL_KITTIES;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex =
                uint256(blockhash(block.number - 1)) %
                MAX_TOTAL_KITTIES;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }
}

/*

    Footnote

    *   Counting the hand-drawn background and t-shirt patterns the total of unique traits increase
        from a total of 416 (four hundred and sizeteen) to an incredible 708 (seven hundred and eight)
        unique traits.

*/
