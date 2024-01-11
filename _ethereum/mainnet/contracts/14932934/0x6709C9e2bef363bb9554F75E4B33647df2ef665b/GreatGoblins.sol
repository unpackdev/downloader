pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract GreatGoblins is ERC721A, Ownable {

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    bool public publicSaleOpen;
    string public _baseTokenURI;
    uint256 public constant MAX_FREE_PER_WALLET = 2;
    uint256 public constant MAX_FREE_SUPPLY = 3500;
    
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_PER_WALLET = 20;
    uint256 public constant MAX_SUPPLY = 7000;
    uint256 public constant COST_PER_MINT = 0.005 ether;

    // mapping(address => uint256) public userFreeMints;

    constructor() ERC721A("GreatGoblins", "GRTGBLNS") {
        publicSaleOpen = false;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleOpen = !(publicSaleOpen);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function mint(uint256 numOfTokens) external payable callerIsUser {
        require(publicSaleOpen, "Sale is not active yet");
        require(totalSupply() + numOfTokens < MAX_SUPPLY, "Exceed max supply"); 
        require(numOfTokens <= MAX_PER_TX, "Can't claim more than 10 in a tx");
        require(numberMinted(msg.sender) + numOfTokens <= MAX_PER_WALLET, "Cannot mint this many");

        uint256 txCost = getCost(numOfTokens);
        require(msg.value >= txCost, "Insufficient ether provided to mint");

        _safeMint(msg.sender, numOfTokens);
    }

    function getCost(uint256 numOfTokens) public view returns (uint256) {
        uint256 txCost = COST_PER_MINT * numOfTokens;
        if (numberMinted(msg.sender) < MAX_FREE_PER_WALLET) {
            if (numberMinted(msg.sender) + numOfTokens <= MAX_FREE_PER_WALLET) {
                txCost = 0;
            } else {
                txCost = txCost - (COST_PER_MINT * (MAX_FREE_PER_WALLET - numberMinted(msg.sender)));
            }
        }
        return txCost;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // get the funds from the minting of the NFTs
    function retrieveFunds() public onlyOwner {
        uint256 balance = accountBalance();
        require(balance > 0, "No funds to retrieve");
        
        _withdraw(payable(msg.sender), balance);
    }

    function _withdraw(address payable account, uint256 amount) internal {
        (bool sent, ) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function accountBalance() internal view returns(uint256) {
        return address(this).balance;
    }

    function ownerMint(address mintTo, uint256 numOfTokens) external onlyOwner {
        _safeMint(mintTo, numOfTokens);
    }

    function isSaleOpen() public view returns (bool) {
        return publicSaleOpen;
    }

}
