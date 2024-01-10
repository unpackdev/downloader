// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Strings.sol"; 
import "./Counters.sol";
import "./Ownable.sol";

contract CRCSUITES is Ownable, ERC721  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public mintFees;
    mapping (address => uint256) public buyBalance;
    string public baseUrl;
    uint256 public _limit;
    uint256 public _totalLimit;
    address public feeWallet;
    uint256 public sold;

    constructor () ERC721("ST Hospitality Collection", "ST Hospitality Collection") {
        mintFees = 4 *10**17;
        sold = 0;
        baseUrl = "https://ipfs.io/ipfs/bafybeida2pmonp26zjjn6ptpnqpsmbxiq23ccgciqtw7fe5qn7ndqlfxfy/";
        _limit = 3;
        _totalLimit = 20;
        feeWallet = 0x868cd1eC108DC2239e681D08B5F2Ca973d2aD8E0;
    }

    function setFeeWallet(address newWallet) public onlyOwner {
        feeWallet = newWallet;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseUrl;
    }

    function setBaseUrl (string memory baseUrl_) public onlyOwner {
        baseUrl = baseUrl_;
    }

    function setMintFees (uint256 _mintFees) public onlyOwner {
        mintFees = _mintFees;
    }

    function setTotalLimit (uint256 newLimit) public onlyOwner {
        _totalLimit = newLimit;
    }

    function mintManual() public onlyOwner {
        uint256 newItemId = 0;
        _tokenIds.increment();
        newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
    }

    function mint(uint256 n) public payable returns(uint256) {
        require(buyBalance[msg.sender] < _limit && n <= _limit, "you can only buy allowed number of NFTs");
        require(n <= _limit - buyBalance[msg.sender], "invalid n");
        
        require(msg.value == mintFees*n, "invalid fees");
        uint256 newItemId = 0;
        for(uint256 i =0; i < n; ++i) {
            sold++;
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            require(newItemId <= _totalLimit, "all minted");   
            _safeMint(msg.sender, newItemId);
            buyBalance[msg.sender] += i;
        }

        (bool succ, ) = address(feeWallet).call{value: msg.value}("");
        require(succ, "ETH not sent");

        return newItemId;
    }

    function tokenURI(uint256 tokenId) override public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(tokenId),
                ".json"
            )
        );
    }

    function withdrawEth() public onlyOwner{
        uint256 Balance = address(this).balance;

        (bool succ, ) = address(owner()).call{value: Balance}("");
        require(succ, "ETH not sent");
    }
}