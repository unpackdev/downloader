pragma solidity ^0.8.12;

import "./Ownable.sol";
import "./ERC721A.sol";



//██╗██╗░░██╗██╗░░░██╗███████╗░█████╗░    ████████╗░█████╗░███╗░░██╗
//██║██║░██╔╝██║░░░██║╚════██║██╔══██╗    ╚══██╔══╝██╔══██╗████╗░██║
//██║█████═╝░██║░░░██║░░███╔═╝███████║    ░░░██║░░░██║░░██║██╔██╗██║
//██║██╔═██╗░██║░░░██║██╔══╝░░██╔══██║    ░░░██║░░░██║░░██║██║╚████║
//██║██║░╚██╗╚██████╔╝███████╗██║░░██║    ░░░██║░░░╚█████╔╝██║░╚███║
//╚═╝╚═╝░░╚═╝░╚═════╝░╚══════╝╚═╝░░╚═╝    ░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝

// why looking left, when you can have an Azuki looking right?
// check ikuzaton.com
// this project is not affiliated with Azuki and Chiru Labs

contract IkuzaTonCollection is ERC721A, Ownable {

    using Strings for uint256;

    // boolean
    bool public isMintOpen = true;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 FREE_MINTS = 3000;
    uint256 PRICE = .02 ether;
    uint256 MAX_MINT_PER_TX = 100;
    uint256 MAX_FREE_MINT = 2;

    // strings
    string private _baseURIExtended;

    // mapping
    mapping(address => uint256) public freeMintPerWallet;

    constructor() ERC721A("IkuzaTon", "IKUZATON", MAX_MINT_PER_TX, MAX_SUPPLY) { }

    function _commonMint(address _to, uint _amount) internal {
        uint _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY, 'Max supply already reached');
        uint num_tokens = _amount;
        if ((num_tokens + _totalSupply) > MAX_SUPPLY) {
            num_tokens = MAX_SUPPLY - _totalSupply;
        }
        _safeMint(_to, num_tokens);
    }

    function mint(address _to, uint _amount) public payable {
        require(isMintOpen, "Mint not yet opened!");
        require(_amount <= MAX_MINT_PER_TX, "Max mint per transaction exceeded");
        uint _totalSupply = totalSupply();
        if (_totalSupply > FREE_MINTS) {
            require(PRICE*_amount <= msg.value, 'Not enough ether sent');
        } else {
            require(
                (freeMintPerWallet[_to] + _amount <= MAX_FREE_MINT) && (freeMintPerWallet[msg.sender] + _amount <= MAX_FREE_MINT),
                    "Exceeded max free mints per address");
            freeMintPerWallet[_to] += _amount;
            if (msg.sender != _to) freeMintPerWallet[msg.sender] += _amount;
        }
        _commonMint(_to, _amount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(_baseURI(), _tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function setMintOpen(bool _isMintOpen) public onlyOwner {
        isMintOpen = _isMintOpen;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }

    function setFreeMint(uint256 _freeMint) public onlyOwner {
        FREE_MINTS = _freeMint;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function developerMint(uint _amount) public onlyOwner {
        _commonMint(msg.sender, _amount);
    }

}
