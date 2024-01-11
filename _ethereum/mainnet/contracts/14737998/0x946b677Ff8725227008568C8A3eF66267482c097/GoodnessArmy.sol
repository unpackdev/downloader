// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./ERC2981Base.sol";

struct CharityAddress {
    address payable charityAddress;
    bool isActive;
    uint256 donated;
}

contract GoodnessArmy is ERC721, ERC2981Base, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter public tokenIdCounter;
    Counters.Counter public charityAddressCounter;


    //Declare an Events
    event Donate(
        address indexed from, 
        uint256 indexed charityID, 
        uint256 amount
    );
    event PermanentURI(
        string _value,
        uint256 indexed _id
    );

    // 90% go to ukrainian government Charity Address
    uint public constant CharityFee = 9000; // 9000 = 90%
    uint public constant Royalties = 1000;  // 1000 = 10%
    
    // 200 NFT for Goodness Army devs team
    uint public constant amountForDevs = 200;
    
    // Collect Fee addresses
    address payable immutable public TreasureAddress;

    // address payable public CharityAddress;
    
    // Base NFT url
    string projectURI = "https://api.goodness.army/nft/"; 
    string public constant contractURI = "https://src.goodness.army/manifest/goodness-army-metadata";

    // CONSTANT VALUES
    // 10k NFT TOTAL
    uint public constant totalSupply = 10000;
    
    // price for 1 nft = 0.25 ether
    uint public constant nftPrice = 0.25 ether;

    // Donation statistics (collect data about how much ethereum go as donation to ukrainian gov ether address)
    uint256 public totalDonated;

    // Charity Addresses list
    mapping(uint256  => CharityAddress) public CharityAddressOf;

    constructor() ERC721("Goodness Army", "ARMY") {
    
        // We took charity Address #0 from ukrainian government website:
        // https://www.kmu.gov.ua/news/mincifri-svitova-kriptospilnota-pidtrimuye-ukrayinu
        addCharityAddress(payable(0x165CD37b4C644C2921454429E7F9358d18A45e14));

        // Goodness Army get 10% from minting fee for marketing purpose
        // address immutable and can not be change
        TreasureAddress = payable(0x4DE9c61665304B4b5CE5AB80bbbBF28BE5596e91);

        // pre-mint for Goodness Army devs team
        firstMint();
    }

    // nft base URI
    function _baseURI() internal view override returns (string memory) {
        return projectURI;
    }

    // ADMIN FUNCTIONS
    // Update base URI
    function updateBaseURI(string memory newURI) public onlyOwner {
        projectURI = newURI;
    }

    // Update Charity Address
    function addCharityAddress(address newCharity) public onlyOwner {
        CharityAddressOf[charityAddressCounter.current()] = CharityAddress({
            charityAddress: payable(newCharity),
            isActive: true,
            donated: 0
        });
        charityAddressCounter.increment();
    }
    function activateCharityAddress(uint24 ID) public onlyOwner {
        require(!CharityAddressOf[ID].isActive, "activateCharityAddress: already in active mode");
        CharityAddressOf[ID].isActive = true;
    }
    function deactivateCharityAddress(uint24 ID) public onlyOwner {
        require(CharityAddressOf[ID].isActive, "deactivateCharityAddress: already deactivated");
        CharityAddressOf[ID].isActive = false;
    }

    // Mint NFT
    function bunchMint(uint amount, uint256 charityID) public payable {
        require(tokenIdCounter.current().add(amount).sub(1) < totalSupply, "bunchMint: exceed 10000 limit");
        require(amount > 0, "bunchMint: amount can't be 0 value");
        require(amount.mul(nftPrice) <= msg.value, "Ether value sent is not correct");
        if (msg.sender == TreasureAddress) {
            donateFromTreasure(charityID);
        } else {
            donate(charityID);
        }        
        uint256 Id;
        while ( Id < amount ) {
            _permanentMint(tokenIdCounter.current());
            Id++;
        }
    }

    // Donate
    function donate(uint256 charityID) public payable {
        require(CharityAddressOf[charityID].isActive, "donate: CharityAddress is deactivated by this ID");
        uint256 sentAmount = msg.value;
        uint256 charity = sentAmount.div(10000).mul(CharityFee);
        totalDonated = totalDonated.add(sentAmount);
        CharityAddressOf[charityID].donated = CharityAddressOf[charityID].donated.add(charity); 
        require(CharityAddressOf[charityID].charityAddress.send(charity), "Failed to send Ether to the charity Address");
        require(TreasureAddress.send(sentAmount.sub(charity)), "Failed to send Ether to the treasure Address");
        //Emit Donate event
        emit Donate(msg.sender, charityID, charity);
    }

    function donateFromTreasure(uint256 charityID) public payable {
        require(CharityAddressOf[charityID].isActive, "donateFromTreasure: CharityAddress is deactivated by this ID");
        require(msg.sender == TreasureAddress, "donateFromTreasure: can be treggered only from TreasureAddress");
        uint256 charity = msg.value;
        totalDonated = totalDonated.add(charity);
        CharityAddressOf[charityID].donated = CharityAddressOf[charityID].donated.add(charity);
        require(CharityAddressOf[charityID].charityAddress.send(charity), "Failed to send Ether to the charity Address");
        //Emit Donate event
        emit Donate(msg.sender, charityID, charity);
    }

    // pre-mint for Goodness Army devs team
    function firstMint() private {
        uint256 tokenId;
        while (tokenId < amountForDevs) {
            _permanentMint(tokenId);
            tokenId++;
        }
    }

    function _permanentMint(uint256 tokenId) private {
        _safeMint(msg.sender, tokenId);
        // Set Permanent url ...
        emit PermanentURI( string(abi.encodePacked(projectURI,tokenId.toString())), tokenId);
        // token ID increment
        tokenIdCounter.increment();
    }

    // Royalties IERC2981 setup interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // IERC2981 Royalties base function
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = TreasureAddress;
        royaltyAmount = (value * Royalties) / 10000;
    }
}