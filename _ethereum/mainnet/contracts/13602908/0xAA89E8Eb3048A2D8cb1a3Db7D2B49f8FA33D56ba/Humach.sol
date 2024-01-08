// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Owner.sol";
import "./ERC721Enumerable.sol";
import "./IMachinie.sol";
import "./IERC20.sol";

contract Humach  is ERC721Enumerable, Ownable
{
    using Strings for uint256;
    mapping(uint256 => uint256)private level;
    mapping(uint256 => uint256) private exp;
    mapping(uint256 => uint256) private stakeTime;
    mapping(address => uint8) private whiteListsMints;
    mapping(address => bool) private whiteLists;
    mapping(uint256 => uint256) breedFee;
    mapping(uint256 => string) private idName;
    mapping(uint256 => string) private idDescription; 
    
    address private machinieOld = 0xE6d3e488b9D31943dF6e3B7d82f6F842679a1a8c;
    address private blackHole = 0x000000000000000000000000000000000000dEaD;
    
    address private machinieNew = 0xB826bDe739897ad50363d045d65eE5b83FDb730d ; 
    address private floppy = 0x9F3dDF3309D501FfBDC4587ab11e9D61ADD3126a;    

    uint256 private tokenId = 888; 
    uint256 private mintFee = 0.068 ether;
    uint256 private changeNameFee = 35 ether;
    uint256 private changeDescFee = 35 ether;
    uint256 private maximumMintAmount = 2562; 
    uint256 private maximumBreedAmount = 5388;
    uint256 private upgradeAmount;
    uint256 private totalMintFee;
    uint256 private mintAmount ; 
    uint256 private breedAmount  ;
    uint256 private maxSupply = 8888;
    uint256 private expPerLevel =10;
    uint256 private minStakeForExp = 86400;
    uint256 private maxLevel = 5;
    uint256 private tOpenWhiteLists = 1637024400; // Tue Nov 16 2021 08:00:00 GMT+0700
    uint256 private tCloseWhiteLists = 1637197200; // Thu Nov 18 2021 08:00:00 GMT+0700
    uint256 private tOpenPublicMint = 1637197200; // Thu Nov 18 2021 08:00:00 GMT+0700
    uint8 private maximunMintPerTransaction =3;
    uint8 private maximumWhiteListsMint = 2; 
    uint16 private maximumNameLength = 20;
    uint16 private maximumDescLength = 300;
    bool private enableStake;
    string private uri = "https://api.machinienft.com/api/humach/unrevealed/";
    
    constructor() ERC721("Humach", "Humach")
    {
        breedFee[0] = 8888 ether;
        breedFee[1] = 170 ether;
        breedFee[2] = 165 ether;
        breedFee[3] = 160 ether;
        breedFee[4] = 155 ether;
        breedFee[5] = 150 ether;

        _worker[machinieNew] = true;
        _admin[0x714FdF665698837f2F31c57A3dB2Dd23a4Efe84c] = true;


    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Humach: URI query for nonexistent token tokenId");
        (uint256 _level, )= calculateLevel(tokenId_);
        require(_level != 0 ,"Humach: abnormal Level" );
        uint256 _imgId = ((_level - 1 ) * maxSupply ) + tokenId_;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _imgId.toString())) : "";
    }

    function machinieUpgrade(uint256 tokenId_ ) external returns (uint256) {
        require(IERC721(machinieOld).ownerOf(tokenId_) == _msgSender() , "Humach : owner query for nonexistent machinie token");
        require(IERC721(machinieOld).isApprovedForAll(_msgSender(), address(this)), "Humach : Need approve this address for All");
        IERC721(machinieOld).safeTransferFrom(_msgSender(), blackHole, tokenId_);
        _safeMint(_msgSender(), tokenId_);
        IMachinie(machinieNew).mintMachinie( _msgSender(),tokenId_);
        level[tokenId_] = 1;
        upgradeAmount++;
        return tokenId_;
    }

    function machiniesUpgrade(uint256[] memory tokenIds_ ) external  {
        require(IERC721(machinieOld).isApprovedForAll(_msgSender(), address(this)), "Humach : Need approve this address for All");
        for(uint _i =0; _i< tokenIds_.length; _i++)
        {
            require(IERC721(machinieOld).ownerOf(tokenIds_[_i]) == _msgSender() , "Humach : owner query for nonexistent machinie token");          
            IERC721(machinieOld).safeTransferFrom(_msgSender(), blackHole, tokenIds_[_i]);
            _safeMint(_msgSender(), tokenIds_[_i]);
            IMachinie(machinieNew).mintMachinie( _msgSender(),tokenIds_[_i]);
            level[tokenIds_[_i]] = 1;
            upgradeAmount++;
        }
    }

    function whiteListsMintHumach(uint8 amount_ ) external payable returns (uint256 [] memory){
        require(block.timestamp >= tOpenWhiteLists, "Humach : is not available period");
        require(block.timestamp <= tCloseWhiteLists, "Humach : is not available period");
        require(whiteLists[_msgSender()], "Humach : you are not in whiteLists");
        require(whiteListsMints[_msgSender()] + amount_ <= maximumWhiteListsMint, "Humach : already use whiteLists Mint Humach");
        require(msg.value >= (mintFee * amount_), "Humach : mintFee is not enought");
        require((mintAmount + amount_ ) <=  maximumMintAmount, "Humach : is over maxSupply");

        uint256 [] memory _id = new uint256 [](amount_);
        for(uint8 _i=0; _i< amount_; _i++){
            _id[_i] = tokenId;
            tokenId++;
            _safeMint(_msgSender(), _id[_i]);
            level[_id[_i]] = 1;            
        }
        totalMintFee = totalMintFee + msg.value;
        mintAmount =  mintAmount + amount_;
        whiteListsMints[_msgSender()] = whiteListsMints[_msgSender()] + amount_;
        return _id;
    }

    function publicMintHumach(uint8 amount_) external payable returns (uint256 [] memory){
        require(amount_ <= maximunMintPerTransaction , "Humach : over Maximum min per transaction");
        require(block.timestamp >= tOpenPublicMint, "Humach : is not available period");
        require(msg.value >= (mintFee *amount_) , "Humach : mintFee is not enought");
        require((mintAmount + amount_) <=  maximumMintAmount, "Humach : is over maxSupply");

        uint256 [] memory _id = new uint256 [](amount_);
        for(uint8 _i=0; _i< amount_; _i++){
            _id[_i] = tokenId;
            tokenId++;
            _safeMint(_msgSender(), _id[_i]);
            level[_id[_i]] = 1;
        }
        totalMintFee = totalMintFee + msg.value;
        mintAmount =  mintAmount + amount_;
        return _id;

    }
    
    function giveAway(address account_, uint8 amount_) external  onlyAdmin returns (uint256 [] memory){
        require((mintAmount + amount_)  <=  maximumMintAmount, "Humach :  is over mint capacity");
        uint256 [] memory _id = new uint256 [](amount_);
        for(uint8 _i=0; _i< amount_; _i++){
            _id[_i] = tokenId;
            tokenId++;
            _safeMint(account_, _id[_i]);
            level[_id[_i]] = 1;
        }
        mintAmount =  mintAmount + amount_;
        return _id;
    }

    function breedHumach(uint256 tokenId_) external returns (uint256){
        require(ownerOf(tokenId_) == _msgSender() , "Humach : owner query for nonexistent Humach token");
        require(breedAmount <  maximumBreedAmount, "Humach : is over Breed capacity");
        uint256 _level = level[tokenId_];
        uint256 _fee = breedFee[_level];
        require(_fee !=0 ,"Humach : breedFee Problem" );
        require(IERC20(floppy).balanceOf(_msgSender()) >= _fee, "Humach : balanceOf Floppy is not enought");
        require(IERC20(floppy).allowance(_msgSender(), address(this)) >= _fee, "Humach : allowance Floppy is not enought");

        IERC20(floppy).transferFrom(_msgSender(), blackHole, _fee);
        uint256 _tokenId = tokenId;
        tokenId++;
        _safeMint(_msgSender(), _tokenId);
        level[_tokenId] = 1;
        breedAmount++;

        return(_tokenId);
    } 

    function stakeHumach (uint256 [] memory tokenIds_) external {
        require(enableStake, "Humach : Stake function is disable");
        for(uint8 _i=0; _i< tokenIds_.length; _i++)
        {
            require(ownerOf(tokenIds_[_i]) == _msgSender() , "Humach : owner query for nonexistent Humach token");
            require(!staking[tokenIds_[_i]], "Humach : HumachID is staking");
            stakeTime[tokenIds_[_i]] = block.timestamp;
            staking[tokenIds_[_i]] = true;
        }

    }

    function unStakeHumach (uint256 [] memory tokenIds_) external {
        for(uint8 _i=0; _i< tokenIds_.length; _i++)
        {
            require(ownerOf(tokenIds_[_i]) == _msgSender() , "Humach : You are not owner of this tokenId");
            require(staking[tokenIds_[_i]], "Humach : HumachID is staking");
            require(stakeTime[tokenIds_[_i]] !=0, "Humach: is staking with Machinie" );
        
            (uint256 _level, uint256 _exp) = calculateLevel(tokenIds_[_i]);
            level[tokenIds_[_i]] =_level;
            exp[tokenIds_[_i]] =_exp;
            staking[tokenIds_[_i]] = false;
            stakeTime[tokenIds_[_i]] = 0;
        }


    }

    function calculateLevel(uint256 tokenId_) public view returns(uint256,uint256){
        if(stakeTime[tokenId_] == 0)
            return (level[tokenId_],exp[tokenId_]);
        uint256 _tStake = block.timestamp - stakeTime[tokenId_];
        uint256 _addExp = _tStake / minStakeForExp;
        uint256 _lastExp = (level[tokenId_] * expPerLevel) + exp[tokenId_];
        uint256 _newExp = _lastExp + _addExp;
        uint256 _maxExp = maxLevel * expPerLevel;
        if(_newExp >= _maxExp )
            return (maxLevel,0);
        uint256 _level = _newExp / expPerLevel;
        uint256 _exp = _newExp % expPerLevel;
        return (_level,_exp);
    }

    function updateWhiteLists(address [] memory account_, bool status_) external onlyAdmin{
        for(uint _i =0; _i<account_.length; _i++)
        {
            whiteLists[account_[_i]] = status_;
        }
    }

    function updateTokenName (uint256 tokenId_ ,string memory name_ ) external  {
        require(ownerOf(tokenId_) == _msgSender() , "Humach : owner query for nonexistent Humach token");
        require(IERC20(floppy).balanceOf(_msgSender()) >= changeNameFee, "Humach : BalanceOf Floppy is not enought");
        require(IERC20(floppy).allowance(_msgSender(), address(this)) >= changeNameFee, "Humach : allowance Floppy isnot enought");
        require(bytes(name_).length <= maximumNameLength, "Humach : Name length is over Limit");

        IERC20(floppy).transferFrom(_msgSender(), blackHole, changeNameFee);
        idName[tokenId_] = name_;
        emit changeName(tokenId_ , name_, idDescription[tokenId_]);
    }

    function updateTokenDescription (uint256 tokenId_  ,string memory description_ ) external  {
        require(ownerOf(tokenId_) == _msgSender() , "Humach : owner query for nonexistent Humach token");
        require(IERC20(floppy).balanceOf(_msgSender()) >= changeDescFee, "Humach : BalanceOf Floppy is not enought");
        require(IERC20(floppy).allowance(_msgSender(), address(this)) >= changeDescFee, "Humach : allowance Floppy isnot enought");
        require(bytes(description_).length <= maximumDescLength, "Humach : Description length is over Limit");

        IERC20(floppy).transferFrom(_msgSender(), blackHole, changeDescFee);
        idDescription[tokenId_] = description_;
        emit changeName(tokenId_ , idName[tokenId_], description_);
    }
   
    function burnHumach(uint256 tokenId_) external {
        require(ownerOf(tokenId_) == _msgSender() , "Humach : You are not owner of this tokenId");
        _burn(tokenId_);
    }

    function updateEnableStake(bool status_) external onlyAdmin{
        enableStake = status_;
    }

    function updateStakStatus(uint256 tokenId_,bool status_) external onlyWorker{
        staking[tokenId_] = status_;
    }

    function updateMintFee(uint256 amount_) external onlyAdmin{
        mintFee = amount_;
    }

    function updateBreedFee (uint256 level_ , uint256 fee_) external onlyAdmin{
        breedFee[level_] = fee_ ;
    }

    function updateChangeNameFee(uint256 changeName_,uint256 changeDesc_) external onlyAdmin{
        changeNameFee = changeName_;
        changeDescFee = changeDesc_;
    }

    function updateMintPerTranaction (uint8 amount_ )external onlyAdmin{
        maximunMintPerTransaction = amount_;
    }
    function updateExpParameter (uint256 expPerLevel_ , uint256 minStakeForExp_ ,uint256 maxLevel_ ) external onlyAdmin {
        expPerLevel = expPerLevel_;
        minStakeForExp = minStakeForExp_;
        maxLevel = maxLevel_;
    }

    function updateMaximumMint(uint256 amount_)external onlyAdmin{
        maximumMintAmount = amount_;
    }

    function updateMaximumBreed(uint256 amount_)external onlyAdmin{
        maximumBreedAmount = amount_;
    }

    function updateProjectTime (uint256 openWhiteLists_ ,uint256 closeWhiteLists_,uint256 openPublic_ ) external onlyAdmin {
        tOpenWhiteLists = openWhiteLists_;
        tCloseWhiteLists = closeWhiteLists_;
        tOpenPublicMint = openPublic_;
    }

    function updateLevel(uint256 [] memory tokenId_, uint256  level_) external onlyAdmin{
        for(uint _i =0; _i<tokenId_.length; _i++)
        {
            level[tokenId_[_i]] = level_;
        }
    }
    function updateNameLength (uint16 nameLength_, uint16 descLength_) external onlyAdmin{
        maximumNameLength = nameLength_;
        maximumDescLength = descLength_;
    }

    function updateContractMachinieOld (address newContract) external onlyOwner {
        machinieOld = newContract;
    }

    function updateContractMachinie (address newContract) external onlyOwner {
        machinieNew = newContract;
    }

    function updateContractFloppy (address newContract) external onlyOwner {
        floppy = newContract;
    }

    function updateBaseURI(string memory baseURI_)external onlyOwner{
        uri = baseURI_;
    }

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    function withdraw(uint256 amount_) external payable onlyOwner {
        require(payable(msg.sender).send(amount_));
    }   

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function isStaking (uint256 tokenId_) external view returns(bool){
        return staking[tokenId_];
    }

    function getStakeTime (uint256 tokenId_) external view returns (uint256){
        return stakeTime[tokenId_];
    }

    function isWhiteLists (address account_) external view returns(bool){
        return whiteLists[account_];
    }

    function getMintFee(uint256 amount_) external view returns(uint256){
        return mintFee*amount_;
    }

    function getBreedHumachFee(uint256 tokenId_) external view  returns (uint256){
        return breedFee[level[tokenId_]];
    }  

    function  getChangeDataFee() external view returns (uint256,uint256){
        return (changeNameFee,changeDescFee);       
    }

    function getUpgradeAmount ()external view returns (uint256){
        return upgradeAmount;
    }
    
    function getTotalMintFee ()external view returns (uint256){
        return totalMintFee;
    }

    function getMintAmount ()external view returns (uint256){
        return mintAmount;
    }

    function getBreedAmount ()external view returns (uint256){
        return breedAmount;
    }

    function getTokenIdName(uint256 tokenId_) external view returns(string memory, string memory){
        return(idName[tokenId_],idDescription[tokenId_]);
    }

    function getEnableStake() external view returns (bool){
        return enableStake;
    }

    function getWhiteListminted(address account_) external view returns(uint8) {
        return whiteListsMints[account_];
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 _i; _i < tokenCount; _i++){
            tokensId[_i] = tokenOfOwnerByIndex(_owner, _i);
        }
        return tokensId;
    }

    function getMintPerTranaction ( )external view returns(uint8){
        return maximunMintPerTransaction;
    }

    function getExpParameter () external view returns(uint256,uint256,uint256) {
        return (expPerLevel,minStakeForExp,maxLevel);
    }

    function getNameLength () external view returns(uint16,uint16) {
        return (maximumNameLength,maximumDescLength);
    }

    function getTokenId() external view returns(uint256){
        return tokenId;
    } 

    function getProjectTime () external view returns(uint256,uint256,uint256){
        return(tOpenWhiteLists,tCloseWhiteLists,tOpenPublicMint);
    }

    function getContractMachinieOld() external view returns(address){
        return machinieOld;
    }

    function getContractMachinie() external view returns(address){
        return machinieNew;
    }
    
    function getContractFloppy() external view returns(address){
        return floppy;
    }

    event changeName(uint256 tokenId_ , string  name_, string  description_);
    
    receive() external payable{
        
    }

}