// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./VRFConsumerBase.sol";


interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);

}

contract Llama is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ReentrancyGuard, VRFConsumerBase {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter private _tokenIdCounter;
    uint256 private unitCost;
    uint256 private _maxPurchase;
    uint256 private _maxTokens;
    string _folderPath;
    bool _saleComplete;
    address _devAddress;
    
    uint256 public LastLottoDraw;
    uint256 public NextLottoDraw;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    
    uint256 public CurrentJackpotInWei;
    uint256 public TotalJackpotInWei;
    uint256 private maxJackpotInWei;
    event CloseSale(address indexed _from);
    event OpenSale(address indexed _from);
    event PrizeWon(address indexed _winner, uint256 _prize, uint256 _rank, uint256 _tokenId);

    mapping(address => uint256) public WhiteList;
    bool private OnlyWhiteList;
    
    constructor() VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator - 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token - 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
        ) ERC721("Lotto Llamas", "LL") {

        
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; //0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
        fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
        
        unitCost = 0.0777 ether; //start price - 0.0777 ether
        _maxPurchase = 20;
        _maxTokens = 10000;
        _saleComplete = false;

        _tokenIdCounter.increment(); //first token is ID 1
        OnlyWhiteList = true;
        _pause();
    }

    function updateLinkFee(uint256 _fee) public onlyOwner{
        fee = _fee;
    }
 
     function updateLinkKeyhash(bytes32 _keyHash) public onlyOwner{
        keyHash = _keyHash;
    }   
    function toggleWhitelist() public onlyOwner {
        OnlyWhiteList = !OnlyWhiteList;
    }
    
    function addWhitelist(address[] memory addresses) public onlyOwner {
        for(uint256 i; i < addresses.length; i++){
            WhiteList[addresses[i]] = 2;
        }
    }
    
    function devMint(address to, uint256 numberToMint) public onlyOwner onSale nonReentrant {
        require(_tokenIdCounter.current() <= _maxTokens, "Sold out!!");
        require(paused(), "Can only dev mint when contract is paused");

        _unpause();

        uint256 i = 0;
        do {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
            i++;
        } while (i < numberToMint && i < _maxPurchase);
        //can only mint a max of whatever the max public purchase is per transaction
        
        pause();
    }
    
    function drawLotto() public onlyOwner nonReentrant{
        require(randomResult > 0, "Set random seed first");
        require(block.timestamp > NextLottoDraw, "Too early for this lotto draw");
        require(address(this).balance >= CurrentJackpotInWei, "Not enough eth to pay jackpot");
        
        LastLottoDraw = block.timestamp;
        NextLottoDraw = block.timestamp.add(2419200); //next draw must be 28 days after the previous one (28 * 24 * 60 * 60)
        lottoTime(CurrentJackpotInWei);
        randomResult = 0; //reset seed for the  next draw
  
    }
    
    //remove this before mainnet deployment
    /*
    function setNextLottoDraw(uint256 nextLottoTimestamp) public onlyOwner {
        NextLottoDraw = nextLottoTimestamp;
    }*/
    
    //just have this method so we can check that chainlink is working correctly 
    //before starting minting. Can't reset seed after 500 llamas have been minted.
    function resetSeed() public onlyOwner {
        require(randomResult != 0, "seed is already 0");
        require(_tokenIdCounter.current() < 500, "Cannot reset seed");
        randomResult = 0;
    }
    
    function isSeedSet() public view returns(bool isSet){
        isSet = (randomResult != 0);
    }
    
    
    function lottoTime(uint256 jackpot) private {
        TotalJackpotInWei = TotalJackpotInWei.sub(jackpot);
        uint256 share = jackpot.div(100);
        
        uint256[10] memory prizes = [share.mul(40) //40% first prize
        , share.mul(10), share.mul(10), share.mul(10), share.mul(10) //10% 2nd - 5th prize
        , share.mul(4), share.mul(4), share.mul(4), share.mul(4), share.mul(4)]; //4% 5th - 10th prize
        
        uint256 maxNumber = totalSupply(); //totalSupply()
        
        uint256[] memory winners = currentWinners(prizes.length, maxNumber);
        for(uint256 i = 0; i < prizes.length; i++){
            uint256 winner = winners[i];
            
            //all the testing there was never a winner outside of the range..
            //but better safe than sorry.
            if (winner > 0 && winner <= maxNumber) {
            
            address winner_addy = ownerOf(winner);
            payable(winner_addy).transfer(prizes[i]);
            emit PrizeWon(winner_addy, prizes[i], i, winner);
            }
        }
    }
    
   function currentWinners(uint256 n, uint256 maxNumber) private  view returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = (uint256(keccak256(abi.encode(randomResult, i)))% maxNumber).add(1) ;
    }
    return expandedValues;
}

    function pause() public onlyOwner onSale {
        _pause();
    }
    
    function startSaleOrUpdateUrl(string memory folderPath) public onlyOwner onSale {
        
        _folderPath = folderPath;
        if (paused()){
             _unpause();
             emit OpenSale(msg.sender);   
        }

    }

    function updateBaseUri(string memory folderPath) public onlyOwner onSale {
        
        _folderPath = folderPath;

    }
    function _baseURI() internal view override returns (string memory) {
        
        return _folderPath;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function updateUnitPrice(uint256 unitPrice) public onlyOwner {
        unitCost = unitPrice;
    }

    function mintLlama(uint256 numberToMint) public payable nonReentrant whenNotPaused {
        require(numberToMint > 0 && numberToMint <= _maxPurchase, "Invalid mint amount");
        require(_tokenIdCounter.current() <= _maxTokens, "Sold out!!");
        require(msg.value == numberToMint.mul(unitCost), "Incorrect ETH amount");
        require(!OnlyWhiteList || WhiteList[msg.sender] >= numberToMint);
        require(numberToMint.add(balanceOf(msg.sender)) <= 200 || owner() == msg.sender, "max wallet limiter turned on for testing!!");
        
        uint256 i = 0;
        do {
                i++;
               _safeMint(msg.sender, _tokenIdCounter.current());
               _tokenIdCounter.increment();
            } while (i < numberToMint && _tokenIdCounter.current() <= _maxTokens);

            uint256 jp = unitCost.mul(i).div(100).mul(36); //fixed 36% jackpot cut
            TotalJackpotInWei = TotalJackpotInWei.add(jp);

            
            if (numberToMint.sub(i) > 0){
                //return any overspent funds for the last buyer
                payable(msg.sender).transfer(numberToMint.sub(i).mul(unitCost));
            }
            
            if(OnlyWhiteList){
                WhiteList[msg.sender] = WhiteList[msg.sender].sub(numberToMint);
            }
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
	
	function withdraw() public onlyOwner {

		uint256 balance = address(this).balance;
		require(balance.sub(TotalJackpotInWei) > 0, '"No funds available to withdraw');
		payable(msg.sender).transfer(balance.sub(TotalJackpotInWei));
	}


    //withdraw link or any other ERC tokens
	function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}
	
	function endSale() public onlyOwner onSale {
	    require(!paused(), "cannot close sale whilst paused");
	    require(_maxTokens == totalSupply(), "cannot close sale before it's sold out");
	    // once this action is completed the base URI cannot be changed 
	    // and contract cannot be paused.
	    _saleComplete = true;
	    emit CloseSale(msg.sender);
	}
	
	
	modifier onSale() {
        require(!_saleComplete, "Sale closed. Action cannot be completed");
        _;
    }
 
    function setCurrentJackpot(uint256 _currentJackpotInWei) public onlyOwner {
        
        CurrentJackpotInWei = _currentJackpotInWei;
    } 
    
    //not onlyOwner.. Anyone can add money to the jackpot
    function topUpJackpot() public payable nonReentrant {
        TotalJackpotInWei = TotalJackpotInWei.add(msg.value);
    }
    
    function setLottoSeed() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract");
        require(randomResult == 0, "Cannot set lotto seed if it is already set");
        return requestRandomness(keyHash, fee);
    }

    function getProjectData() public view returns (bool _onlyWhiteList, uint256 _unitCost, uint256 _currentJackpot, uint256 _totalJackpot, uint256 _nextLottoTimestamp, uint256 _totalSupply, bool _isPaused) {
        _currentJackpot = CurrentJackpotInWei;
        _totalJackpot = TotalJackpotInWei;
        _nextLottoTimestamp = NextLottoDraw;
        _isPaused = paused();
        _totalSupply = totalSupply();
        _unitCost = unitCost;
        _onlyWhiteList = OnlyWhiteList;
    }


    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
}