// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

pragma solidity ^0.8.0;

contract NotSoSuperheroes is ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant RESERVES = 101; // 1 higher to avoid lte/gte checks
    uint256 private _saleTime = 1631901600; // Monday, September 17, 2021 2:00:00 PM EST
    uint256 private _price = 7 * 10**16; // Currently .07 ETH
    uint256 private _maxPerTx = 21; // 1 higher to avoid lte/gte checks

    address walletSaveTheChildren = 0x8880d170F87A709F3749c27d60D3F487cAFd1Fc3;
    address walletNSSCommunity = 0xA4b901B66e3dcA25dE2a933De40e97f39303E6FE;
    uint256 communitySplit = 10; // Split total will always equal 100

    uint256 totalDeliveredToSTC;

    string private _baseTokenURI;

    constructor(
        string memory baseURI
    ) ERC721("NotSoSuperheroes", "NSS") {
        setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function getSaleTime() public view returns (uint256) {
        return _saleTime;
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= _saleTime;
    }

    function setMaxPerTransaction(uint256 max) public onlyOwner {
        _maxPerTx = max;
    }

    function setSaleTime(uint256 time) public onlyOwner {
        _saleTime = time;
    }

    function setPrice(uint256 _newWEIPrice) public onlyOwner {
        _price = _newWEIPrice;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }


    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();
        require(msg.sender == tx.origin, "Must be called directly.");
        require(block.timestamp >= _saleTime, "The sale has not yet opened.");
        require(_maxPerTx > _count, "Exceeds transaction token limit.");
        require(MAX_SUPPLY >= totalSupply + _count, "Will exceed max supply.");
        require(msg.value == _price * _count, "Transaction value is not correct for this many heroes.");

        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    /*
     * Saves the initial reserves to be used for project promotion and giveaways.
     */
    function saveTheCity(uint256 _count) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _count < RESERVES, "Beyond max limit");
        require(block.timestamp < _saleTime, "The sale has already started.");
        for (uint256 index; index < _count; index++) {
            _safeMint(owner(), totalSupply + index);
        }
    }

    /*
     *  Save The Children will receive the sales proceeds from the first 500 and the last 500 mints. 
     *  This function checks what mint we're at, and how much has been sent to Save The Children so far if the withdraw function has been called previously.
     */
    function getBalanceForSTC() internal returns (uint256 totalForSaveTheChildren) {
        uint256 totalSupply = totalSupply();
        uint256 mintsToSellOut = MAX_SUPPLY - totalSupply;

        if (totalSupply < 500 + RESERVES) {
            totalForSaveTheChildren = ((totalSupply - RESERVES) * _price) - totalDeliveredToSTC;
            totalDeliveredToSTC += totalForSaveTheChildren;
        }
        else if (totalSupply > MAX_SUPPLY - 500) {
            totalForSaveTheChildren = (500 * _price) + ((500 - mintsToSellOut) * _price) - totalDeliveredToSTC;
            totalDeliveredToSTC += totalForSaveTheChildren;
        }
        else {
            totalForSaveTheChildren = (500 * _price) - totalDeliveredToSTC;
            totalDeliveredToSTC += totalForSaveTheChildren;
        }

        return totalForSaveTheChildren;
    } 

    /**
     * The withdrawAll function will always make sure any amount owed to Save The Children is paid first, then the Community, then the contract owner.
     */
    function withdrawAll() public payable onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 toSTC = getBalanceForSTC();
        uint256 newBalance = contractBalance - toSTC;

        if (toSTC != 0) {
            require(payable(walletSaveTheChildren).send(toSTC)); // Send STC any proceeds from allocated mints.
        }
        uint256 toCommunity = (newBalance * communitySplit) / 100; // Split post donation proceeds for community.
        require(payable(walletNSSCommunity).send(toCommunity));
        uint256 ownerBalance = newBalance - toCommunity;
        require(payable(msg.sender).send(ownerBalance)); // Finally pay off contract owner the remaining balance.
    }
}