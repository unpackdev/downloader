// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract Halfwits is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 5555;
    uint256 public MAX_MINT_LIMIT_PER_TXN = 10;
    uint256 public MAX_FREE_PER_WALLET = 1;
    uint256 public MINT_PRICE = 0.002 ether;

    bool mintOpen = false;

    mapping(address => bool) private _accountToFreeMint;

    bool _revealed = false;
    string private baseURI = "https://nftstorage.link/ipfs/bafkreibdoh276ymmk27px7deeqln4bx5etxelqyrhwhozcuwbaqepruxce";

    address public constant DEV_ADDRESS = 0x88552648FA6971C4cb8d30DA778b6Ef4B06ef826;  // 30 
    address public constant PROJECT_ADDRESS = 0x3E9BB8cFAC724288D4cb74b65422bfB214282229; // 30
    address public constant TEAM_ADDRESS = 0x9149b12c42E7C4D9F8c5D0D8913A8b4073dfA0fA; // 40 
  
    constructor() ERC721A("Halfwits", "Halfwits") {}

    function mint(uint256 amount) external payable {

        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");
        require(mintOpen, "MINT_IS_NOT_YET_ACTIVE");
        
        require(amount > 0,"MINT_ATLEAST_1");
        require(amount <= MAX_MINT_LIMIT_PER_TXN, "MAX_LIMIT_PER_TXN");
        require(totalSupply() + amount <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        
        if (!_accountToFreeMint[msg.sender]) {
            require(msg.value >= MINT_PRICE * (amount - MAX_FREE_PER_WALLET), "NOT_ENOUGH_ETH");
            _accountToFreeMint[msg.sender] = true;
        } else {
            require(msg.value >= MINT_PRICE * amount, "NOT_ENOUGH_ETH");
        }

        _safeMint(msg.sender, amount);
    }

    function getMintState() public view returns (bool) {
        return mintOpen;
    }

    function getMintPrice() public view returns (uint256) {
        return MINT_PRICE;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    // URI
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    function switchMintState() external onlyOwner {
        mintOpen = !mintOpen;
    }
        
    function setMaxMintPerTxn(uint256 _mintLimit) external onlyOwner {
        MAX_MINT_LIMIT_PER_TXN = _mintLimit;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }

    function mintForTeam(uint256 numberOfTokens) external onlyOwner {
        _safeMint(msg.sender, numberOfTokens);
    }

    function batchMint(address[] calldata addresses, uint[] calldata amounts) external onlyOwner {
        require(addresses.length == amounts.length, "MISMATCH_ADDRESSES_AMOUNT_LENGTH");
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], amounts[i]);
        }
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        uint256 acc_a = (balance * 30) / 10000;
        uint256 acc_b = (balance * 30) / 10000;
        payable(DEV_ADDRESS).transfer(acc_a);
        payable(PROJECT_ADDRESS).transfer(acc_b);
        payable(TEAM_ADDRESS).transfer(address(this).balance);
    }
}