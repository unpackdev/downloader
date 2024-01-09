pragma solidity >=0.6.0 <0.8.9;
pragma experimental ABIEncoderV2;
//SPDX-License-Identifier: MIT

//import "./console.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC20.sol";
import "./Counters.sol";
import "./Ownable.sol";
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

interface ILLove {
    function balanceOf(address owner) external view returns (uint);
    function burn(address account, uint amount) external;
}

interface ISimpsOffice {
    function randomQueenOwner() external returns (address);
    function addTokensToStake(address account, uint16[] calldata tokenIds) external;
}

interface IRandom {
    function updateRandomIndex() external;
    function getSomeRandomNumber(uint _seed, uint _limit) external view returns (uint16);

}


contract SimpsCity is ERC721Enumerable, Ownable {
    uint16 public version=21;
    uint public MAX_TOKENS = 50000;
    uint constant public MINT_PER_TX_LIMIT = 100;

    uint public tokensMinted = 0;
    uint16 public phase = 0;
    uint16 public queenStolen = 0;
    uint16 public simpStolen = 0;
    uint16 public queenMinted = 0;

    bool private _paused = true;

    mapping(uint16 => uint) public phasePrice;



    ISimpsOffice public simpsOffice;
    ILLove public love;
    IRandom public random;

    string private _apiURI = "https://api.simps.city/";

    // mapping(address => uint) private _whiteList;
    mapping(address => uint) private _freeList;
 
    mapping(uint16 => bool) private _isQueen;
    
    uint16[] private _availableTokens; 


    event TokenStolen(address owner, uint16 tokenId, address thief);


    constructor() ERC721("Simps", "SIMPS"){

        // Phase 1 is available in the beginning
        switchToSalePhase(0, true);
        //switchToSalePhase(1, true);

        // Set default price for each phase
        phasePrice[0] = 0.07 ether;
        phasePrice[1] = 0.08 ether;
        phasePrice[2] = 24000 ether;
        phasePrice[3] = 50000 ether;
        phasePrice[4] = 90000 ether;
        phasePrice[5] = 120000 ether;
        phasePrice[6] = 150000 ether;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }


    function getAvaTokenIds() public view returns(uint16[] memory){
        uint16[] memory b = new uint16[](_availableTokens.length);
        for (uint i=0; i < _availableTokens.length; i++) {
            b[i] = _availableTokens[i];
        }
        return b;
    
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function setPaused(bool _state) external  {
        _paused = _state;
    }

    function addAvailableTokens(uint16 _from, uint16 _to) public onlyOwner {
        internalAddTokens(_from, _to);
    }

    function internalAddTokens(uint16 _from, uint16 _to) internal {
        for (uint16 i = _from; i <= _to; i++) {
            _availableTokens.push(i);
        }
    }

    function switchToSalePhase(uint16 _phase, bool _setTokens) public onlyOwner {
        phase = _phase;

        if (!_setTokens) {
            return;
        }

        if(phase == 0){
            //pre sale
            internalAddTokens(1, 9999);
        } else if (phase == 1) {
            //first public sales
        } else if (phase == 2) {
            internalAddTokens(10000, 15000);
        } else if (phase == 3) {
            internalAddTokens(15001, 23000);
        } else if (phase == 4) {
            internalAddTokens(23001, 37000);
        } else if (phase == 5) {
            internalAddTokens(37001, 45000);
        } else if (phase == 6) {
            internalAddTokens(45001, 50000);
        }


    }

    function giveAway(uint _amount, address _address) public onlyOwner {
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_availableTokens.length > 0, "All tokens for this Phase are already sold");

        for (uint i = 0; i < _amount; i++) {
            uint16 tokenId = getTokenToBeMinted();
            _safeMint(_address, tokenId);
        }
    }

    // function addWhiteList(uint _amount, address _address) public onlyOwner {
    //     _whiteList[_address]= _amount;
    // }

    function addFreeList(uint _amount, address _address) public onlyOwner {
        _freeList[_address]= _amount;
    }

    // function getUserWhiteListAmount(address add) public view returns(uint){
    //     uint count = _whiteList[add];
    //     return count;
    // }

    function getUserFreeListAmount(address add) public view returns(uint){
        uint count = _freeList[add];
        return count;
    }

    // modifier chekAndUpateWL(uint _mint_amount){
    //     require(_whiteList[msg.sender]>0, "Only whitelist can mint");
    //     require(_whiteList[msg.sender]>0, "Only whitelist can mint");
    //     require(_whiteList[msg.sender]>=_mint_amount, "Exceed whitelist amount");
    //     _whiteList[msg.sender]=_whiteList[msg.sender]-_mint_amount;

        
    //     _;
    // }
    modifier chekAndUpateFL(uint _mint_amount){

        require(_freeList[msg.sender]>0, "no free mint quota.");
        require(_freeList[msg.sender]>=_mint_amount, "Exceed free mint");
        
        _freeList[msg.sender]=_freeList[msg.sender]-_mint_amount;
        
        _;
    }

    function freeMint(uint _amount, bool _stake) public payable whenNotPaused chekAndUpateFL(_amount){
        require(msg.value == 0, "free!");
        specialMint(_amount, _stake);
    }

    // function whiteListMint(uint _amount, bool _stake) public payable whenNotPaused {

    //     require(_amount*whiteListMintPrice == msg.value, "Invalid payment amount");
    //     specialMint(_amount, _stake);
    // }

    function specialMint(uint _amount, bool _stake) internal{
        require(tx.origin == msg.sender, "Only EOA");
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_amount > 0 && _amount <= MINT_PER_TX_LIMIT, "Invalid mint amount");
        require(_availableTokens.length > 0, "All tokens for this Phase are already sold"); 
        tokensMinted += _amount;
        uint16[] memory tokenIds = _stake ? new uint16[](_amount) : new uint16[](0);
        for (uint i = 0; i < _amount; i++) {

            uint16 tokenId = getTokenToBeMinted();

            if (isQueen(tokenId)) {
                queenMinted += 1;
            }
            
            if (!_stake) {
                _safeMint(msg.sender, tokenId);
            } else {
                _safeMint(address(simpsOffice), tokenId);
                tokenIds[i] = tokenId;
            }
        }

        if (_stake) {
            simpsOffice.addTokensToStake(msg.sender, tokenIds);
        }
    }

    function mint(uint _amount, bool _stake) public payable whenNotPaused{
        require(tx.origin == msg.sender, "Only EOA");
        require(tokensMinted + _amount <= MAX_TOKENS, "All tokens minted");
        require(_amount > 0 && _amount <= MINT_PER_TX_LIMIT, "Invalid mint amount");
        require(_availableTokens.length > 0, "All tokens for this Phase are already sold");

        uint totalPennyCost = 0;
        
        if (phase == 0||phase == 1) {
            require(mintPrice(_amount) == msg.value, "Invalid payment amount");
        } else {
            // Mint via Penny token burn
            require(msg.value == 0, "Now minting is done via Penny");
            totalPennyCost = mintPrice(_amount);
            require(love.balanceOf(msg.sender) >= totalPennyCost, "Not enough Penny");
        }

        if (totalPennyCost > 0) {
            love.burn(msg.sender, totalPennyCost);
        }

        tokensMinted += _amount;
        uint16[] memory tokenIds = _stake ? new uint16[](_amount) : new uint16[](0);
        for (uint i = 0; i < _amount; i++) {
            address recipient = selectRecipient();
            if (phase != 1) {
                random.updateRandomIndex();
            }

            uint16 tokenId = getTokenToBeMinted();

            if (isQueen(tokenId)) {
                queenMinted += 1;
            }

            if (recipient != msg.sender) {
                isQueen(tokenId) ? queenStolen += 1 : simpStolen += 1;
                emit TokenStolen(msg.sender, tokenId, recipient);
            }
            
            if (!_stake || recipient != msg.sender) {
                _safeMint(recipient, tokenId);
            } else {
                _safeMint(address(simpsOffice), tokenId);
                tokenIds[i] = tokenId;
            }
        }
        if (_stake) {
            simpsOffice.addTokensToStake(msg.sender, tokenIds);
        }
    }

    function selectRecipient() internal returns (address) {
        if (phase == 0||phase == 1) {
            return msg.sender; // During ETH sale there is no chance to steal NTF
        }

        // 10% chance to steal NTF
        if (random.getSomeRandomNumber(queenMinted, 100) >= 10) {
            return msg.sender; // 90%
        }

        address thief = simpsOffice.randomQueenOwner();
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }

    function mintPrice(uint _amount) public view returns (uint) {
        return _amount * phasePrice[phase];
    }

    // function startAuction() public onlyOwner{
    //     auctionStartTimeStamp = block.timestamp;
    // }

    // function isAuction() internal view returns(bool result){
    //     if(auctionStartTimeStamp>0&&(block.timestamp - auctionStartTimeStamp)/ auctionInterval<= (auctionStartPrice - auctionEndPrice)/auctionPriceStep){
    //         return true;
    //     }else{
    //         return false;
    //     }
    // }

    // function getAuctionPrice() public view returns (uint price){
    //     if((block.timestamp - auctionStartTimeStamp)/ auctionInterval<= (auctionStartPrice - auctionEndPrice)/auctionPriceStep){
    //         return auctionStartPrice - auctionPriceStep*((block.timestamp - auctionStartTimeStamp)/ auctionInterval);
    //     }else{
    //         return auctionEndPrice;
    //     }
        
    // }

    // function getAuctionAmount (uint _amount) public view returns (uint) {
    //     if(isAuction()){
    //         //still in aution
    //        return  _amount * getAuctionPrice();
    //     }else{
    //         return _amount*auctionEndPrice;
    //     }
    // }

    function isQueen(uint16 id) public view returns (bool) {
        return _isQueen[id];
    }

    function getTokenToBeMinted() private returns (uint16) {
        uint rand = random.getSomeRandomNumber(_availableTokens.length, _availableTokens.length);
        
        uint16 tokenId = _availableTokens[rand];
        

        _availableTokens[rand] = _availableTokens[_availableTokens.length - 1];
        _availableTokens.pop();

        return tokenId;
    }
    

    function setQueenId(uint16 id, bool special) external onlyOwner {
        _isQueen[id] = special;
    }

    function setQueenIds(uint16[] calldata ids) external onlyOwner {
        for (uint i = 0; i < ids.length; i++) {
            _isQueen[ids[i]] = true;
        }
    }

    function setSimpsOffice(address _island) external onlyOwner {
        simpsOffice = ISimpsOffice(_island);
    }

    function setLove(address _love) external onlyOwner {
        love = ILLove(_love);
    }

    function setRandom(address _random) external onlyOwner {
        random = IRandom(_random);
    }

    function changePhasePrice(uint16 _phase, uint _weiPrice) external onlyOwner {
        phasePrice[_phase] = _weiPrice;
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        // Hardcode the Manager's approval so that users don't have to waste gas approving
        if (_msgSender() != address(simpsOffice))
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function totalSupply() public view override returns (uint) {
        return tokensMinted;
    }

    function _baseURI() internal view override returns (string memory) {
        return _apiURI;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _apiURI = uri;
    }



    function withdraw(address to) external onlyOwner {
        uint balance = address(this).balance;
        payable(to).transfer(balance);
    }
}




