// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";
import "./Strings.sol";

contract LastMintedGemAir is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant MAX_PURCHASE = 20;
    uint256 private constant TOTAL_SELECTED_HOLDERS = 100;
    uint256 private TICKET_PRICE = 30000000000000000;
    uint256[] private HOLDERS_ETHER = [
        50000000000000000000,
        40000000000000000000,
        30000000000000000000,
        20000000000000000000,
        10000000000000000000,
        5000000000000000000,
        3000000000000000000,
        2000000000000000000,
        1000000000000000000
    ];
    address[] private HOLDERS_SELECTED_WALLETS;
    uint256 public numberOfWallets = 0;
    string private image;

    mapping(address => uint256) private claimableEther;

    constructor() ERC721("LastMintedGemAir", "LMG") {
        claimableEther[
           0x85a0c71B183B53B689C31EEE22461E2b7c3dA1e7
        ] = 180000000000000000000;
    }

    function setImage(string memory _image) public onlyOwner {
        image = _image;
    }

    function validateSeeds(uint256[] memory seeds) public pure returns (bool) {
        bool isValid = false;
        if (seeds.length == TOTAL_SELECTED_HOLDERS) {
            isValid = true;
        }
        return isValid;
    }

    function getSeletedHolders() public view returns (address[] memory) {
        return HOLDERS_SELECTED_WALLETS;
    }

    function getClaimableEther() public view returns (uint256) {
      return claimableEther[msg.sender];
    }

    function selectHolders(uint256 seed, uint256 position) public payable {
        require(
            HOLDERS_SELECTED_WALLETS.length < TOTAL_SELECTED_HOLDERS,
            "SELECT HOLDERS: winners already selected"
        );
        require(
            _tokenIdCounter.current() == MAX_SUPPLY,
            "SELECT HOLDERS: current token id should be 20000"
        );
        uint256 token = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed))
        ) % MAX_SUPPLY;
        address selectedWallet = super.ownerOf(token);
        HOLDERS_SELECTED_WALLETS.push(selectedWallet);
        if (position == 0) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[0];
        }
        if (position == 1) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[1];
        }
        if (position == 2) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[2];
        }
        if (position == 3) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[3];
        }
        if (position >= 4 && position <= 11) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[4];
        }
        if (position >= 12 && position <= 15) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[5];
        }
        if (position >= 16 && position <= 26) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[6];
        }
        if (position >= 27 && position <= 90) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[7];
        }
        if (position >= 91) {
            claimableEther[selectedWallet] += HOLDERS_ETHER[8];
        }
        ++numberOfWallets;
    }

    function mint(uint256 quantity, uint256[] memory seeds) external payable {
        require(
            quantity <= MAX_PURCHASE,
            "Mint: tickets to mint exceeds max per transations"
        );
        require(
            msg.value >= TICKET_PRICE * quantity,
            "Mint: ether amount incorrect"
        );
        require(
            _tokenIdCounter.current() + quantity <= MAX_SUPPLY,
            "Mint: Purchase would exceed max supply"
        );
        if (_tokenIdCounter.current() + quantity >= MAX_SUPPLY) {
            require(validateSeeds(seeds), "Mint: provided seeds not valid");
        }

        for (uint8 i = 0; i < quantity; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
        }
        if (_tokenIdCounter.current() == MAX_SUPPLY) {
            // last minter thanks for your services
            claimableEther[msg.sender] = 10000000000000000000;
            for (uint8 j = 0; j < TOTAL_SELECTED_HOLDERS; j++) {
                // select random holders
                selectHolders(seeds[j], j);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory name = string(
            abi.encodePacked("Last Minted Gem Air #", tokenId.toString())
        );
        string
            memory description = "Air is an invisible mixture of gases, primarily oxygen and nitrogen, that surrounds the Earth and is vital for breathing";
        return createTokenURI(name, description);
    }

    function createTokenURI(string memory name, string memory description)
        internal
        view
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '", "external_url":"https://lastmintedgem.art", "description":"',
                        description,
                        '", "image":"',
                        image,
                        '"}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    // If you are a randomly selected holder, you can use this method to claim your Ethereum
    function claim() public {
        require(claimableEther[msg.sender] > 0, "Claim: Nothing to claim");
        require(numberOfWallets == TOTAL_SELECTED_HOLDERS, "Claim: Holders no selected");
        uint256 amount = claimableEther[msg.sender];
        claimableEther[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

