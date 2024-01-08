// SPDX-License-Identifier: MIT

// LITTLE CATS NFT
// Spreading a little joy to the world with these cats.
// N O S Λ J I O - @nosaj_io

pragma solidity >=0.7.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract LittleCats is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_CATS = 9999;
    string public CAT_PROVENANCE = "";

    uint256 private price = 30000000000000000; //0.03 ETH
    bool public isSaleOn = true;

    uint256 public airdropCount;
    address public ethWinner;
    address public teslaWinner;

    constructor() ERC721("LittleCats", "LILCAT") {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function mintCat(uint256 numberOfTokens) public payable {
        require(isSaleOn, "Sale not active.");
        require(numberOfTokens > 0 && numberOfTokens <= 20, "Can only mint 1-20 cats at a time.");
        require(totalSupply().add(numberOfTokens) <= MAX_CATS, "Exceed max supply. Try lowering number of cats.");
        require(msg.value >= price.mul(numberOfTokens), "Not enough ETH.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_CATS) {
                _safeMint(msg.sender, mintIndex);
            }
            if (mintIndex == 5000) {
                _ethRaffle();
            }
        }

        if (totalSupply() == MAX_CATS) {
            _tesla();
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        CAT_PROVENANCE = _provenanceHash;
    }

    function flipSale() public onlyOwner {
        isSaleOn = !isSaleOn;
    }

    function tokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function randomizer() private view returns (uint256) {
        bytes32 txHash = keccak256(
            abi.encode(block.coinbase, block.timestamp, block.difficulty)
        );
        return uint256(txHash);
    }

    function airdrop() external onlyOwner {
        uint256 rd = randomizer() % 100;
        for (uint256 i = 0; i < 10; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < MAX_CATS) {
                _safeMint(
                    ownerOf(1000 * airdropCount + 100 * i + rd),
                    mintIndex
                );
            }
        }
        airdropCount++;
    }
    
    // Pick one ETH Winner when 5,000 cats are minted.
    function _ethRaffle() private {
        uint256 swag = 4959;
        uint256 rd = randomizer() % 1000;
        bytes32 txHash = keccak256(
            abi.encode(
                ownerOf(swag - 1000 + rd),
                ownerOf(swag - 2000 + rd),
                ownerOf(swag - 3000 + rd),
                ownerOf(swag - 4000 + rd),
                msg.sender
            )
        );
        ethWinner = ownerOf((uint256(txHash) % 4959) + 1);
    }

    // Pick one Tesla Winner when 9,999 cats are minted.
    function _tesla() private {
        require(totalSupply() == MAX_CATS);

        uint256 swag = 9918;
        uint256 rd = randomizer() % 1000;

        bytes32 txHash = keccak256(
            abi.encode(
                ownerOf(swag - 1000 + rd),
                ownerOf(swag - 2000 + rd),
                ownerOf(swag - 3000 + rd),
                ownerOf(swag - 4000 + rd),
                ownerOf(swag - 5000 + rd),
                ownerOf(swag - 6000 + rd),
                msg.sender
            )
        );
        teslaWinner = ownerOf((uint256(txHash) % 9918) + 1);
    }
}
