// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";

/// @custom:security-contact kolichenko@kolisar.com
contract PeaceForUkraine is ERC1155, Ownable {

    // Token URIs tokenId => URI
    mapping (uint => string) public _URIs;

    struct Leaderboard {
        address buyer;
        uint amount;
    }
    Leaderboard[] leaderboard;


    // Sale status
    bool public saleIsActive = true;

    // Minimal price of token
    uint public minimalTokenPrice = 0.05 ether;

    uint public soldItems = 0;

    uint public totalFunds = 0;

    mapping (uint => uint) public itemsStatistic;

    uint public tokensCount = 12;

    // Initialization
    constructor() ERC1155("") {

        // Preset of token URLs
        setURI(1, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceI.json");
        setURI(2, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceII.json");
        setURI(3, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceIII.json");
        setURI(4, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceIV.json");
        setURI(5, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceV.json");
        setURI(6, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceVI.json");
        setURI(7, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceVII.json");
        setURI(8, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceVIII.json");
        setURI(9, "ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceIX.json");
        setURI(10,"ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceX.json");
        setURI(11,"ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceXI.json");
        setURI(12,"ipfs://QmXQan6aXNmrxdZJkaaHJifUuv5Qh3CaTfh9inKDySukgS/PeaceXII.json");

        // Mint tokens to creators
        for (uint i=1; i<=tokensCount; i++)
        {
            _mint(0x32ff88F42A804dfE2cEE38d67dB20f1eC589eF03, i, 1, "");
            _mint(0x46E3ba081A56d157896406074DB47bDd8e0bD34e, i, 1, "");

            itemsStatistic[i]+=2;
        }
    }

    // Generate random number
    function random(uint i)
        private
        view
        returns (uint)
    {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i)))%tokensCount+1;
    }

    // Close sales proces
    function closeSales()
        public
        onlyOwner
    {
        saleIsActive = false;
    }

    // Setting minimal Token Price
    function setMinimalTokenPrice(uint _price)
        public
        onlyOwner
    {
        minimalTokenPrice = _price;
    }

    // Add buyer to Leaderboard
    function addToLeaderboard(address _buyer, uint _amount)
        private
    {
        uint _index = 0;

        for (uint i=0; i<leaderboard.length; i++) {
            if (leaderboard[i].buyer == _buyer) {
                _index = i+1;
            }
        }

        if (_index == 0) {
            leaderboard.push(Leaderboard(_buyer, _amount));
        }
        else {
            leaderboard[_index-1].amount += _amount;
        }
    }

    // Get Buyers count
    function getBuyersCount()
        public
        view
        returns (uint)
    {
        return leaderboard.length;
    }

    // Get Buyer by id
    function getBuyer(uint _id)
        public
        view
        returns (address, uint)
    {
        uint length = leaderboard.length;

        if (_id < length) {
            return (leaderboard[_id].buyer, leaderboard[_id].amount);
        }
        else {
            return (address(0x00), uint(0));
        }
    }

    // Set tokens count
    function addToken(string memory _tokenURI)
        public
        onlyOwner
    {
        tokensCount++;
        setURI(tokensCount, _tokenURI);
    }

    // Set token URL
    function setURI(uint _id,string memory _newURI)
        public
        onlyOwner
    {
        _URIs[_id] = _newURI;
    }

    // Minting tokens
    function mint(uint _amount)
        public
        payable
        returns (uint[] memory)
    {
        require (saleIsActive == true, "PeaceForUkraine: Sales are not active");
        require (msg.value >= _amount*minimalTokenPrice, "PeaceForUkraine: Not enough money");

        uint[] memory _tokenIds = new uint[](_amount);
        uint _tokenId;

        for (uint i=1; i<=_amount; i++)
        {
            _tokenId = random(i);
            _mint(msg.sender, _tokenId, 1, "");
            
            soldItems++;
            itemsStatistic[_tokenId]++;
            _tokenIds[i-1] = _tokenId;
        }
        totalFunds += msg.value;
        addToLeaderboard(msg.sender, msg.value);

        return _tokenIds;
    }


    // Get URL of token
    function uri(uint _id)
        public
        view
        override(ERC1155)
        returns (string memory)
    {
        return _URIs[_id];
    }


    /**
     * @dev Withdraw of money from contract
     */
    function withdraw(address _receiver)
        public
        onlyOwner
    {
        uint _balance = address(this).balance;
        address payable receiver = payable(_receiver);
        receiver.transfer(_balance);
    }
}