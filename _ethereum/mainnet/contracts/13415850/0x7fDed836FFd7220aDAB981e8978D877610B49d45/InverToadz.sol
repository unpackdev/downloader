// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721.sol";

contract InverToadz is ERC721, Ownable {
    uint256 public numAvailableTokens = 6969;
    uint256 public tokenPrice = 0.0069 ether;
    uint256 public constant maxMintsPerTx = 5;
    uint256 public constant maxMintsPerWallet = 10;

    mapping(address => uint256) public addressToNumMinted;
    uint256[10000] private _availableTokens;

    bool public devMintLocked = false;
    bool public saleLive = false;

    string private _baseTokenURI;
    string private _contractURI;
    uint256 private _totalSupply;

    constructor() ERC721("InverToadz", "TOADZ") {}

    // Minting
    function mint(uint256 quantity) external payable {
        require(
            saleLive,
            "Sale is closed!"
        );
        require(
            quantity <= maxMintsPerTx,
            "There is a limit on minting too many at a time!"
        );
        require(
            numAvailableTokens - quantity >= 0,
            "Minting this many would exceed supply!"
        );
        require(
            addressToNumMinted[msg.sender] + quantity <= maxMintsPerWallet,
            "There is a limit on minting too many per wallet!"
        );
        require(
            msg.value >= tokenPrice * quantity,
            "Not enough ether sent!"
        );
        require(
            msg.sender == tx.origin,
            "No contracts!"
        );

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = getRandomSerialToken(quantity, i);
            _safeMint(msg.sender, tokenId);
            _totalSupply++;
        }

        addressToNumMinted[msg.sender] = addressToNumMinted[msg.sender] + quantity;
    }

    // Gifting
    function gift(address[] calldata receivers) external onlyOwner {
        require(
            numAvailableTokens - receivers.length >= 0,
            "Minting this many would exceed supply!"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 tokenId = getRandomSerialToken(receivers.length, i);
            _safeMint(receivers[i], tokenId);
            _totalSupply++;
        }
    }

    // Dev mint special tokens
    function mintSpecial(uint256[] calldata specialIds) external onlyOwner {
        require(
            !devMintLocked,
            "Dev Mint Permanently Locked"
        );
        uint256 num = specialIds.length;
        for (uint256 i = 0; i < num; i++) {
            uint256 specialId = specialIds[i];
            _safeMint(msg.sender, specialId);
            _totalSupply++;
        }
    }

    function getRandomSerialToken(uint256 _numToFetch, uint256 _i) internal returns (uint256)
    {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                msg.sender,
                tx.gasprice,
                block.number,
                block.timestamp,
                blockhash(block.number - 1),
                _numToFetch,
                _i
                )
            )
        );
        uint256 randomIndex = randomNum % numAvailableTokens;
        uint256 valAtIndex = _availableTokens[randomIndex];
        uint256 result;
        if (valAtIndex == 0) {
            result = randomIndex;
        } else {
            result = valAtIndex;
        }

        uint256 lastIndex = numAvailableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[randomIndex] = lastIndex;
            } else {
                _availableTokens[randomIndex] = lastValInArray;
            }
        }

        numAvailableTokens--;
        return result;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function lockDevMint() external onlyOwner {
        devMintLocked = true;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}