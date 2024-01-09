// contracts/fractionl.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

abstract contract wholeEnchilada {
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
  function ownerOf(uint256 tokenId) public virtual;
}

contract fractionl is ERC721Enumerable, VRFConsumerBase, Ownable {
    
    // chainlink/random/prize variables
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public chefsChoice;
    uint256 public goldenPlate;

    wholeEnchilada private blueChip;
    uint256 blueChipID = 4368;
    address whodler;
    
    //nft minting variables
    using Strings for uint256;
    bool public signOn;
    uint256 private _price = 0.075 ether;
    string _baseTokenURI;
    
    // The IPFS hash
    string public METADATA_PANTRY = "";
    
    constructor(string memory baseURI) 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        ) 
        ERC721("fractionl", "FRCTN0") public{
            keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
            fee = 0.2 * 10 ** 19; // 2 LINK
            setBaseURI(baseURI);
            blueChip = wholeEnchilada(0x1A92f7381B9F03921564a437210bB9396471050C); //NFT Smart Contract of Cool Cats NFT
        }
        
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    function fractionalize(uint256 numfractions) public payable {
        uint256 supply = totalSupply();
        require(signOn,                                             "sign is off");
        require(supply + numfractions < 1025,                        "exceeds max fractions");
        require(msg.value >= _price * numfractions,                 "ether value sent is below the price");

        for(uint256 i; i < numfractions; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    
    // a higher power
    function stockPantry(string memory _hash) public onlyOwner {
        METADATA_PANTRY = _hash;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }
    
    function turnSignOn() public onlyOwner {
        signOn = true;
    }
    function turnSignOff() public onlyOwner {
        signOn = false;
    }

    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - gimme the LINK");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     https://docs.chain.link/docs/acquire-link
     https://docs.chain.link/docs/fund-your-contract
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        chefsChoice = randomness;
    }

    function getwhodler() public onlyOwner{
        
        uint256 supply = totalSupply();
        goldenPlate = (chefsChoice % supply) + 1;
        whodler = ownerOf(goldenPlate);

    }

    function sendWholeEnchilada() public onlyOwner{
        blueChip.safeTransferFrom(address(this), whodler, blueChipID);
    }

    function withdrawLink() public onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    function withdrawNFT() public onlyOwner{
        blueChip.safeTransferFrom(address(this), msg.sender, blueChipID);
    }
    function preheat() public onlyOwner {
        uint256 supply = totalSupply();
        require(supply < 25, "no more reserves allowed");
        for(uint256 i; i < 24; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
}