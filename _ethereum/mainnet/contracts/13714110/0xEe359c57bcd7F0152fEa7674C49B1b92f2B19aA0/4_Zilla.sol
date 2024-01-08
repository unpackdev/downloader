// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Zilla is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // Claim Basic Variables
    string _baseTokenURI =
        "https://ipfs.io/ipfs/QmQYMSLbanR7CHtgGhBMD6RYNmWTkyPdByT2JpSNsjwtKH/";
    string hiddenURI =
        "https://ipfs.io/ipfs/QmNnz3jdhDeodePdFhEH1VzVqnjnQisngUoH4PxnpX3DqL/hidden.json";
    address PREMINT = 0xFc44b51003041bf8010646C07f2b31E757747359;
    address dev = 0x2F20D2cafaa1692e401791Be811700fb56f0930B;
    address admin1 = 0xB91fb18babD1b77cd628BE1841db934480c61Ad7;
    address admin2 = 0xFc44b51003041bf8010646C07f2b31E757747359;
    uint256 private constant MAX_ENTRIES = 3333;
    uint256 private constant PREMINT_ENTRIES = 100;

    // Set Prices following Tokenomics
    uint256 private OG_PRICE = 0.06 ether;
    uint256 private SALE_PRICE = 0.07 ether;
    uint256 private MAX_BUYABLE = 3;
    uint256 public price;

    // Set about the WhiteListed person
    mapping(address => bool) whitelisted;
    uint256 public whitelistAccessCount;
    uint16 private LIMIT_WL = 900;

    // Set about the OG members
    mapping(address => bool) ogmember;
    uint256 public ogCount;
    uint8 private LIMIT_OG = 100;

    // Set Variables to start
    bool public start;
    bool public revealStart;
    uint256 public startTime;

    // Amount of Tokens which are Minted
    uint256 public totalMinted;

    constructor() ERC721("Bored Zilla", "Zilla") {
        // setBaseURI(baseURI);
    }

    // When it runs, 100 NFTs go to the Admin's Wallet
    function preMint() public {
        for (uint8 i = 1; i <= PREMINT_ENTRIES; i++) _mint(PREMINT, i);
        totalMinted = 100;
    }

    function mint(uint256 amount) public payable {
        require(start == true, "SALE has not Started!");
        require(totalMinted + amount <= MAX_ENTRIES, "Amount Exceed!");

        if ((block.timestamp - startTime) <= 25200) {
            require(
                whitelisted[msg.sender] == true || ogmember[msg.sender] == true,
                "You are not a WhiteListed Person or OG Member!"
            );
            require(
                balanceOf(msg.sender) + amount <= MAX_BUYABLE,
                "In PRESALE Stage, you can buy ONLY 3 Zillas!"
            );
        }
        if (ogmember[msg.sender]) price = OG_PRICE * amount;
        else price = SALE_PRICE * amount;

        // Payment value must be larger than the 'price'
        require(msg.value >= price, "Zilla : INCORRECT PRICE!");
        payable(dev).transfer(((address(this).balance) * 2) / 100);
        payable(admin1).transfer(((address(this).balance) * 48) / 100);
        payable(admin2).transfer(((address(this).balance) * 50) / 100);
        for (uint8 i = 1; i <= amount; i++)
            _safeMint(msg.sender, (totalMinted + i));

        totalMinted += amount;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!revealStart) return hiddenURI;
        else
            return
                string(
                    abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json")
                );
    }

    function startSale() external onlyOwner {
        require(start == false, "PRESALE is not Started!");
        startTime = block.timestamp;
        start = true;
        revealStart = false;
    }

    function setRevealStart() external onlyOwner {
        revealStart = true;
    }

    function setWhitelistAddresses(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = true;
        }
        whitelistAccessCount += addresses.length;
    }

    function setOGAddresses(address[] calldata addresses) external onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            ogmember[addresses[i]] = true;
        }
        ogCount += addresses.length;
    }

    function getOGState(address user) public view returns (bool) {
        return ogmember[user];
    }

    function getWhitelistState(address user) public view returns (bool) {
        return whitelisted[user];
    }

    function setBaseURI(string memory _tokenURI) public onlyOwner {
        _baseTokenURI = _tokenURI;
    }

    function setHiddenURI(string memory _uri) public onlyOwner {
        hiddenURI = _uri;
    }
}
