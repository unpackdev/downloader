// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC721.sol";
import "IERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";
import "ECDSA.sol";
import "Counters.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

contract KAPC is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using Strings for uint256;

    /**
    * @dev KAPC ERC721 gas optimized contract based on GBD.
    * */

    string public KAPC_PROVENANCE = "";

    uint256 public MAX_KAPC = 10000;
    uint256 public MAX_KAPC_PER_PURCHASE = 8;
    uint256 public MAX_KAPC_WHITELIST_CAP = 8;
    uint256 public MAX_KAPC_MAINSALE_CAP = 5;
    uint256 public MAX_KAPC_PER_ADDRESS = 8;
    uint256 public presalePRICE = 0.08 ether;
    uint256 public PRICE = 0.08 ether;
    uint256 public constant RESERVED_KAPC = 50;

    // presales will revert if any contract doesn't exist
    address[] public whitelist = [
        0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D, // Bored Ape Yacht Club
        0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623, // Bored Ape Kennel Club
        0x60E4d786628Fea6478F785A6d7e704777c86a7c6, // Mutant Ape Yacht Club
        0xF1268733C6FB05EF6bE9cF23d24436Dcd6E0B35E, // Desperate Apewives
        0x1a2F71468F656E97c2F86541E57189F59951efe7, // CryptoMories
        0xB4C80C8df14CE0a1e7C500FdD4e2Bda1644f89B6, // Crypto Pimps
        0x4503e3C58377a9d2A9ec3c9eD42a8a6a241Cb4e2, // Spiky Space Fish United
        0x65b28ED75c12D8ce29d892DE9f8304A6D2e176A7, // ChubbyKaijuDAO
        0x63FA29Fec10C997851CCd2466Dad20E51B17C8aF, // Fishy Fam
        0x0B22fE0a2995C5389AC093400e52471DCa8BB48a, // Little Lemon Friends
        0x123b30E25973FeCd8354dd5f41Cc45A3065eF88C, // Alien Frens
        0x30A51024cEf9E1C16E0d9F0Dd4ACC9064D01f8da  // MetaSharks
        ];

    // upgrade variables
    address public upgradeToken;
    uint256 public upgradePrice;
    mapping (uint256 => uint256) public upgradeLevel;
    uint256 public maximumUpgrade = 3;

    // metadata variables
    string public tokenBaseURI = "ipfs://Qma2n4MW5j2gsM345kR6zSFsWaG2XiNZ1gq9UWGS997c5U/";
    string public unrevealedURI;

    // mint variables
    bool public presaleActive = false;
    bool public mintActive = false;
    bool public reservesMinted = false;
    uint256 public presaleStart = 1643677200;
    uint256 public mainsaleStart = 1643763600;

    Counters.Counter public tokenSupply;

    mapping(address => uint256) private whitelistAddressMintCount;
    mapping(address => uint256) private mainsaleAddressMintCount;
    mapping(address => uint256) private totalAddressMintCount;

    // benefactor variables
    address payable immutable public payee;
    address immutable public reservee = 0x4C316f405FE1253FB9121274d5a8c51e6EDF0be7;

    // starting index variables
    uint256 public startingIndexBlock;
    uint256 public startingIndex;


    /**
    * @dev Contract Methods
    */

    constructor(address _payee
        ) ERC721("Kid Ape Playground Club", "KAPC") {
        payee = payable(_payee);
    }

    /************
    * Metadata *
    ************/

    /*
    * Provenance hash is the sha256 hash of the IPFS DAG root CID for KAPCs.
    * It will be set prior to any minting and never changed thereafter.
    */

    function setProvenanceHash(string memory provenanceHash) external onlyOwner {
        KAPC_PROVENANCE = provenanceHash;
    }

    /*
    * Note: Initial baseURI upon reveal will be a centralized server IF all KAPCs haven't
    * been minted by December 1st, 2021 - The reveal date. This is to prevent releasing all metadata
    * and causing a sniping vulnerability prior to all KAPCs being minted.
    * Once all KAPCs have been minted, the baseURI will be swapped to the final IPFS DAG root CID.
    * For this reason, a watchdog is not set since the time of completed minting is undeterminable.
    * We intend to renounce contract ownership once minting is complete and the IPFS DAG is assigned
    * to serve metadata in order to prevent future calls against setTokenBaseURI or other owner functions.
    */

    function setTokenBaseURI(string memory _baseURI) external onlyOwner {
        tokenBaseURI = _baseURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        presalePRICE = _price;
    }

    function setWhitelist(address[] memory _whitelist) external onlyOwner {
        whitelist = _whitelist;
    }

    function setUpgradeToken (address _upgradeToken, uint256 _upgradePrice) external onlyOwner {
        upgradeToken = _upgradeToken;
        upgradePrice = _upgradePrice;
    }

    function setUnrevealedURI(string memory _unrevealedUri) external onlyOwner {
        unrevealedURI = _unrevealedUri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bool revealed = bytes(tokenBaseURI).length > 0;

        if (!revealed) {
            return unrevealedURI;
        }

        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 contentId = _tokenId + upgradeLevel[_tokenId] * 10000;
        return string(abi.encodePacked(tokenBaseURI, contentId.toString()));
    }

    /********
    * Mint *
    ********/

    function whitelisted(address _buyer) external view returns (bool) {
        bool _whitelisted = false;
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (IERC721(whitelist[i]).balanceOf(msg.sender) > 0) {
                _whitelisted = true;
            }
        }
        return _whitelisted;
    }

    function mint(uint256 _quantity) external payable {
        require(block.timestamp > presaleStart || presaleActive == true || mintActive == true,
            "sale hasn't started");
        require(totalAddressMintCount[msg.sender].add(_quantity) <= MAX_KAPC_PER_ADDRESS,
            "You can only mint 8 per address.");
        // check for presale start time and make presale active 
        if (block.timestamp > presaleStart &&
                presaleActive == false) {
            presaleActive = true;
        }

        if (presaleActive == true &&
                block.timestamp < mainsaleStart &&
                mintActive == false) {        
            bool _whitelisted = false;
            for (uint256 i = 0; i < whitelist.length; i++) {
                if (IERC721(whitelist[i]).balanceOf(msg.sender) > 0) {
                    _whitelisted = true;
                }
            }
            require(_whitelisted == true, "Must have a whitelisted NFT");
            require(presaleActive, "Presale is not active");
            // // taking out for gas reduction
            //require(_quantity <= MAX_KAPC_WHITELIST_CAP, "You can only mint a maximum of 8 per transaction for presale");
            // require(whitelistAddressMintCount[msg.sender].add(_quantity) <= MAX_KAPC_WHITELIST_CAP, 
            //     "You can only mint 8 per address in the presale.");
            require(msg.value >= presalePRICE.mul(_quantity), "The ether value sent is less than the presale price.");

            // whitelistAddressMintCount[msg.sender] += _quantity;
            totalAddressMintCount[msg.sender] += _quantity;
            _safeMintKAPC(_quantity);
        }

        if (block.timestamp > mainsaleStart && mintActive == false) {
            mintActive = true;
        }
        if (mintActive == true) {
            require(mintActive, "Sale is not active.");
            require(_quantity <= MAX_KAPC_PER_PURCHASE, "Quantity is more than allowed per transaction.");
            require(mainsaleAddressMintCount[msg.sender].add(_quantity) <= MAX_KAPC_MAINSALE_CAP,
                "You are allowed to mint 5 per address in the main sale.");
            require(msg.value >= PRICE.mul(_quantity), "The ether value sent is less than the mint price.");

            mainsaleAddressMintCount[msg.sender] += _quantity;
            totalAddressMintCount[msg.sender] += _quantity;
            _safeMintKAPC(_quantity);
        }
    }

    function _safeMintKAPC(uint256 _quantity) internal {
        require(_quantity > 0, "You must mint at least 1 KAPC");
        require(tokenSupply.current().add(_quantity) <= MAX_KAPC, "This purchase would exceed max supply of KAPCs");
        this.withdraw();
        
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < MAX_KAPC) {
            tokenSupply.increment();
            _safeMint(msg.sender, mintIndex);
            }
        }

        // If we haven't set the starting index and this is either 1) the last saleable token or 2) the first token to be sold after
        // the end of pre-sale, set the starting index block
        if (startingIndexBlock == 0 && (tokenSupply.current() == MAX_KAPC -1|| mintActive == true)) {
            startingIndexBlock = block.number;
        } 
    }

    /*
    * Note: Reserved KAPCs will be minted immediately after the presale ends
    * but before the public sale begins. This ensures a randomized start tokenId
    * for the reserved mints.
    */

    function mintReserved() external onlyOwner {
        require(!reservesMinted, "Reserves have already been minted.");
        require(tokenSupply.current().add(RESERVED_KAPC) <= MAX_KAPC, "This mint would exceed max supply of KAPCs");

        for (uint256 i = 0; i < RESERVED_KAPC; i++) {
            uint256 mintIndex = tokenSupply.current();

            if (mintIndex < MAX_KAPC) {
                tokenSupply.increment();
                    if (mintIndex > 45){
                        _safeMint(msg.sender, mintIndex);
                    } else {
                        _safeMint(reservee, mintIndex);
                    }
            }
        }
        reservesMinted = true;
    }

    function setPresaleActive(bool _active) external onlyOwner {
        presaleActive = _active;
    }

    function setMintActive(bool _active) external onlyOwner {
        mintActive = _active;
    }

    /**********
    * Upgrade *
    **********/ 

    function upgrade(uint256 token) public {
        require(this.ownerOf(token) == msg.sender, "Can't upgrade a token you don't own.");
        require(this.upgradeLevel(token) < maximumUpgrade, "Token fully upgraded");
        require(upgradeToken != address(0), "Upgrade token must be set");
        require(
            IERC20(upgradeToken).transferFrom(msg.sender, 
                reservee, 
                upgradePrice),
            "Must send upgradePrice tokens to upgrade");
        upgradeLevel[token] += 1;
    }

    /**************
    * Withdrawal *
    **************/

    function withdraw() public {
        uint256 balance = address(this).balance;
        payable(payee).transfer(balance);
    }


    /**
     * Set the starting index for the collection
     */

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_KAPC;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % MAX_KAPC;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }
}
