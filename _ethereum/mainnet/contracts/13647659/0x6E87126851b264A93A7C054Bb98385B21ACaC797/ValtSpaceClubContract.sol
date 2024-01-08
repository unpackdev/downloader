// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "ERC721.sol";
import "Counters.sol";
import "Ownable.sol";
import "RoyaltiesV2Impl.sol";
import "LibPart.sol";
import "LibRoyaltiesV2.sol";

contract ValtSpaceClubContract is ERC721, RoyaltiesV2Impl, Ownable {
    // Parameters to allow easier reading of the contract code
    address public artist;
    mapping(address => bool) public excludedList;

    // Sale Event
    event Sale(address indexed from, address indexed to, uint256 price);

    // Bytes4 Code for EIP-2981
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // setup counter to keep track of NFTs that we have so far minted
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 private tokenCounter;

    mapping(uint256 => uint256) public tokenIdToPrice;

    // for _setTokenURI
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;

    // removed public on Oct 30
    constructor(address _artist) ERC721("ValtSpaceClub", "2222") {
        tokenCounter = _tokenIds.current();
        artist = _artist;
        // Add the artist to the exluded list so when the
        // artist sells the NFT, we don't charge a Royalty (as that would be silly)
        excludedList[_artist] = true;
    }

    function createCollectible(uint256 howManyNFTs)
        public
        payable
        returns (uint256[5] memory)
    {
        uint256 newTokenId = tokenCounter;
        uint256 v = tokenCounter;
        uint256 j = 100;
        uint256 i = 0;
        uint256[5] memory mintedTokens;
        require(howManyNFTs > 0, "You have to Mint at least 1 NFT!");
        require(howManyNFTs < 6, "You cannot Mint more than 5 NFTs!");
        // For loop begins to allow multiple buys in one transaction
        for (uint256 mintCount = 0; mintCount < howManyNFTs; mintCount++) {
            // Get the latest available token
            newTokenId = tokenCounter;
            v = newTokenId;

            // Get your own TokenURI instead of asking for it
            string
                memory myTokenURI = "https://thevaltspaceclub.io/ValtSpaceClub000";

            if (newTokenId < 10) {
                myTokenURI = "https://thevaltspaceclub.io/ValtSpaceClub000";
            } else if (newTokenId < 100) {
                myTokenURI = "https://thevaltspaceclub.io/ValtSpaceClub00";
            } else if (newTokenId < 1000) {
                myTokenURI = "https://thevaltspaceclub.io/ValtSpaceClub0";
            } else {
                myTokenURI = "https://thevaltspaceclub.io/ValtSpaceClub";
            }

            j = 100;
            bytes memory reversed = new bytes(j);
            i = 0;
            while (v != 0) {
                uint256 remainder = v % 10;
                v = v / 10;
                reversed[i++] = bytes1(uint8(48 + remainder));
            }

            bytes memory inStrb = bytes(myTokenURI);
            bytes memory s = new bytes(inStrb.length + i);

            for (j = 0; j < inStrb.length; j++) {
                s[j] = inStrb[j];
            }
            for (j = 0; j < i; j++) {
                s[j + inStrb.length] = reversed[i - 1 - j];
            }
            myTokenURI = "";
            if (newTokenId == 0) {
                myTokenURI = "https://thevaltspaceclub.io/ValtSpaceClub0000.json";
            }
            if (newTokenId > 0) {
                myTokenURI = string(s);

                bytes memory burl_1 = bytes(myTokenURI);
                bytes memory burl_2 = bytes(".json");
                bytes memory burl = bytes(
                    "https://thevaltspaceclub.io/ValtSpaceClub0000.json"
                );
                j = 0;

                for (i = 0; i < burl_1.length; i++) burl[j++] = burl_1[i];
                for (i = 0; i < burl_2.length; i++) burl[j++] = burl_2[i];
                myTokenURI = string(burl);
            }
            // Mint the Token
            _safeMint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, myTokenURI);
            setRoyalties(tokenCounter);

            // $222 USD is 0.055 ETH as of Oct 27, 2021
            uint256 floorPrice = 0.055 * 10**18;
            tokenIdToPrice[newTokenId] = floorPrice;
            tokenCounter = tokenCounter + 1;

            // After Mint we transfer the token from the artist to the msg.sender
            // If it is the Artist (i.e. minting a new NFT on the website) then do nothing
            if (msg.sender != artist) {
                require(floorPrice > 0, "This token is not for sale!!!");
                require(
                    msg.value / howManyNFTs == floorPrice,
                    "Incorrect value"
                );

                _transfer(artist, msg.sender, newTokenId);

                emit Sale(artist, msg.sender, floorPrice);

                tokenIdToPrice[newTokenId] = 0; // not for sale anymore
                // replaced msg.value by floorPrice in the next line
                payable(artist).transfer((floorPrice * 7) / 10); // send the ETH to the seller 70%
                payable(0xB48545E9EF2c580A6326d6aa6238e1EcAEb68A70).transfer(
                    (floorPrice * 3) / 10
                ); // send ETH to Developer 30%
            }
            // ***************** Now Buy it - end
            mintedTokens[mintCount] = newTokenId;
        } // For loop ends

        // NOW return the list of newTokenIds that were minted/purchased
        return mintedTokens;
    }

    // This _safeMint() override function allows someone else to mint the token
    // and pay for the mint, but the artist will remain the owner.
    function _safeMint(address to, uint256 tokenId) internal override {
        _mint(artist, tokenId);
    }

    function allowBuy(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == ownerOf(_tokenId), "Not owner of this token");
        require(_price > 0, "Price zero");
        tokenIdToPrice[_tokenId] = _price;
    }

    function setExcluded(address excluded, bool status) external {
        require(
            msg.sender == artist,
            "only the artists can set the exclusion list"
        );
        excludedList[excluded] = status;
    }

    // (ROYALTIES)
    //address payable _royaltiesRecipientAddress,
    //uint96 _percentageBasisPoints
    //onlyOwner
    function setRoyalties(uint256 _tokenId) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        //_royalties[0].value = _percentageBasisPoints;
        //_royalties[0].account = _royaltiesRecipientAddress;
        _royalties[0].value = 1000; // the royalty is hardcoded at 10%
        _royalties[0].account = payable(artist); // the royalty is always and only paid to the artist
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    // (ROYALTIES) END

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
    // (TOKENURI) END
}
