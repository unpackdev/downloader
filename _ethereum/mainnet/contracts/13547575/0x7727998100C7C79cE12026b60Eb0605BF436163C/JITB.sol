// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Utility.sol"; // Utility Functions

contract JACK_IN_THE_BLOCKS is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter internal _tokenIds;

    string internal baseCID; // CID of the base URI I.E//QmP5NXDTvFmFQiU91xDdt56yfSPybCUb22mX3Zkvg3nJDT
   

    bool public _paused = true; //Minting Status

    bool public premint_paused = true; //Preminting Status

    uint256 public _price = 60000000000000000; //Price in wei 0.06 ETH

    uint256 public _reserved = 115; //Reserved Tokens for giveaway

    uint16 public mintingSupply = 2978; // NFT Supply Cap

    uint16 public mintedFromReserve; // reserved token supply //default 0

    uint16 public mintedFromSupply; // reserved token supply //default 0

    mapping(address => bool) public claimedToken; // pre-minted tokens per address

    //WITHDRAW ADDRESS
    address _withdrawAddress = 0x6917Dd141930D6496F0605225f4Eef2e697Dff88;

    //PUNK EVOLVED ADDRESS
    address PUNK_EVOLVE_ADDRESS = 0xD28c830DED2C84304Fd576F91AE3a78fDc981d27;

    //INITIALIZING CONTRACT
    constructor() ERC721("Jack In The Blocks", "JITB") {}

    //Get Total Supply of Tokens // --<
    function totalSupply() public view override returns (uint256) {
        return _tokenIds.current();
    }

    // Allows Tokens to be Viewed // --<
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    "ipfs://",
                    baseCID,
                    "/",
                    Utility.toString(tokenId),
                    ".json"
                )
            );
    }

    // --<
    function pre_mint() external payable {
        uint256 balance = ERC721(address(PUNK_EVOLVE_ADDRESS)).balanceOf(
            msg.sender
        );
        require(balance > 0, "Must Own A Punk Evolve");
        require(!claimedToken[msg.sender], "Presale Token Claimed");
        require(!premint_paused, "Minting is currently paused!");
        require(
            msg.value == getDiscountPrice(msg.sender),
            "ETH sent not correct!"
        );
        require(
            mintedFromSupply + 1 <= mintingSupply - _reserved,
            "Exceeds Minting Supply"
        );
        _tokenIds.increment();
        _safeMint(msg.sender, _tokenIds.current());
        mintedFromSupply++;
        claimedToken[msg.sender] = true;
    }

    //MINT x amount of NFT // --<
    function mint(uint8 amount) external payable {
        uint256 price = getDiscountPrice(msg.sender);
        require(!_paused, "Minting is currently paused!");
        require(msg.value == price * amount, "ETH sent not correct!");
        require(
            mintedFromSupply + amount <= mintingSupply - _reserved,
            "MUST_MINT_FROM_RESERVE"
        );
        require(amount > 0 && amount <= 5, "EXCEEDS_TRANSACTION_LIMIT");
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
            mintedFromSupply++;
        }
    }

    // --<
    function giveAway(address _to, uint256 _amount) external onlyOwner {
        require(mintedFromReserve + _amount <= _reserved, "EXCEEDS_SUPPLY");
        for (uint256 i; i < _amount; i++) {
            _tokenIds.increment();
            _safeMint(_to, _tokenIds.current());
            mintedFromReserve++;
        }
    }

    //CHANGE PAUSE STATE // --<
    function premint_toggle() external onlyOwner {
        premint_paused = !premint_paused;
    }

    // --<
    function mint_toggle() external onlyOwner {
        premint_paused = true;
        _paused = !_paused;
    }

    //GET PRICE // --<
    function getDiscountPrice(address _address) public view returns (uint256) {
        uint256 balance = ERC721(address(PUNK_EVOLVE_ADDRESS)).balanceOf(
            _address
        );
        if (balance >= 1 && balance <= 3) {
            return _price - 5000000000000000;
        } else if (balance >= 4 && balance <= 6) {
            return _price - 10000000000000000;
        } else if (balance >= 7) {
            return _price - 15000000000000000;
        } else {
            return _price;
        }
    }

    // --<
    function getPrice() public view returns (uint256) {
        return _price;
    }

    //RETURN ALL TOKENS OF A SPECIFIC ADDRESS // --<
    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    //WITHDRAW CONTRACT BALANCE TO DEFINED ADDRESS // --<
    function withdraw() public onlyOwner {
        payable(address(_withdrawAddress)).transfer(address(this).balance);
    }

    //SETS THE BASEURL FOR THE METADATA USING CID // --<
    function setBaseURI(string calldata cid) public onlyOwner {
        baseCID = cid;
    }

    // --<
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // --<
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
