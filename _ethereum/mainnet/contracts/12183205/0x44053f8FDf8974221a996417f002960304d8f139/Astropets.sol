pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Astropets is ERC721, Ownable, IMintedBeforeReveal {

    // This is the original provenance record of all Astropets in existence at the time.
    string public constant ORIGINAL_PROVENANCE = "5e97a8a678cf094940217772780fadef1422c87081529cbf85170f9b28568a39";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1617721200;

    // Time after which the Astropets are randomized and revealed (10 days from initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 10);

    // Maximum amount of Astropets in existance. Ever! No Astropets will be sold again after 10 day sale is over
    uint256 public constant MAX_ASTROPET_SUPPLY = 5885;

    // Words to live by
    string public constant R = "Don't let anyone tell you that you can't do something. Always try your best and shoot for the stars.";

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    // Mapping from token ID to whether the Astropet was minted before reveal.
    mapping (uint256 => bool) private _mintedBeforeReveal;

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    /**
    * @dev Returns if the Astropet was minted before reveal phase. This could come in handy later.
    */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
    * @dev Gets current Astropet price based on current supply.
    */
    function getAstropetMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_ASTROPET_SUPPLY, "Sale has already ended, no more Astropets left to sell.");

        uint currentSupply = totalSupply();
        
        if (currentSupply >= 1500) {
            return 20; // After 1500, max transaction is 20
        }
        else if (currentSupply >= 600) {
            return 20; // From 600 to 1500, max transaction is 20
        } 
        else {
            return 20; // First 600, max transaction is 20
        }
    }

    /**
    * @dev Gets current Astropet price based on current supply.
    */
    function getAstropetPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_ASTROPET_SUPPLY, "Sale has already ended, no more Astropets left to sell.");

        uint currentSupply = totalSupply();

        if (currentSupply >= 5800) {
            return 240000000000000000; // 5800 - 5885 0.24 ETH
        } else if (currentSupply >= 5300) {
            return 160000000000000000; // 5300 - 5799 0.16 ETH
        } else if (currentSupply >= 4500) {
            return 120000000000000000; // 4500 - 5299 0.12 ETH
        } else if (currentSupply >= 3300) {
            return 80000000000000000; // 3300 - 4499 0.08 ETH
        } else if (currentSupply >= 1800) {
            return 40000000000000000; // 1800 - 3299 0.04 ETH
        } else if (currentSupply >= 600) {
            return 20000000000000000; // 600 - 1799 0.02 ETH
        } else {
            return 10000000000000000; // 0 - 599 0.01 ETH 
        }
    }

    /**
    * @dev Mints yourself a Astropet. Or more. You do you.
    */
    function mintAAstropet(uint256 numberOfAstropets) public payable {
        // Some exceptions that need to be handled.
        require(block.timestamp >= SALE_START_TIMESTAMP && block.timestamp <= REVEAL_TIMESTAMP, 'Only purchasable during sale period');
        require(totalSupply() < MAX_ASTROPET_SUPPLY, "Sale has already ended.");
        require(numberOfAstropets > 0, "You cannot mint 0 Astropets.");
        require(numberOfAstropets <= getAstropetMaxAmount(), "You are not allowed to buy this many Astropets at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfAstropets) <= MAX_ASTROPET_SUPPLY, "Exceeds maximum Astropet supply. Please try to mint fewer Astropets.");
        require(SafeMath.mul(getAstropetPrice(), numberOfAstropets) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the amount of provided Astropets.
        for (uint i = 0; i < numberOfAstropets; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_ASTROPET_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_ASTROPET_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_ASTROPET_SUPPLY;
        }

        // Prevent default sequence because that would be a bit boring.
        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }

    function _getNow() public virtual view returns (uint256) {
        return block.timestamp;
    }
}