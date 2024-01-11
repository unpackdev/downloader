pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract GambaKittiesClub is ERC721, Ownable{

    uint256 public nftPrice = 0.02 ether;
    uint256 public totalSupply;
    uint256 public MAX_NFT;
    uint256 public MAX_MINT_PER_ACC;
    uint256 public collectedETH;

    bool public isSaleActive;
    
    mapping(address => bool) public isAcceptedToken;
    mapping(address => uint256) public receivedTokenBalance;
    mapping(address => uint256) private totalTokensMinted;

    address private WETH;
    address private router;
    address private factory;
    
    string private baseTokenURI;
    
    constructor (
        string memory name,
        string memory symbol,
        uint256 _maxNFTSupply,
        uint256 _totalSupply,
        address _WETH,
        address _router
    ) ERC721(name, symbol) {
        MAX_NFT = _maxNFTSupply;
        MAX_MINT_PER_ACC = 5;
        totalSupply = _totalSupply;
        WETH = _WETH;
        router = _router;
        isSaleActive = true;
    }

    function setPrice(uint256 _price) public onlyOwner {
        nftPrice = _price;
    }

    function setMaxNFTSupply(uint256 _maxNFTSupply) public onlyOwner {
        MAX_NFT = _maxNFTSupply;
    }

    function withdrawFunds(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(isAcceptedToken[_tokenAddress], "Token is not accepted");
        require(receivedTokenBalance[_tokenAddress] >= _amount, "Not enough tokens");
        receivedTokenBalance[_tokenAddress] -= _amount;
        IERC20(_tokenAddress).transferFrom(address(this), msg.sender, _amount);
    }

    function acceptToken(address _tokenAddress) public onlyOwner {
        require(!isAcceptedToken[_tokenAddress], "Token is already accepted");
        isAcceptedToken[_tokenAddress] = true;
    }

    function rejectToken(address _tokenAddress) public onlyOwner {
        require(isAcceptedToken[_tokenAddress], "Token is not accepted");
        isAcceptedToken[_tokenAddress] = false;
    }

    function mintUsingETH(address _to) public payable {
        require(msg.value == nftPrice, "Not enough ETH");
        _mintGKC(_to);
        collectedETH += msg.value;
    }

    function mintUsingToken(address _tokenAddress, uint256 _amount, address _to) public {
        require(isAcceptedToken[_tokenAddress], "Token is not accepted");
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        _mintGKC(_to);
        receivedTokenBalance[_tokenAddress] += _amount;
    }

    function _mintGKC(address _to) internal {
        uint256 _totalSupply = totalSupply;
        require(isSaleActive, "Sale is not active");
        require(_totalSupply < MAX_NFT, "Max NFT supply reached");
        require(totalTokensMinted[_to] < MAX_MINT_PER_ACC, "Max mint per account reached");
        unchecked {
          _totalSupply++;
          totalTokensMinted[_to]++;
        }
        _mint(_to, _totalSupply);
        totalSupply = _totalSupply;
    }

    function calculateMinAmountOfTokenNeeded(
        address _tokenAddress
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = WETH;
        uint256[] memory amountInMins = IUniswapV2Router02(payable(router)).getAmountsIn(nftPrice, path);
        return amountInMins[0];
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setState(bool _state) public onlyOwner {
        isSaleActive = _state;
    }

    function setMaxMintPerAcc(uint256 _maxMintPerAcc) public onlyOwner {
        MAX_MINT_PER_ACC = _maxMintPerAcc;
    }
}
