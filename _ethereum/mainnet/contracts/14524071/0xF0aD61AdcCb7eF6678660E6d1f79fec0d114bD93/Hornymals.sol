// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ISlave.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./StringsUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./Club.sol";

contract Hornymals is ERC721EnumerableUpgradeable,   OwnableUpgradeable,Club, UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    //using SafeMathUpgradeable for uint256;

    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant MAX_MINTS = 5;
    uint256 public price;
    uint256 public presalePrice;
    uint256 public reserved;
    uint256 private randNonce;
    uint256 public startingIndex;
    bytes32 public merkleRoot;
    address public artistAddress;
    uint8 public season;
    uint8 public extraStars;
    uint8 public startingStars;
    bool public saleActive;
    bool public presaleActive;
    address  public stardustTokenAddress;
    address public slaveContractAddress;
    string public baseURI;
    string public PROVENANCE;
    mapping(uint256 => uint8) private _stars;
    mapping(uint256 => uint8) private _breedInfo;
    mapping(address => uint256) private _lastMintInterval;



    function initialize(address stardustToken) initializer public{
        stardustTokenAddress = stardustToken;
        price = 0.069 ether;
        presalePrice = 0.069 ether;
        baseURI = "https://hornymals.com/";
        PROVENANCE="f5a3778c8063a695783e424341c12c30f81d755b737533a53eb672deb653dce1";
        __ERC721_init("Hornymals", "Hornymals");
        __ERC721Enumerable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _safeMint(msg.sender, 0);
    }
    function setArtist(address _artistAddress)public onlyOwner{
        artistAddress = _artistAddress;
    }
    function mint(uint256 _nbTokens) external payable {
        require(saleActive, "Sale not active");
        require(msg.sender == tx.origin, "Can't mint through another contract");
        uint256 currentMaxMints = (startingStars==0) ? MAX_MINTS: 1;
        require(_nbTokens <= currentMaxMints, "Exceeds max token purchase.");
        uint256 supply = totalSupply();
        require(supply + _nbTokens <= MAX_SUPPLY - reserved, "Not enough Tokens left.");
        require(_nbTokens * price <= msg.value, "Sent incorrect ETH value");
        for (uint256 i=0; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply +i);
            if(startingStars>0){
                _stars[supply+i] = startingStars;
            }
            if(startingStars==5){
                _addMember(supply+i);
            }
        }
    }
    function preMint(bytes32[] calldata _proof, uint256 _nbTokens) external payable{
        require(presaleActive, "Presale not active");
        require(msg.sender == tx.origin, "Can't mint through another contract");
        uint256 currentMaxMints = (startingStars==0) ? MAX_MINTS: 1;
        require(_nbTokens <= currentMaxMints, "Exceeds max token purchase.");
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_proof, merkleRoot, node), "Not on allow list");
        uint256 mintInterval = (startingStars==0) ? 10:(6-startingStars);
        uint256 myLastMintInterval = _lastMintInterval[msg.sender];
        require(myLastMintInterval + _nbTokens<= mintInterval, "Exceeds mint limit");
        uint256 supply = totalSupply();
        require(supply + _nbTokens <= MAX_SUPPLY - reserved, "Not enough Tokens left.");
        require(presalePrice * _nbTokens <= msg.value, "Sent incorrect ETH value");
        if(myLastMintInterval<5){
            myLastMintInterval=5;
        }
        _lastMintInterval[msg.sender] = mintInterval<6? mintInterval : myLastMintInterval+_nbTokens;
        for (uint256 i=0; i < _nbTokens; i++) {
            _safeMint(msg.sender, supply +i);
            if(startingStars>0){
                _stars[supply+i] = startingStars;
            }
            if(startingStars==5){
                _addMember(supply+i);
            }
        }
    }
    function starsOfToken(uint256 tokenId) public view returns (uint8){
        require(_exists(tokenId), "Stars: query for nonexistent token");
        return  _stars[tokenId];
    }
    function usedBreeds(uint tokenId) public view returns(uint8){
        require(_exists(tokenId), "Breeds: query for nonexistent token");
        uint8 myBreeds = _breedInfo[tokenId];
        return myBreeds%10;
    }
    function breedInfo(uint256 tokenId)public view returns(uint8){
        require(_exists(tokenId), "Breeds: query for nonexistent token");
        return _breedInfo[tokenId];
    }
    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
        if(presaleActive && saleActive){
            saleActive=false;
        }
    }
    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
        if(saleActive && presaleActive){
            presaleActive = false;
        }
    }
    function setSeason(address slaveAddress , uint8 newSeason, uint8 newExtraPrice) external artistOrOwner {
        season = newSeason;
        slaveContractAddress = slaveAddress;
        extraStars = newExtraPrice;
    }
    function buyStars(uint256 tokenId, uint8 starsToBuy) public {
        address  from = msg.sender;
        require(ownerOf(tokenId) == from, "You are not the owner of the Hornymal");
        require(starsOfToken(tokenId) + starsToBuy <=5, "Cant buy that many stars");
        uint256 amount =  starsToBuy *100e18;
        require(IERC20(stardustTokenAddress).allowance(from, address(this)) >= amount , "First, approve more stardust to this contract!");
        IERC20(stardustTokenAddress).transferFrom(from, address(this),amount);
        _stars[tokenId] +=starsToBuy;
        if(_stars[tokenId]>=5){
            _addMember(tokenId);
        }

    }
    function buyStarsMultiple(uint256[] calldata tokenIds, uint8[] calldata numberOfStars) public{
        address  from = msg.sender;
        uint256 amount=0;
        for(uint256 index=0;index<tokenIds.length;index++){
            require(ownerOf(tokenIds[index]) == from, "You are not the owner of all the Hornymals");
            require(_stars[tokenIds[index]]+numberOfStars[index]<=5,"Not more than five stars");
            amount += numberOfStars[index];
        }
        amount = amount*100e18;
        require(IERC20(stardustTokenAddress).allowance(from, address(this)) >= amount , "First, approve more stardust to this contract!");
        IERC20(stardustTokenAddress).transferFrom(from, address(this),amount);
        for(uint256 index=0;index<tokenIds.length;index++){
            _stars[tokenIds[index]] +=numberOfStars[index];
            if(_stars[tokenIds[index]]==5){
                _addMember(tokenIds[index]);
            }
        }
}
    function fillUpStars(uint256[] calldata tokenIds) public {
        address  from = msg.sender;
        uint amount=0;
        for(uint256 index=0;index<tokenIds.length;index++){
            require(ownerOf(tokenIds[index]) == from, "You are not the owner of the Hornymal");
            amount += 5-_stars[tokenIds[index]];
        }
        amount =amount *100e18;
        require(IERC20(stardustTokenAddress).allowance(from, address(this)) >= amount , "First, approve more stardust to this contract!");
        IERC20(stardustTokenAddress).transferFrom(from, address(this),amount);
        for(uint256 index=0;index<tokenIds.length;index++){
            _stars[tokenIds[index]]=5;
            _addMember(tokenIds[index]);
        }
    }
    function drawWinner() public artistOrOwner{
        uint256 mp=numberOfMembers();
        require(mp>0 ,"No members in club");
        uint256 clubIndex = pseudoRandom(mp);
        uint256 tokenId =getMemberByIndex(clubIndex);
        address winner= ownerOf(tokenId);
        uint256 supply = totalSupply();
        _safeMint(winner, supply);
        reserved --;
        emit LotteryWin(winner, supply);
    }



    function setBaseURI(string memory _URI) external onlyOwner{
        baseURI = _URI;
    }
    function setStardustToken(address stardustAddress) external onlyOwner {
        stardustTokenAddress = stardustAddress;
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns(string memory) {
        return baseURI;
    }

    function setPrice(uint256 _newPrice) external artistOrOwner {
        price = _newPrice;
    }
    function setPresalePrice(uint256 _newPresalePrice) external artistOrOwner {
        presalePrice = _newPresalePrice;
    }



    function withdraw() public artistOrOwner {
        uint256 balance = address(this).balance;
        uint256 split = balance/10;
         require(artistAddress!=address(0), "Set an artist address!");
        require(payable(owner()).send(split), "owner not payable");
        require(payable(artistAddress).send(balance-split), "artist not payable");
    }
    function withdrawTokens() public onlyOwner {
        uint256 balance = IERC20(stardustTokenAddress).balanceOf(address(this));
        IERC20(stardustTokenAddress).transfer(msg.sender, balance);
    }



    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721EnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function tokenURI(uint256 tokenId) public view
    override(ERC721Upgradeable)
    returns (string memory){
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //string memory _baseURI = _baseURI();
        uint myStars = starsOfToken(tokenId);
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, myStars.toString(),"/",tokenId.toString())) : "";
    }

    function breed(uint256 parentOneId, uint256 parentTwoId) external{
        require( season == 1, "This is not the breeding-season");
        require(msg.sender == ownerOf(parentOneId) && msg.sender == ownerOf(parentTwoId), "You are not the owner");

        uint8 usedOne= _breedInfo[parentOneId]%10;
        require(usedOne<5, "Parent one cant breed anymore");
        uint8 usedTwo = _breedInfo[parentTwoId]%10;
        require(usedTwo<5, "Parent two cant breed anymore");
        uint8 starsOne = _stars[parentOneId];//starsOfToken(parentOneId);
        uint8 priceOne = usedOne +1;
        require(starsOne>=priceOne , "Parent one has not enough star");
        if(starsOne==5){
           _removeMember(parentOneId);
        }
        uint8 starsTwo = _stars[parentTwoId];//tokenId]starsOfToken(parentTwoId);
        uint8 priceTwo = usedTwo+1;
        require(starsTwo>=priceTwo, "Parent two has not enough star");
        if(starsTwo==5){
            _removeMember(parentTwoId);
        }

        uint256 rnd = pseudoRandom(2);
            if(rnd == 0){
                ISlave(slaveContractAddress).masterMint(msg.sender,parentOneId, _breedInfo[parentOneId] );
                _breedInfo[parentOneId]+=11;
                _breedInfo[parentTwoId]++;

            }
        else{
                ISlave(slaveContractAddress).masterMint(msg.sender, parentTwoId,  _breedInfo[parentTwoId]);
                _breedInfo[parentOneId]++;
                _breedInfo[parentTwoId]+=11;
            }
    _stars[parentOneId] -=priceOne;
    _stars[parentTwoId] -=priceTwo;

     }

    function pseudoRandom(uint256 moduloParameter) internal returns(uint256)
    {
        // increase nonce
        randNonce++;

        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % moduloParameter;
    }


    function useOffer(uint256 tokenId) external{
        require(season>1, "There is not any suitable offers available at the moment");
        require(msg.sender == ownerOf(tokenId) , "You are not the owner");
        uint8 stars = starsOfToken(tokenId);
        uint8 starsToUse = 1+ extraStars;

        require(stars>= starsToUse, "The Hornymal has not enough star");
        if(stars==5){
            _removeMember(tokenId);
        }
        ISlave(slaveContractAddress).masterMint(msg.sender, tokenId, 0);
        _stars[tokenId] = _stars[tokenId] -starsToUse;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal  override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }



    function _authorizeUpgrade(address) internal override onlyOwner{

    }
    modifier artistOrOwner(){
        require(artistAddress == _msgSender() || owner() ==_msgSender(), "Caller is not artist or owner");
        _;
    }
    function setStartingIndex() public onlyOwner{
        require(startingIndex == 0, "Starting index is already set");
        startingIndex = pseudoRandom(MAX_SUPPLY);
       // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex ++;
        }
    }
    function setMerkleRootStartingStarsAndReserved(bytes32 _merkleRoot, uint8 _startingStars, uint256 _reserved) external onlyOwner {
        merkleRoot = _merkleRoot;
        startingStars = _startingStars;
        reserved = _reserved;
    }

}




