// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

/*
 * Welcome to the source code! There isn't much truly going on in this contract. The main thing to look
 * out for is that the name of each Vectorscape object is the name used to generate the image which is 
 * shown once we set the base url. The token URI will actually be the code that generates the SVG itself uploaded to IPFS.
 * So no risk of losing your prized Vectorscape if something happens to our site or api unless IPFS goes down. 
 * At that point, I think this little project is the least of our worries...
 * 
 * This is my first project but there will (hopefully) be many more to come as the years go on. Share your projects and thoughts with me
 * about NFTs on Twitter! @CommanderSnake1
*/

contract VectorscapeFactory is ERC721, Ownable {
    struct Vectorscape {
        string name;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint maxSupply = 2000;
    uint maxPerMint = 10;
    uint256 public PRICE = .01 ether;
    
    string _baseURL = "";
    string _contractURL = "https://gateway.pinata.cloud/ipfs/QmNiw67Mn7uYZgoFDzC2ooKFQFmKckpmdYvBxUGpMsK1E6";
    bool paused;

    mapping(string => uint) private nameToTokenId;
    Vectorscape[] public vectorscapes;

    constructor() ERC721("Vectorscapes", "VCS") { 
        paused = true;
    }

    function mint(string[] calldata names)
        public
        payable
        returns (bool)
    {
        require(!paused, "Contract is paused!");
        require(vectorscapes.length + names.length < maxSupply, "Max supply has been minted");

        uint256 price = this.getPrice();
        if (price > 0) {
            require(address(msg.sender).balance > price * names.length, "Insufficient Balance");
            require(msg.value == PRICE * names.length, "ETH value incorrect");
            address payable p = payable(owner());
            p.transfer(PRICE * names.length);
        }

        for (uint i = 0; i < names.length; i++ ) {
            string memory upperName = upper(names[i]);
            require(nameToTokenId[upperName] == 0, "name already exists!");
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
            vectorscapes.push(Vectorscape(upperName));
            nameToTokenId[upperName] = newItemId;
        }

        return true;
    }

    function getMaxSupply() external view returns(uint) {
        return maxSupply;
    }

    function totalSupply() external view returns (uint) {
        return vectorscapes.length;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        _baseURL = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function getPaused() external view returns (bool) {
        return paused;
    }

    function getVectorscape(uint256 id) public view returns(Vectorscape memory vectorscape) {
        require(id > 0);
        vectorscape = vectorscapes[id - 1];
        return vectorscape;
    }

    function getOwnerIds(address account) external view returns(uint[] memory) {
        uint[] memory vectorscapeIds = new uint[](balanceOf(account));
        uint count = 0;
        for(uint i = 0; i < vectorscapes.length; i++){
            if(ownerOf(i+1) == account) {
                vectorscapeIds[count] = i;
                count++;
            }
        }
        return vectorscapeIds;
    }

    function getOwnerVectorscapes(address account) external view returns(Vectorscape[] memory) {
        Vectorscape[] memory ownerVectorscapes = new Vectorscape[](balanceOf(account));
        uint count = 0;
        for(uint i = 0; i < vectorscapes.length; i++){
            if(ownerOf(i+1) == account) {
                ownerVectorscapes[count] = vectorscapes[i];
                count++;
            }
        }
        return ownerVectorscapes;
    }

    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
            bytes memory _baseBytes = bytes(_base);
            for (uint i = 0; i < _baseBytes.length; i++) {
                _baseBytes[i] = _upper(_baseBytes[i]);
            }
            return string(_baseBytes);
    }

    function contractURI() external view returns (string memory) {
        return _contractURL;
    }

    function setContractURL(string memory _url) external onlyOwner() {
        _contractURL = _url;
    }

    function getTokenId(string memory _name) external view returns (uint) {
        return nameToTokenId[_name] + 1;
    }

    function getPrice() external view returns (uint256) {
        if (this.totalSupply() >= 200) {
            return PRICE;
        } else {
            return 0;
        }
    }
}