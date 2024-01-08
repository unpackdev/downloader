pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract CreepKidsNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private TokenIds;
    uint CurrentMintIndex;
    uint PromoMintCount;
    bool Unlocked;
    
    uint constant public TotalCount = 1000;
    uint[TotalCount] private Indices;
    
    event TokenMintEvent(uint256 newID);
    
    string private metadataPath;  

    constructor() public ERC721("Creep Kids", "KIDS") {
        //security
        Unlocked = false;
        PromoMintCount = 50;

        //nft.storage ipfs hash
        metadataPath = "ipfs://QmWbNqmucZvBNGpyP724eCsoMFqdepnnjb6o7u5oLkDdcp";
    }
    
    //Thank you to the DerpyBirbs & NOOBS 
    function randomIndex() internal returns (uint) {
        uint totalSize = TotalCount - CurrentMintIndex;
        uint index = uint(keccak256(abi.encodePacked(CurrentMintIndex, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        uint value = 0;

        if (Indices[index] != 0) {
            value = Indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (Indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            Indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            Indices[index] = Indices[totalSize - 1];
        }
        return value;
    }

    function unlock() public onlyOwner {
        Unlocked = true;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256  tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function createCreepKid(address receiver, uint count)
        public payable
    {
        require(Unlocked, "Creep Kid Minting is still Locked :-/");
        require(count <= 10, "Not allowed to mint more than 10 at once!");
        require(msg.value >= 0.0666 ether * count, "Not enough eth paid! .0666 per creep");
        require((count + CurrentMintIndex-1) < 1000, "Unable to mint, not enough creep kids left :-(");

        for(uint i = 0; i < count; i++)
        {
            _mintCreepKid(receiver);
        }
    }

    function promoMint(address receiver, uint count)
    public onlyOwner 
    {
        require(PromoMintCount > 0, "Promo mints exhausted :-(");
        require(count <= 10, "Max per mint is 10!");
        require(PromoMintCount + 1 - count > 0, "Count exceeds promo count");

        PromoMintCount -= count;

        for(uint i = 0; i < count; i++)
        {
            _mintCreepKid(receiver);
        }
    }

    function _mintCreepKid(address receiver)
    private
    {
        uint256 newID = TokenIds.current();
        string memory randomID = uintToString(randomIndex());
        string memory tokenURI = string(abi.encodePacked(metadataPath,'/',randomID));
        _safeMint(receiver, newID);
        _setTokenURI(newID, tokenURI);

        TokenIds.increment();
        CurrentMintIndex++;
        TokenMintEvent(newID);
    }

    //PAYABLE
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function withdraw(uint256 amount)
    public onlyOwner
    {
        require(amount <= address(this).balance, "Amount requested is too much");
        payable(msg.sender).transfer(amount);
    }

    //ENCODING
    function concatenate(bytes32 x, bytes32 y) public pure returns (bytes memory) {
        return abi.encodePacked(x, y);
    }

    function bytes32ToString(bytes32 data) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && data[i] != 0){
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for(i = 0; i < 32 && data[i] != 0; i++) {
            bytesArray[i] = data[i];
        }

        return string(bytesArray);
    }

    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
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
}
