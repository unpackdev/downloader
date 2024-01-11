pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
//import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721A.sol";
//import "./PullPayment.sol";
//import "./console.sol";

contract NFT is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant TOTAL_SUPPLY = 9_999;
    uint256 public constant FREE_SUPPLY = 4_444;
    uint256 public constant MINT_PRICE = 0.01 ether;
    uint256 public constant MAX_MINT_TRANSACTION = 10; //Number thatt can be minted in a single transaction
    uint256 public constant MAX_MINT_FREE_TRANSACTION = 2; //max mint on a free transaction
    uint256 public constant TOTAL_MAX_MINT = 1000; //number a user can mint in total
    uint256 public constant NUM_FREE = 10; //Free Mints per user
    uint256 public constant LOCKED = 222; //Num mints locked for Owner
    bool public mintEnabled = true;

    mapping(address => uint256) public userNumMints;
    uint256 public LOCKED_MINTED;

    constructor() ERC721A("beartown", "BEARTOWN") {
        LOCKED_MINTED = 0;
        baseTokenURI = "";
    }

    string public baseTokenURI;

    function buildABear(uint256 numMint) external payable nonReentrant {
        require(mintEnabled, "Minting is not yet enabled");
        uint256 mintedSupply = totalSupply();
        require(mintedSupply + LOCKED <= TOTAL_SUPPLY, "Sold Out!");
        (uint256 totalMintCost, uint numMintedFree) = getMintPrice(numMint);
        require(msg.value == totalMintCost, "Pay up.");
        _safeMint(msg.sender, numMint);
       
       if (numMintedFree > 0){
           userNumMints[msg.sender] += numMintedFree;
       }
    }

    function buildBearArmy(address recipient, uint256 num) public onlyOwner {
        require(num > 0);
	    require(totalSupply() + LOCKED <= TOTAL_SUPPLY, "Not enough to mint");
        _safeMint(recipient, num);
        LOCKED_MINTED += num;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintEnabled(bool _mintEnabled) public onlyOwner {
        mintEnabled = _mintEnabled;
    }

    function getMaxMint() public view returns (uint256) {
        if (mintEnabled == false){
            return 0;
        }
        uint256 supplyRemaining = getSupplyRemaining();

        if (supplyRemaining < MAX_MINT_TRANSACTION) {
            return supplyRemaining;
        }
        return MAX_MINT_TRANSACTION;
    }

    function getFreeRemaining() public view returns (uint256) {
        if (totalSupply() >= FREE_SUPPLY){
            return 0;
        }
        return FREE_SUPPLY - totalSupply();
    }

    function getSupplyRemaining() public view returns (uint256){
        return (TOTAL_SUPPLY - totalSupply());
    }

    function getMintedSupply() public view returns (uint256){
        if (!mintEnabled){
            return totalSupply();
        }
        return totalSupply() + (LOCKED - LOCKED_MINTED);
    }

    function getMintPrice(uint numMint) public view returns (uint256, uint256) {
        //Allow user to have X free mints
        //After that tally up total and return. For use in FE/Mint Calculation
        require(totalSupply() + LOCKED <= TOTAL_SUPPLY, "Not enough to mint.");
        require(numMint > 0, "Mint amount must be greater than 0");
        uint userMints = userNumMints[msg.sender];
        uint MAX_TRANSACTION = getMaxMint();
        uint numMintedFree = 0;
        require(numMint <= MAX_TRANSACTION, "Minting too many at once.");
        if ((userMints < NUM_FREE) && getFreeRemaining() > 0) {
            if ((numMint >= MAX_MINT_FREE_TRANSACTION) && ((NUM_FREE - userMints) >= MAX_MINT_FREE_TRANSACTION)) {
                numMint -= MAX_MINT_FREE_TRANSACTION;
                numMintedFree = MAX_MINT_FREE_TRANSACTION;
            }else if ((numMint < MAX_MINT_FREE_TRANSACTION) && ((NUM_FREE - userMints) >= numMint)){
                numMintedFree = numMint;
                numMint = 0;
            }     
        }
        uint256 totalMintCost = (numMint * MINT_PRICE);
        return (totalMintCost, numMintedFree);
    }

   
    function canMint() public view returns (int) {
        //Statuses:
        //0: No supply
        //1: Can mint
        //2: Cant mint -- must wait before minting again
        //3: Cant mint -- Already minted max.
        //4: Cant mint -- not yet enabled
        if (totalSupply() == TOTAL_SUPPLY) {
            return 0;
        }

        if (mintEnabled == false) {
            return 4;
        }

        if (userNumMints[msg.sender] >= TOTAL_MAX_MINT) {
            return 3;
        }

        return 1;
    }


    function withdrawFunds() public payable onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Error sending funds.");
    }

    function withdrawERC(address _tokenContract) public payable onlyOwner {
        //Withdraw any stray ERC coins held by the contract
        IERC20 tokenContract = IERC20(_tokenContract);
        uint balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        tokenContract.transfer(msg.sender, balance);
    }
}
