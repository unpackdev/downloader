// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19 <0.8.5;
import "./ERC721.sol";
import "./Ownable.sol";

contract CMC is ERC721, Ownable { 

    event NewAsset(uint id, Asset asset);
    event BoosterOpened(address owner,uint qty);
    event Giveaway(address luckGuy);

    struct Asset {
        uint256 assetId;
        uint256 birth;
        uint256 rand;
    }

    struct ContractOwners {
        address payable addr;
        uint percent;
    }

    Asset[] public assets;
    string internal baseTokenURI = 'https://api.cryptomarket.cards/asset/';
    uint boosterPrice = 0.02 ether;
    uint boosterUnits = 4;
    ContractOwners[] contractOnwers;
    uint initialSupply = 2000 * boosterUnits;

     modifier canBuy(uint _qty){
        require(msg.value == (boosterPrice * _qty), "Insuficient funds");
        _;
    }

    modifier hasQuantity(uint _qty){
        require(_qty > 0, "Booster units must be greater than 0");
        _;
    }

    modifier hasAssets(uint _qty){
        require(initialSupply == 0 || (_qty * boosterUnits) <= initialSupply, "You cannot buy more than pre-sale supply");
        _;
    }

    modifier canWithdraw(){
        require(address(this).balance > 1, "this account doesn't have enough balance");
        _;
    }

    constructor() ERC721("CryptoMarketCards", "CMC") {
        contractOnwers.push(ContractOwners(payable(address(0xcce56Ca550D764539FB39a5d13Ddfa6F528eCE7b)), 2375)); // n
        contractOnwers.push(ContractOwners(payable(address(0x6DAA3d177a78327B1B35977B39747034add6007c)), 2375)); // l
        contractOnwers.push(ContractOwners(payable(address(0x24BdA6432Fb2CBfeDab31C86B9cAf02Dffe4Ba8E)), 2375)); // a
        contractOnwers.push(ContractOwners(payable(address(0x41Cf0afB4056e27DEcA21F7AdC7B3ADa41868841)), 2375)); // k
        contractOnwers.push(ContractOwners(payable(address(0xB43623DAEDF0d03a23646b3Fd145F1eb842F1a2b)), 500)); // f
    }

    function withdraw() external payable onlyOwner canWithdraw {
        uint nbalance = address(this).balance - 0.01 ether;
        for(uint i = 0; i < contractOnwers.length; i++){
            ContractOwners storage o = contractOnwers[i];
            o.addr.transfer((nbalance * (o.percent/100)) / 100);       
        }
    }

    function balance() external view onlyOwner returns (uint)  {
        return address(this).balance;
    }

    function setBoosterPrice(uint _fee) external onlyOwner {
        boosterPrice = _fee;
    }

    function setBoosterUnits(uint _units) external onlyOwner {
        boosterUnits = _units;
    }

    function getBoosterPrice() external view returns (uint){
        return boosterPrice;
    }

    function getBoosterUnits() external view returns (uint){
        return boosterUnits;
    }

    function getInitialSupply() external view returns (uint){
        return initialSupply;
    }

    function setInitialSupply(uint supply) external onlyOwner {
        initialSupply = supply;
    }

    function getAssetsIdsByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < assets.length; i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getAsset(uint _id) external view returns(Asset memory){
        return assets[_id];
    }

    function getAssetsCount() external view returns(uint){
        return assets.length;
    }

    function getAssetsByOwner() external view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(msg.sender));
        uint counter = 0;
        for (uint i = 0; i < assets.length; i++) {
            if (ownerOf(i) == msg.sender) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getMyAssets() external view returns(Asset[] memory) {
        Asset[] memory result = new Asset[](balanceOf(msg.sender));
        uint counter = 0;
        for (uint i = 0; i < assets.length; i++) {
            if (ownerOf(i) == msg.sender) {
                result[counter] = assets[i];
                counter++;
            }
        }
        return result;
    }


    function openBoosterAndMint(uint _qty) external payable canBuy(_qty) hasQuantity(_qty) hasAssets(_qty) {
        uint i = 0;
        while(i < (boosterUnits * _qty)){
            createAndMint(msg.sender);
            i++;
        }
        emit BoosterOpened(msg.sender, i);
    }

    function giveaway(address _to) external onlyOwner {
        uint i = 0;
        while(i < boosterUnits){
            createAndMint(_to);
            i++;
        }
        emit Giveaway(_to);
    }


    function createAndMint(address _address) internal {
        uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender, assets.length)));
        uint tokenId = assets.length;
        Asset memory asset = Asset(tokenId, block.timestamp, rand % (10 ** 16));
        assets.push(asset);
        _mint(_address, tokenId);
    }

    //ERC-721 functions

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function totalSupply() public view returns (uint){
        if(assets.length > initialSupply){
            return assets.length;
        }
        return initialSupply;
    }

}