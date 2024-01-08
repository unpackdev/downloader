//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./console.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";
import "./ERC721Enumerable.sol";

interface PandaPartyItems{
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function itemType(uint256 id) external view returns (uint256);
    function burn(address account, uint256 id, uint256 value) external;
}
contract PandaParty is ERC721Enumerable, VRFConsumerBase, Ownable {
    using SafeMath for uint256;
    bool public isMintingActive = false;
    uint256 public price; 
    uint256 constant public _maxSupply = 7777;
    string internal baseURI;
    string public IPFSHASH = "QmU5pWKHB3sJMLuqEwoBX5mPtybgkTkbCQomfy43CTSa4F";
    address payable internal multisig;
    uint256[_maxSupply] public pandas;

    uint256[6][_maxSupply] public customPandas;
    uint256[_maxSupply * 2] public pandaBuddies;
    PandaPartyItems public pandaPartyItems;
    string internal baseURICustom;
    bool itemsLocked = false;

    string [_maxSupply * 2] public pandaNames;

    bytes private prevHash;
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal linkRNG = 0;

    uint256[][] public partQuantites =[
        [1000,2000,3000,4000,5000,5162,5325,5809,6293,6777,7777,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000],
        [5000,7000,7777,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000],
        [2325,4650,6975,7277,7777,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000],
        [350, 990,1540,1890,2240,3590,4240,4290,4320,5670,6227,6677,7227,7777,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000], //mouth
        [166,405,571,676,696,935,1174,1340,1533,1772,2011,2306,2601,2896,3191,3486,3781,4076,4269,4508,4747,4913,5107,5301,5494,5688,5927,6121,6315,6509,6702,6996,7162,7328,7348,7449,7550,7777,10000], //hair
        [275,625,875,1125,1675,2225,2277,2552,3102,3752,4602,4877,5727,6577,7227,7677,7777,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000,10000] //eyes
    ];
    constructor(
        string memory _baseURI,
        uint256 _price,
        address payable _multisig
    ) 
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
        0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
    )
    ERC721(
        "Panda Party",
        "PANDA"
    ) public {
        baseURI = _baseURI;
        price = _price;
        multisig = _multisig;
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; 
 
    }

    // panda names n stuff

    function setName(uint256 tokenId, string memory name) public {
        require(ownerOf(tokenId) == msg.sender, "... this aint you");
        require(bytes(name).length < 50, "that wont fit on the nametag...");
        pandaNames[tokenId] = name;

    }
    function viewName(uint256 tokenId) public view returns (string memory) {
        return pandaNames[tokenId];
    }

    // custom panda stuff

    function setCustomPandaContract(address _contract, string memory _uri) public onlyOwner {
        require(itemsLocked == false, "on no, we locked the door");
        pandaPartyItems = PandaPartyItems(_contract);
        baseURICustom = _uri;
        itemsLocked = true;
    }

    function claimBlankPanda(uint256 tokenId) public {
        require(itemsLocked == true, "not yet friend");
        require(ownerOf(tokenId) == msg.sender, "thats not the secret password");
        require(pandaBuddies[tokenId] == 0, "Your buddies already here");
        require(tokenId < _maxSupply, "idk wtf you tryna do");
        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        pandaBuddies[tokenId] = mintIndex;
        pandaBuddies[mintIndex] = tokenId;
    }

    function attachItem(uint256 tokenId, uint256 itemId) public {
        require(ownerOf(tokenId) == msg.sender, "thats not the secret password");
        require(pandaPartyItems.balanceOf(msg.sender, itemId) > 0, "thats not the secret password");
        uint256 itemType = pandaPartyItems.itemType(itemId);
        pandaPartyItems.burn(msg.sender, itemId, 1);
        customPandas[tokenId - _maxSupply][itemType] = itemId; 
    }
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        linkRNG = randomness;
        prevHash = abi.encodePacked(randomness);
    }
    function getLinkRNG() public view returns (uint256 number) {
        return linkRNG;
    }
    function getPanda(uint256 panda) public view returns (uint256 background, uint256 body, uint256 neck, uint256 mouth, uint256 hair, uint256 eyes) {
        if(panda >= _maxSupply){
            uint256 _id = panda - _maxSupply;
            return(customPandas[_id][0], customPandas[_id][1], customPandas[_id][2], customPandas[_id][3], customPandas[_id][4], customPandas[_id][5]);
        }
        else { 
            uint256 _seed = pandas[panda];
            uint256 _eyes = 0;
            uint256 _hair = 0;
            uint256 _mouth = 0;
            uint256 _neck = 0;
            uint256 _body = 0;
            uint256 _background = 0;

            for(uint256 i; i < partQuantites[0].length; i++){
                if(_seed % 7777 < partQuantites[0][i]){
                    _background = i;
                    break;
                }
            }
            _seed = _simpleRng(_seed);

            for(uint256 i; i < partQuantites[1].length; i++){
                if(_seed % 7777 < partQuantites[1][i]){
                    _body = i;
                    break;
                }
            }
            _seed = _simpleRng(_seed);

            for(uint256 i; i < partQuantites[2].length; i++){
                if(_seed % 10000 < partQuantites[2][i]){
                    _neck = i;
                    break;
                }
            }
            _seed = _simpleRng(_seed);

            for(uint256 i; i < partQuantites[3].length; i++){
                if(_seed % 10000 < partQuantites[3][i]){
                    _mouth = i;
                    break;
                }
            }
            _seed = _simpleRng(_seed);

            for(uint256 i; i < partQuantites[4].length; i++){
                if(_seed % 10000 < partQuantites[4][i]){
                    _hair = i;
                    break;
                }
            }
            _seed = _simpleRng(_seed);


            for(uint256 i; i < partQuantites[5].length; i++){
                if(_seed % 10000 < partQuantites[5][i]){
                    _eyes = i;
                    break;
                }
            }
            _seed = _simpleRng(_seed);
            return (_background, _body, _neck, _mouth, _hair, _eyes);

        }
    }

    function random(uint256 n, uint256 mod) internal returns (uint256) {
        return n % mod;
    }
    function _rng(address sender) internal returns (uint256) {
        bytes32 seed = keccak256(prevHash);
        prevHash = abi.encodePacked(seed, block.timestamp , sender);
        return uint256(seed);
    }
    function _simpleRng(uint256 n) internal pure returns (uint256) {

        return uint256(keccak256(abi.encodePacked(n)));
    }
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "This panda isn't on the guest list");
        string memory baseURI = _baseURI();
        if(tokenId >= _maxSupply){
            baseURI = _baseURICustom();
        }
        (uint256 background, uint256 body, uint256 neck, uint256 mouth, uint256 hair, uint256 eyes) = getPanda(tokenId);
        uint256 buddy = pandaBuddies[tokenId];
        string memory name = pandaNames[tokenId];
        //return "ipfs://bafybeid2rpwfmdh3c35nftazuacjvlwgtiuiaxopt7wnl4fx7pay5iweom/";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, 
            uint2str(background), "-", 
            uint2str(body), "-",
            uint2str(neck), "-",
            uint2str(mouth), "-",
            uint2str(hair), "-",
            uint2str(eyes), "-",
            uint2str(buddy), "-",
            name)
        ) : "";
        
    }
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function _baseURICustom() internal view returns (string memory) {
        return baseURICustom;
    }

    function startMinting(uint256 n) public onlyOwner {
        prevHash = abi.encodePacked(n);


        getRandomNumber();
        isMintingActive = true;
    }

    function stopMinting() internal {
        isMintingActive = false;
    }
    function startPregameMinting() public onlyOwner {

        LINK.approve(address(this), 1000000000000000000);
        getRandomNumber();

    }

    function mintPandaPregame(address pandaFren, uint256 quantity) public onlyOwner {
        require(quantity <= 25, "You only get 25 spots on the guest list, sorry fren.");
        require(totalSupply().add(quantity) <= 200, ":( parties full, can't let you in.");
        
        uint256 _seed = _rng(pandaFren);
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < _maxSupply) {
                _safeMint(pandaFren, mintIndex);
                pandas[mintIndex] = _seed;
                _seed = _simpleRng(_seed);
            }
        }
    }

    function mintPanda(uint256 quantity) public payable {
        require(isMintingActive, ":( parties full, can't let you in.");
        require(quantity <= 25, "You only get 25 spots on the guest list, sorry fren.");
        require(totalSupply().add(quantity) <= _maxSupply, ":( parties full, can't let you in.");
        require(price.mul(quantity) <= msg.value, "Trying to sneak in the back door? You're a bad panda..");
        
        uint256 _seed = _rng(msg.sender);
        for(uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < _maxSupply) {
                _safeMint(msg.sender, mintIndex);
                pandas[mintIndex] = _seed;
                _seed = _simpleRng(_seed);
                if(mintIndex % 100 == 0){
                    getRandomNumber();
                }
            
            }
        }

        if(_maxSupply == totalSupply()){
          stopMinting();
        }
        (bool success, ) = multisig.call{value: address(this).balance}("");
            require(success, "ETH Transfer failed.");
    }

    function withdraw() public onlyOwner{
        (bool success, ) = multisig.call{value: address(this).balance}("");
            require(success, "ETH Transfer failed.");
    }
    function withdrawLink() public onlyOwner{

            LINK.transfer(multisig, LINK.balanceOf(address(this)));
    }
}