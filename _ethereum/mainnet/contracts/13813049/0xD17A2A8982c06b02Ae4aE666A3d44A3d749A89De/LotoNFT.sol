// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./VRFConsumerBase.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract HotcafeNFTickets is ERC721, Ownable, VRFConsumerBase, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint;

    bytes32 internal keyHash;
    uint internal fee;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    bool public isSalesActive = true;
    
    uint public constant MAX_SUPPLY = 10000;
    uint public price = 0.06 ether;
    uint public finalAmount;
    uint public teamShare = 20;
    uint public tier1Share = 40;
    uint public tier2Share = 20;
    uint public tier3Share = 20;
    uint public tier1WinnersQuantity = 1;
    uint public tier2WinnersQuantity = 20;
    uint public tier3WinnersQuantity = 40;
    uint public totalWinners = tier1WinnersQuantity + tier2WinnersQuantity + tier3WinnersQuantity;

    mapping(uint => uint) private winnerMatrix;
    mapping(address => uint) public accountRewards;
    mapping(address => bool) public accountToRewardsClaimed;

    uint public randomSeed;
    uint[] public _winnerTokens;

    constructor() 
        ERC721("Hotcafe NFTickets", "TICKET") 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
        _contractUri = "ipfs://QmP9Bi5etCGDgRBy5xwJVu67fgsRqtsEYgjtXMqdiL4b1k";
    }

    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out");
        require(msg.value >= price.mul(quantity), "ether send is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function safeMint(address to) internal {
        uint tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function selectWinners() public onlyOwner {
        require(randomSeed != 0, "seed not generated");

        finalAmount = address(this).balance;

        for (uint i = 0; i < totalWinners; i++) {
            uint winnerToken = nextWinner(uint(keccak256(abi.encode(randomSeed, i))));
            _winnerTokens.push(winnerToken);
        }

        distributeRewards();
        withdrawTeam();
    }

    function distributeRewards() internal {
        for (uint i = 0; i < _winnerTokens.length; i++) {
            address winner = ownerOf(_winnerTokens[i]);
            uint share = 0;
            if (i < tier1WinnersQuantity) {
                share = tier1Share.mul(10 ** 18).div(tier1WinnersQuantity);
            } else if (i < tier1WinnersQuantity + tier2WinnersQuantity) {
                share = tier2Share.mul(10 ** 18).div(tier2WinnersQuantity);
            } else if (i < tier1WinnersQuantity + tier2WinnersQuantity + tier3WinnersQuantity) {
                share = tier3Share.mul(10 ** 18).div(tier3WinnersQuantity);
            }

            accountRewards[winner] += finalAmount.mul(share).div(100).div(10 ** 18);
        }
    }

    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    function nextWinner(uint random) internal returns (uint) {
        uint maxIndex = totalSupply() - _winnerTokens.length;
        
        random = random % maxIndex;

        uint value = 0;
        if (winnerMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = winnerMatrix[random];
        }

        // If the last available winner place is still unused...
        if (winnerMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            winnerMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            winnerMatrix[random] = winnerMatrix[maxIndex - 1];
        }

        return value;
    }

    function allWinners() public view returns (uint[] memory winners) {
        uint _totalWinners = _winnerTokens.length;
        winners = new uint[](_totalWinners);

        for (uint i = 0; i < _totalWinners; i++) {
            winners[i] = _winnerTokens[i];
        }

        return winners;
    }

    function withdrawRewards() public nonReentrant {
        require(accountToRewardsClaimed[msg.sender] == false, "rewards already claimed");
        require(accountRewards[msg.sender] > 0, "account does not have rewards");

        require(payable(msg.sender).send(accountRewards[msg.sender]));

        accountToRewardsClaimed[msg.sender] = true;
    }

    function withdrawTeam() internal {
        require(payable(msg.sender).send(address(this).balance.mul(teamShare).div(100)));
    }

    function fulfillRandomness(bytes32, uint randomness) internal override {
        randomSeed = randomness;
    }
}