pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/WithLimitedSupply.sol


pragma solidity ^0.8.0;


/// @author 1001.digital 
/// @title A token tracker that limits the token supply and increments token IDs on each new mint.
abstract contract WithLimitedSupply {
    using Counters for Counters.Counter;

    // Keeps track of how many we have minted
    Counters.Counter private _tokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private _maxSupply;

    /// Instanciate the contract
    /// @param totalSupply_ how many tokens this collection should hold
    constructor (uint256 totalSupply_) {
        _maxSupply = totalSupply_;
    }

    /// @dev Get the max Supply
    /// @return the maximum token count
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /// @dev Get the current token count
    /// @return the created token count
    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    /// @dev Check whether tokens are still available
    /// @return the available token count
    function availableTokenCount() public view returns (uint256) {
        return maxSupply() - tokenCount();
    }

    /// @dev Increment the token count and fetch the latest count
    /// @return the next token id
    function nextToken() internal virtual ensureAvailability returns (uint256) {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return token;
    }

    /// @dev Check whether another token is still available
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    /// @param amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, "Requested number of tokens not available");
        _;
    }
}
// File: contracts/RandomlyAssigned.sol


pragma solidity ^0.8.0;


/// @author 1001.digital
/// @title Randomly assign tokenIDs from a given set of tokens.
abstract contract RandomlyAssigned is WithLimitedSupply {
    // Used for random index assignment
    mapping(uint256 => uint256) private tokenMatrix;

    // The initial token ID
    uint256 private startFrom;

    /// Instanciate the contract
    /// @param _maxSupply how many tokens this collection should hold
    /// @param _startFrom the tokenID with which to start counting
    constructor (uint256 _maxSupply, uint256 _startFrom)
        WithLimitedSupply(_maxSupply)
    {
        startFrom = _startFrom;
    }

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextToken() internal override ensureAvailability returns (uint256) {
        uint256 maxIndex = maxSupply() - tokenCount();
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        // Increment counts
        super.nextToken();

        return value + startFrom;
    }
}








pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
//import "./RandomlyAssigned.sol";

interface iINKz {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function burn(address from_, uint amount) external;
}

abstract contract OCTOHEDZ {

  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

    contract BabyKraken is Ownable, ERC721Enumerable, RandomlyAssigned {

    OCTOHEDZ private octohedz;
    address private octohedzContract = 0x6E5a65B5f9Dd7b1b08Ff212E210DCd642DE0db8B; 

    constructor(string memory baseTokenURI, string memory baseContractURI) ERC721("Baby Kraken", "BABYKRAKEN") RandomlyAssigned (MAX_KRAKEN,0) {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
        octohedz = OCTOHEDZ(octohedzContract);
    }

    uint public MAX_KRAKEN = 4000;
    uint256 constant public mintPriceINKz = 600 ether;
    bool public hasSaleStarted = false;
            string private _baseTokenURI;
    string private _baseContractURI;
    bool public inkzMintEnabled= true;
    uint256 public totalKrakensMinted = 0;

   // INKz Interactions
    address public INKzAddress;
    iINKz public INKz;
    function setINKz(address address_) external onlyOwner { 
        INKzAddress = address_;
        INKz = iINKz(address_);
    }
    
    
    function setINKzMintStatus(bool bool_) external onlyOwner {
        inkzMintEnabled = bool_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
       return _baseContractURI;
    }

        function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

      function flipSaleState() public onlyOwner {
        hasSaleStarted = !hasSaleStarted;
    }
    
        event Mint (address indexed to_, uint tokenId_);
        modifier onlySender {
        require(msg.sender == tx.origin, "No smart contracts allowed!");
        _;
    }
     
        modifier inkzMint {
        require(inkzMintEnabled, "Minting with INKz is not available yet!");
        _;
    } 

    
    function mintWithINKz(uint amount) public payable onlySender inkzMint {
        require(hasSaleStarted, "Sale must be active to breed a Baby Kraken");
        require(totalSupply()<= MAX_KRAKEN, "Exceeds Total Supply");
        require(INKz.balanceOf(msg.sender) >= mintPriceINKz * amount, "You do not have enough INKz!");
        require (octohedz.balanceOf(msg.sender)>1, "Need to have more than 1 OctoHedz to start breeding");
        INKz.burn(msg.sender, mintPriceINKz);  
        uint256 _mintId = nextToken();    
        _mint(msg.sender, _mintId);
        totalKrakensMinted++;
           emit Mint(msg.sender, _mintId);
        
    }

}
