pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./Cyberchads.sol";

contract CyberchadsPresale is Ownable  {
    Cyberchads public _cyberchads;
    uint256 public tokensMinted;
    bool public saleActive;

    // Maximum Chads minted in the presale. More unique Chads with new art might be minted
    // in the future if the community wants it! 
    uint256 public constant MAX_CHAD_SUPPLY = 5453;

    constructor(Cyberchads cyberchads_) {
        _cyberchads = cyberchads_;
        // 5 legendary tokens were minted outside of the presale
        tokensMinted = _cyberchads.totalSupply() - 5;
    }

    /**
    * @dev Gets number of Chads that a buyer can buy per transaction, based on the current sale tier.
    */
    function getChadMaxAmount() public view returns (uint256) {
        require(saleActive == true, "Sale is not active");
        require(tokensMinted < MAX_CHAD_SUPPLY, "Sale has already ended, no more Chads left to sell.");

        if (tokensMinted >= 1220) {
            return 20; // After 1220, 20 Chads/tx.
        } else if (tokensMinted >= 233) {
            return 10; // 233 to 1220, 10 Chads/tx.
        } else {
            return 2; // 2 Chads/tx
        }
    }

    /**
    * @dev Gets current Chad price based on current supply.
    */
    function getChadPrice() public view returns (uint256) {
        require(saleActive == true, "Sale has not started yet so you can't get a price yet.");
        require(tokensMinted < MAX_CHAD_SUPPLY, "Sale has already ended, no more Chads left to sell.");

        if (tokensMinted >= 5448) {
            return 2618000000000000000; // 5448 - 5452 2.618 ETH
        } else if (tokensMinted >= 5435) {
            return 1618000000000000000; // 5435 - 5447 1.618 ETH
        } else if (tokensMinted >= 5401) {
            return 786000000000000000; // 5401 - 5434 0.786 ETH
        } else if (tokensMinted >= 3804) {
            return 618000000000000000; // 3804  - 5400 0.618 ETH
        } else if (tokensMinted >= 2207) {
            return 500000000000000000; // 2207 - 3803 0.5 ETH
        } else if (tokensMinted >= 1220) {
            return 382000000000000000; // 1220 - 2206 0.382 ETH
        } else if (tokensMinted >= 610) {
            return 236000000000000000; // 610 - 1219 0.236 ETH
        } else if (tokensMinted >= 233) {
            return 100000000000000000; // 233 - 609 0.1 ETH
        } else {
            return 41400000000000000; // 0 - 232 0.0414 ETH 
        }
    }

    /**
    * @dev Mints a given number chads.
    */
    function mintChads(uint256 numberOfChads) public payable {
        // Error handling.
        require(saleActive == true, "Sale is not active");
        require(tokensMinted < MAX_CHAD_SUPPLY, "Sale has already ended.");
        require(numberOfChads > 0, "You cannot mint 0 Chads.");
        require(numberOfChads <= getChadMaxAmount(), "You are not allowed to buy this many Chads at once in this price tier.");
        require(SafeMath.add(tokensMinted, numberOfChads) <= MAX_CHAD_SUPPLY, "Exceeds maximum Chad supply. Please try to mint less Chads.");
        require(SafeMath.mul(getChadPrice(), numberOfChads) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the Chads.
        for (uint i = 0; i < numberOfChads; i++) {
            _cyberchads.mint(msg.sender);
            tokensMinted = tokensMinted + 1;
        }
    }

    // ADMINISTRATIVE FUNCTIONS
    // ------------------------------------

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function startSale() public onlyOwner {
        saleActive = true;
    }
    function pauseSale() public onlyOwner {
        saleActive = false;
    }
}