// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract stinkyfarttown is ERC721A, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public MaxSupply = 7979;

    uint256 public price = 0.0028 ether;

    bool public open = false;

    uint256 public walletMintMax = 5;

    uint256 public maxFreeSupply = 1979;

    uint256 public walletFreeMintMax = 1;

    mapping(address => uint256) public freeMinted;

    string private _baseTokenURI;


    constructor()
        ERC721A("stinkyfarttown", "sft", 10000, MaxSupply)
    {
 
    } 

    modifier eoaOnly() {
        require(tx.origin == msg.sender, "EOA Only");
        _;
    }

    function mint(uint256 _number) external payable nonReentrant eoaOnly{

        require(open, "Not started");

        uint256 totalSupply = totalSupply();

        require(totalSupply.add(_number) <= MaxSupply, "Exceed max token supply");
        
        if(totalSupply.add(_number) <= maxFreeSupply && _number <= walletFreeMintMax){

            require(_number.add(freeMinted[msg.sender]) <= walletFreeMintMax,"Exceed wallet free max");

            freeMinted[msg.sender] = freeMinted[msg.sender].add(_number);

            if(msg.value > 0){
                payable(msg.sender).transfer(msg.value);
            }

        }else{           

            require(numberMinted(msg.sender).add(_number) <= walletMintMax, "Exceed wallet max");   

            require(msg.value == price.mul(_number),"Eth error");
        }

        _safeMint(msg.sender, _number);
    }


    function numberMinted(address _owner) public view returns (uint256) {

        return _numberMinted(_owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {

        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {

        _baseTokenURI = baseURI;
    }

    function setMaxFreeSupply(uint256 _maxFreeSupply) external onlyOwner {

        maxFreeSupply = _maxFreeSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {

        price = _price;
    }

    function setWalletMintMax(uint256 _walletMintMax) external onlyOwner {

        walletMintMax = _walletMintMax;
    }

    function setWalletFreeMintMax(uint256 _walletFreeMintMax) external onlyOwner {

        walletFreeMintMax = _walletFreeMintMax;
    }

    function toggle() external onlyOwner {
        
        open = !open;
    }


    function withdraw() public onlyOwner {

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1);

        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
    
}

interface OwnableDelegateProxy {
}
interface ProxyRegistry {
    function proxies(address) external view returns (OwnableDelegateProxy);
}