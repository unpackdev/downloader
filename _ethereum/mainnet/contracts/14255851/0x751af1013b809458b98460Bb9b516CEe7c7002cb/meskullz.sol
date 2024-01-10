// SPDX-License-Identifier: MIT

//  author Name: Alex Yap
//  author-email: <echo@alexyap.dev>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./skullz.sol";

interface IWhitelistContract {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract MeSkullz is ERC721Enumerable, ReentrancyGuard, Ownable {

    struct WLConStruct {
        IWhitelistContract _cntrct;
        bool _vld;
    }

    string public MESKULLZ_PROVENANCE = "";
    string public baseTokenURI;
    bool public mintIsActive = false;
    bool public mintIsActivePixlrGenesis = false;
    bool public mintIsActiveWhitelistWallet = false;
    bool public mintIsActiveWhitelistContract = false;
    uint256 adminMinted;
    uint256 adminReserved = 200;
    uint256 constant pixlrGenesisReserved = 300;
    uint256 public pixlrGenesisMinted;
    uint256 public whitelistMaxMint = 3;
    uint256 public meskullzPrice;
    uint256 public meskullzMaxPerMint;
    uint256 public skullzPriceName = 300 ether;
    uint256 public constant MAX_MESKULLZ = 10000;
    mapping(uint256 => string) public meskullzName;
    mapping(uint256 => bool) public pixlrGenesisClaimed;
    mapping(address => uint256) public whitelistMinted;
    mapping(string => WLConStruct) public whitelistContract;
    mapping(address => bool) public whitelist;
    Skullz public skullzToken;
    IWhitelistContract pixlrGenesis;
    
    //events
    event NameChanged(string name, uint256 tokenId);

    constructor(string memory baseURI, uint256 _mintPrice, uint256 _maxPerMint, address _pixlrGenesis) ERC721("MeSkullz", "MSZ") {
        setBaseURI(baseURI);
        meskullzPrice = _mintPrice;
        meskullzMaxPerMint = _maxPerMint;
        pixlrGenesis = IWhitelistContract(_pixlrGenesis);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        meskullzPrice = _mintPrice;
    }

    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        meskullzMaxPerMint = _maxPerMint;
    }

    function setWhitelistMaxMint(uint256 _max) external onlyOwner {
        whitelistMaxMint = _max;
    }

    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipPixlrGenesisMintState() public onlyOwner {
        mintIsActivePixlrGenesis = !mintIsActivePixlrGenesis;
    }

    function flipWhitelisWalletMintState() public onlyOwner {
        mintIsActiveWhitelistWallet = !mintIsActiveWhitelistWallet;
    }

    function flipWhitelisContractMintState() public onlyOwner {
        mintIsActiveWhitelistContract = !mintIsActiveWhitelistContract;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        MESKULLZ_PROVENANCE = provenanceHash;
    }

    function setSkullzToken(address _yield) external onlyOwner {
        skullzToken = Skullz(_yield);
    }

    function setBurnRate(uint256 _namingPrice) external onlyOwner {
        skullzPriceName = _namingPrice;
    }

    function addWhitelist(address[] calldata _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = true;
        }
    }

    function removeWhitelist(address[] calldata _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            delete whitelist[_addrs[i]];
        }
    }

    function addWhitelistContract(string[] calldata _names, address[] calldata _addrs) public onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelistContract[_names[i]] = WLConStruct(IWhitelistContract(_addrs[i]), true);
        }
    }

    function removeWhitelistContract(string[] calldata _names) public onlyOwner {
        for (uint256 i = 0; i < _names.length; i++) {
            delete whitelistContract[_names[i]];
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(msg.sender).transfer(balance);
    }

    function reserveMeskullz(uint256 numberOfTokens) public onlyOwner {
        require((adminMinted + numberOfTokens) <= adminReserved, "Purchase would exceed reserved supply");

        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_MESKULLZ) {
                uint256 mintIndex = supply + i;
                adminMinted++;
                _safeMint(msg.sender, mintIndex);
            }
        }

        skullzToken.updateRewardOnMint(msg.sender);
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant{
        require(mintIsActive, "Sales are inactive");
        require(numberOfTokens <= meskullzMaxPerMint, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - pixlrGenesisMinted - adminMinted) <= (MAX_MESKULLZ - pixlrGenesisReserved - adminReserved), "Purchase would exceed supply");
        require(meskullzPrice * numberOfTokens <= msg.value, "Incorrect ether value");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
        
        skullzToken.updateRewardOnMint(msg.sender);
    }

    function mintForPixlrGenesis(uint16[] calldata pgTokenIds) public nonReentrant{
        require(mintIsActivePixlrGenesis, "Sales are inactive");
        require(pgTokenIds.length <= meskullzMaxPerMint, "Cannot purchase this many tokens per transaction");
        require((pixlrGenesisMinted + pgTokenIds.length) <= pixlrGenesisReserved, "Purchase would exceed reserved supply");

        for (uint256 i = 0; i < pgTokenIds.length; i++) {
            require(pixlrGenesis.ownerOf(pgTokenIds[i]) == msg.sender, "Not the owner of this token");
            require(!pixlrGenesisClaimed[pgTokenIds[i]], "Token already claimed");
            pixlrGenesisClaimed[pgTokenIds[i]] = true;
            pixlrGenesisMinted++;
            _safeMint(msg.sender, totalSupply());
        }

        skullzToken.updateRewardOnMint(msg.sender);
    }

    function mintForWhitelistWallet(uint256 numberOfTokens) public payable nonReentrant{
        require(mintIsActiveWhitelistWallet, "Sales are inactive");
        require(numberOfTokens <= meskullzMaxPerMint, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - pixlrGenesisMinted - adminMinted) <= (MAX_MESKULLZ - pixlrGenesisReserved - adminReserved), "Purchase would exceed supply");
        require(meskullzPrice * numberOfTokens <= msg.value, "Incorrect ether value");
        require(whitelist[msg.sender], "Minting is only available for whitelisted users");
        require((whitelistMinted[msg.sender] + numberOfTokens) <= whitelistMaxMint, "Number of tokens requested exceeded the value allowed per wallet");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (whitelistMinted[msg.sender] < whitelistMaxMint) {
                whitelistMinted[msg.sender]++;
                _safeMint(msg.sender, totalSupply());
            }
        }
        
        skullzToken.updateRewardOnMint(msg.sender);
    }

    function mintForWhitelistContract(uint256 numberOfTokens, string memory _contractName) public payable nonReentrant{
        require(mintIsActiveWhitelistContract, "Sales are inactive");
        require(numberOfTokens <= meskullzMaxPerMint, "Cannot purchase this many tokens per transaction");
        uint256 total = totalSupply();
        require((total + numberOfTokens - pixlrGenesisMinted - adminMinted) <= (MAX_MESKULLZ - pixlrGenesisReserved - adminReserved), "Purchase would exceed supply");
        require(meskullzPrice * numberOfTokens <= msg.value, "Incorrect ether value");
        require(validateName(_contractName), "Invalid name");
        require(whitelistContract[_contractName]._vld, "Invalid contract");
        require(whitelistContract[_contractName]._cntrct.balanceOf(msg.sender) > 0, "You do not hold any token in this contract");
        require((whitelistMinted[msg.sender] + numberOfTokens) <= whitelistMaxMint, "Number of tokens requested exceeded the value allowed per wallet");

        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (whitelistMinted[msg.sender] < whitelistMaxMint) {
                whitelistMinted[msg.sender]++;
                _safeMint(msg.sender, totalSupply());
            }
        }
        
        skullzToken.updateRewardOnMint(msg.sender);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override nonReentrant{
        skullzToken.updateReward(from, to);
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override nonReentrant{
        skullzToken.updateReward(from, to);
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function getReward() external {
        skullzToken.updateReward(msg.sender, address(0));
        skullzToken.getReward(msg.sender);
    }

    function changeName(uint256 _tokenId, string memory _newName) public {
        require(ownerOf(_tokenId) == msg.sender);
        require(validateName(_newName), "Invalid name");
        skullzToken.burn(msg.sender, skullzPriceName);
        meskullzName[_tokenId] = _newName;

        emit NameChanged(_newName, _tokenId);
    }

    function validateName(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);

        if(b.length < 1) return false;
        if(b.length > 25) return false;
        if(b[0] == 0x20) return false; // Leading space
        if(b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) {
                return false;
            }

            lastChar = char;
        }

        return true;
    }
}