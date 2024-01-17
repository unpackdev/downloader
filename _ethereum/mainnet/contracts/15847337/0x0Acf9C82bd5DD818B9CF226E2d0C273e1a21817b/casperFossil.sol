//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./SafeMath.sol";


contract NOVUSFOSSILS is ERC721Enumerable, Ownable {
        using SafeMath for uint256;

    using Counters for Counters.Counter;
    using Strings for uint256;

    struct TierInfo {
        uint256 tierLength;
        uint256 tierPrice;
        bool isOpen;
    }

    Counters.Counter private _mints;
    string public baseTokenURI;
    mapping(address => bool) internal allowedToMint;
    mapping(uint256 => TierInfo) tierData;
    bool public allowlistEnabled;

    uint256 maxFossils = 888;

    constructor(string memory baseURI) ERC721("NOVUS Fossils", "NVSF") {
        setBaseURI(baseURI);

        TierInfo memory tierinfo = TierInfo(8, 250000000000000000, true);
        tierData[1] = tierinfo;
        tierinfo = TierInfo(88, 350000000000000000, true);
        tierData[2] = tierinfo;
        tierinfo = TierInfo(888, 50000000000000000, false);
        tierData[3] = tierinfo;
        allowlistEnabled = false;
    }

    modifier onlyAllowed() {
        if (allowlistEnabled) {
            require(
                isAllowed(msg.sender) || msg.sender == owner(),
                "You are not a wl !"
            );
        }
        _;
    }

    function isAllowed(address adr) public view returns (bool) {
        if (!allowlistEnabled) {
            return true;
        } else {
            return allowedToMint[adr];
        }
    }

    // Give allowance to one address to mint
    function giveAllowance(address _addr) public payable onlyOwner {
        allowedToMint[_addr] = true;
    }

    // Give allowance to a group of addresses to mint
    function giveGroupAllowance(address[] calldata _addrs)
        public
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < _addrs.length; ++i) {
            allowedToMint[_addrs[i]] = true;
        }
    }

    // Call this if a mistake was made to disable the mint allowance for that address
    function takeBackAllowance(address _adr) public payable onlyOwner {
        allowedToMint[_adr] = false;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // Mint function
    function mintFossil(address _adr) internal {
        uint256 newID = _mints.current();
        _safeMint(_adr, newID);
        _mints.increment();
    }

    // Call this with [adr, adr, adr] to airdrop an NFT to those address where [] is a list of addresses
    function dropMembership(address _addr) public onlyOwner {
        mintFossil(_addr);
    }

    function checkTierStatus() internal view returns (uint256 i) {
        uint256 currentID = _mints.current();
        require(currentID < maxFossils, ("All fossils has been minted"));
        for (i = 1; i < 4; ++i) {
            if (currentID < tierData[i].tierLength) return i;
        }
    }

    // Get the current price of the mint
    function getPrice() public view returns (uint256) {
        uint256 tierID = checkTierStatus();
        return tierData[tierID].tierPrice;
    }

    // Function that a user calls to mint
    function mintMembership() public payable onlyAllowed {
        uint256 tierID = checkTierStatus();
        require(
            msg.value == tierData[tierID].tierPrice && tierData[tierID].isOpen,
            "Can't mint"
        );
        mintFossil(msg.sender);
        if (allowlistEnabled) {
            delete allowedToMint[msg.sender];
        }
    }

    // Set the price of the mint (in wei)
    function setPrice(uint256 tierID, uint256 nPrice) public onlyOwner {
        tierData[tierID].tierPrice = nPrice;
    }

    // Open or close a tier
    function setOpen(uint256 tierID, bool status) public onlyOwner {
        tierData[tierID].isOpen = status;
    }

    // Set the length of a tier
    function setLength(uint256 tierID, uint256 len) public onlyOwner {
        tierData[tierID].tierLength = len;
    }

    // Set max mints allowed
    function setMaxMints(uint256 maxMints) public onlyOwner {
        maxFossils = maxMints;
    }

    // False disable WL mode
    function setAllowlistMode(bool en) public onlyOwner {
        allowlistEnabled = en;
    }

    // Withdraw ETH on the contract
    function receiveETH() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
