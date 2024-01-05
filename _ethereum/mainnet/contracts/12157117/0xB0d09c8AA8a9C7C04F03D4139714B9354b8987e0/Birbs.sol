pragma solidity 0.7.6;

import "./ERC165.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Birbs is Ownable, ERC165, ERC721 {
    // Libraries
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    // Private fields
    Counters.Counter private _tokenIds;
    string private ipfsUri = "https://ipfs.io/ipfs/";

    // Public constants
    uint256 public constant MAX_SUPPLY = 10000;

    // Public fields
    bool public open = false;

    // This hash is the SHA256 output of the concatenation of the SHA256 hashes of the image data for all 10k Birbs
    string public constant provenanceHash = "db773b3b8e6c2b43a3f6adc8412091aa7b2ef6047e156e270a61a8527741c022";

    // After each round completes, these hashes will be set by an admin to the CID of an IPFS folder containing every
    // metadata file in that round. This contract will then return a decentralised IPFS URI when tokenURI() is called.
    // Once all rounds are complete, lock() will be called to permanently set the URI of every token to the IPFS hosted one.
    string[5] public roundHash;

    // This value will be set by an admin to an IPFS url that will list the hash and CID of all 10k Birbs.
    string public provenanceURI = "";

    // After all rounds are complete, and provenance records updated, the contract will be locked by an admin and then
    // the state of the contract will be immutable for the rest of time.
    bool public locked = false;

    modifier notLocked() {
        require(!locked, "Contract has been locked");
        _;
    }

    constructor()
    ERC721("Birbs", "BIRB")
    {
        _setBaseURI("https://cryptobirbs.io/meta/");
    }

    fallback()
    external payable
    {
        uint256 quantity = getQuantityFromValue(msg.value);
        mint(quantity);
    }

    // Public methods
    function mint(uint256 quantity)
    public payable
    {
        require(open, "Sale not open");
        require(quantity > 0, "Quantity must be at least 1");

        // Limit buys to 50 Birbs
        if (quantity > 50) {
            quantity = 50;
        }

        // Limit buys that exceed MAX_SUPPLY
        if (quantity.add(totalSupply()) > MAX_SUPPLY) {
            quantity = MAX_SUPPLY.sub(totalSupply());
        }

        uint256 price = getPrice(quantity);

        // Ensure enough ether was sent
        require(msg.value >= price, "Not enough ether sent");

        for (uint256 i = 0; i < quantity; i++) {
            _mintBirb(msg.sender);
        }

        // Return any remaining ether after the buy
        uint256 remaining = msg.value.sub(price);

        if (remaining > 0) {
            (bool success, ) = msg.sender.call{value: remaining}("");
            require(success);
        }
    }

    function getQuantityFromValue(uint256 value)
    public view
    returns (uint256)
    {
        uint256 totalSupply = totalSupply();
        uint256 quantity = 0;
        uint256 priceOfOne = 0;

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            if (totalSupply >= 9900) {
                priceOfOne = 1 ether;
            } else if (totalSupply >= 8500) {
                priceOfOne = 0.5 ether;
            } else if (totalSupply >= 6000) {
                priceOfOne = 0.25 ether;
            } else if (totalSupply >= 3000) {
                priceOfOne = 0.1 ether;
            } else {
                priceOfOne = 0.01 ether;
            }

            if (value >= priceOfOne) {
                totalSupply++;
                quantity++;
                value -= priceOfOne;
            } else {
                break;
            }
        }

        return quantity;
    }

    function getPrice(uint256 quantity)
    public view
    returns (uint256)
    {
        require(quantity <= MAX_SUPPLY);

        uint256 totalSupply = totalSupply();
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < quantity; i++) {
            if (totalSupply >= 9900) {
                totalPrice += 1 ether;
            } else if (totalSupply >= 8500) {
                totalPrice += 0.5 ether;
            } else if (totalSupply >= 6000) {
                totalPrice += 0.25 ether;
            } else if (totalSupply >= 3000) {
                totalPrice += 0.1 ether;
            } else {
                totalPrice += 0.01 ether;
            }

            totalSupply++;
        }

        return totalPrice;
    }

    function tokenOfOwnerPage(address owner, uint256 page)
    external view
    returns (uint256 total, uint256[12] memory birbs)
    {
        total = balanceOf(owner);

        uint256 start = page * 12;

        if (total > start) {
            uint256 countOnPage = 12;

            if (total - start < 12) {
                countOnPage = total - start;
            }

            for (uint256 i = 0; i < countOnPage; i ++) {
                birbs[i] = tokenOfOwnerByIndex(owner, start + i);
            }
        }
    }

    function tokenURI(uint256 tokenId)
    public view virtual override
    returns (string memory)
    {
        require(tokenId > 0 && tokenId <= totalSupply(), "URI query for nonexistent token");

        uint256 round;

        if (tokenId > 9900) {
            round = 4;
        } else if (tokenId > 8500) {
            round = 3;
        } else if (tokenId > 6000) {
            round = 2;
        } else if (tokenId > 3000) {
            round = 1;
        } else {
            round = 0;
        }

        // Try to construct an IPFS URI
        if (bytes(roundHash[round]).length > 0) {
            return string(abi.encodePacked(ipfsUri, roundHash[round], "/", tokenId.toString()));
        }

        // Fallback to centralised URI
        return string(abi.encodePacked(baseURI(), tokenId.toString()));
    }

    // Admin methods
    function ownerMint(uint256 quantity)
    public onlyOwner
    {
        require(!open, "Owner cannot mint after sale opens");

        for (uint256 i = 0; i < quantity; i++) {
            _mintBirb(msg.sender);
        }
    }

    function openSale()
    external onlyOwner
    {
        open = true;
    }

    function setBaseURI(string memory newBaseURI)
    external onlyOwner notLocked
    {
        _setBaseURI(newBaseURI);
    }

    function setIpfsURI(string memory _ipfsUri)
    external onlyOwner notLocked
    {
        ipfsUri = _ipfsUri;
    }

    function setRoundHash(uint256 _round, string memory _roundHash)
    external onlyOwner notLocked
    {
        roundHash[_round] = _roundHash;
    }

    function setProvenanceURI(string memory _provenanceURI)
    external onlyOwner notLocked
    {
        provenanceURI = _provenanceURI;
    }

    function lock()
    external onlyOwner
    {
        locked = true;
    }

    function withdrawEther()
    external onlyOwner
    {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    // Private Methods
    function _mintBirb(address owner)
    private
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
    }
}